----------------------------------------------------------------------------------
-- Company: Checksum LLC
-- Engineer: Anthony Fisher
-- 
-- Create Date:    09:18:52 07/31/2018 
-- Design Name: Shift Register Test
-- Module Name:    shift_reg_test - a1
-- Project Name: 
-- Target Devices: Xilinx CoolRunner-II, XC2C64A-VQ44
-- Tool versions: Xilinx ISE 14.7
-- Description: 
--  This code is used to program the XC2C64A-VQ44 CPLD to perform functionality
--  testing on two shift registers, IC13 and IC14, on the PCB being tested.
--
-- Dependencies: 
--
-- Revision: 
--  Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity shift_register_tester is
    port ( sys_clk : in std_logic;
           start : in std_logic;
           sdi13 : in std_logic;
           sdi14 : std_logic;
           parallel_data_in : in std_logic_vector(6 downto 0);
           sdo : out std_logic;
           parallel_data_out : out std_logic_vector(7 downto 0) := (others => '0');
           parallel_control : out std_logic := '1';  -- Controls both IC13 latch clock and IC14 parallel load
           scl : out std_logic := '0';
           parallel_out_en : out std_logic := '1';
           out_valid : out std_logic := '0';
           ic13_pass : out std_logic := '0';
           ic14_pass : out std_logic := '0');
end shift_register_tester;

architecture a1 of shift_register_tester is

    -- Bytes to be written to the shift registers.
    constant SEQ0 : std_logic_vector(7 downto 0) := "11101101";
    constant SEQ1 : std_logic_vector(7 downto 0) := "01010111";
    constant SEQ2 : std_logic_vector(7 downto 0) := "01111001";

    type state_type is (IDLE, 
                        WRITE_PARALLEL, 
                        READ_WRITE_SERIAL,
                        READ_PARALLEL,
                        RESULT_READY);
    signal state : state_type := IDLE;
    
    -- Control signals for starting operation.
    signal start_reg, start_rise : std_logic := '0';
    
    -- Counter to track bits transmitted so far.
    signal bits_sent : integer range 0 to 255 := 0;
    
    -- Data received from shift registers.
    signal rx_data1_13, rx_data0_13, rx_data0_14, rx_data1_14 : std_logic_vector(7 downto 0);
    
    -- Serial clock signals
    signal scl_en, scl_buf : std_logic := '0';
    
    signal parallel_control_buf : std_logic := '1';

begin

    --========================
    -- State transition logic
    --========================
    
    state_update : process (sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            case state is
                when IDLE =>
                    -- Wait in IDLE state until start signal is received.
                    if (start_rise = '1') then
                        state <= WRITE_PARALLEL;
                    end if;
                when WRITE_PARALLEL =>
                    -- Move to next state after one clock cycle.
                    state <= READ_WRITE_SERIAL;
                when READ_WRITE_SERIAL =>
                    -- Move to next state after 16 serial clock cycles (two bytes read/written).
                    if (bits_sent > 15) then
                        state <= READ_PARALLEL;
                    end if;
                when READ_PARALLEL =>
                    -- Move to next state after data has been latched into parallel outputs.
                    if (parallel_control_buf = '1') then
                        state <= RESULT_READY;
                    end if;
                when RESULT_READY =>
                    -- Return to IDLE state once start signal goes low.
                    -- This indicates that the output data has been read by the PC.
                    if (start = '0') then
                        state <= IDLE;
                    end if;
                when others => state <= IDLE;
            end case;
        end if;
    end process state_update;
    
    --========================
    -- Parallel write logic
    --========================
    
    -- Data to be loaded into IC14
    parallel_data_out <= SEQ0;
                     
	--========================
    -- Serial read/write logic
    --========================
    
	-- Enable serial shift clock when in shifting states and there are still bits to send.
    scl_en_proc : process (sys_clk)
    begin
        if (falling_edge(sys_clk)) then
            if ((state = READ_WRITE_SERIAL) and bits_sent < 16) then
                scl_en <= '1';
            else
                scl_en <= '0';
            end if;
        end if;
    end process scl_en_proc;

    -- Internal buffer of serial clock. Used for clocking serial receive.
    scl_buf <= sys_clk when (scl_en = '1') else
               '0';

    scl <= scl_buf;
    
           
    -- Send bits, MSB first
    sdo <= SEQ1(7 - bits_sent) when (bits_sent < 8) else
           SEQ2(15 - bits_sent) when (bits_sent < 16) else
           SEQ2(0);
    
    -- Recieve bits, MSB first
    serial_rx : process (scl_buf, state)
    begin
        if (state = IDLE) then
            -- Reset if in IDLE state
            rx_data0_13 <= (others => '0');
            rx_data0_14 <= (others => '0');
            rx_data1_14 <= (others => '0');
        elsif (rising_edge(scl_buf)) then
            if (state = READ_WRITE_SERIAL) then
                if (bits_sent < 8) then
                    -- Writing to both, but only receiving valid data from IC14 because it
                    -- was previously loaded via the parallel inputs.
                    rx_data0_13 <= rx_data0_13;
                    rx_data0_14 <= rx_data0_14(6 downto 0) & sdi14;
                else
                    -- Receive valid data from both.
                    rx_data0_13 <= rx_data0_13(6 downto 0) & sdi13;
                    rx_data1_14 <= rx_data1_14(6 downto 0) & sdi14;
                end if;
            else
                -- If in any other state, simply hold the current value.
                rx_data0_13 <= rx_data0_13;
                rx_data0_14 <= rx_data0_14;
                rx_data1_14 <= rx_data1_14;
            end if;
        end if;
    end process serial_rx;
    
    -- Track number of bits sent in the serial transmission. 
    bit_count : process (scl_buf, state)
    begin
        if (not (state = READ_WRITE_SERIAL)) then
            bits_sent <= 0;
        elsif (rising_edge(scl_buf)) then
            bits_sent <= bits_sent + 1;
        end if;
    end process bit_count;
    
    --========================
    -- Parallel control logic
    --========================
    
    -- parallel_control must be low to perform a parallel write to IC14 in the
    -- WRITE_PARALLEL state and must be high when using IC14 serially.
    -- It must also have a rising edge during the READ_PARALLEL state in order
    -- to latch the contents of IC13 into its parallel output register.
    parallel_control_proc : process (sys_clk, state)
    begin
        if (state = WRITE_PARALLEL) then
            parallel_control_buf <= '0';
        elsif (falling_edge(sys_clk)) then
            if (state = READ_PARALLEL) then
                parallel_control_buf <= not parallel_control_buf;
            else
                parallel_control_buf <= '1';
            end if;
        end if;
    end process parallel_control_proc;
    
    parallel_control <= parallel_control_buf;
    
    --========================
    -- Parallel read logic
    --========================
             
    -- Enable the parallel outputs when trying to read them
    parallel_out_en <= '0' when state = READ_PARALLEL else
                          '1';
                          
    parallel_rx : process (sys_clk, state)
    begin
        if (state = IDLE) then
            -- Reset if in IDLE state
            rx_data1_13 <= (others => '0');
        elsif (rising_edge(sys_clk)) then
            if (state = READ_PARALLEL) then
                -- MSB line is not connected in circuit, so just assume
                -- the correct value on that bit.
                rx_data1_13 <= SEQ2(7) & parallel_data_in;
            else
                rx_data1_13 <= rx_data1_13;
            end if;
        end if;
    end process parallel_rx;
    
    --========================
    -- Output pass/fail logic
    --========================
    
	 -- Valid output ready to be read
    out_valid <= '1' when state = RESULT_READY else '0';
    
    -- Synchronous out_valid signal may be necessary because rx_data1_13 changes
    -- at the same clock edge as entering RESULT_READY state. This would add a 
    -- one-clock-cycle delay to out_valid going high. 
--    out_valid_proc : process (sys_clk)
--    begin
--        if (rising_edge(sys_clk)) then
--            if (state = RESULT_READY) then
--                out_valid <= '1';
--            else
--                out_valid <= '0';
--            end if;
--        end if;
--    end process out_valid_proc;
    
    -- Chip passes if the recorded values match the sent values
    ic13_pass <= '1' when (rx_data0_13 = SEQ1 and rx_data1_13 = SEQ2) else
                 '0';
    ic14_pass <= '1' when (rx_data0_14 = SEQ0 and rx_data1_14 = SEQ1) else
                 '0';
           
    --========================
    -- Miscellaneous control logic
    --========================
    
	-- Detection of rising edge on start signal
    start_reg_proc : process (sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            start_reg <= start;
        end if;
    end process start_reg_proc;
    
    -- This signal goes high for one clock cycle when a rising edge
    -- occurs on the start signal.
    start_rise <= '1' when (start = '1' and start_reg = '0') else '0';
    

end a1;