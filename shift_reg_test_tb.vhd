----------------------------------------------------------------------------------
-- Company: Checksum LLC
-- Engineer: Anthony Fisher
-- 
-- Create Date:    09:18:52 07/31/2018 
-- Design Name: Shift Register Test
-- Module Name:    shift_reg_tester_tb - a1
-- Project Name: 
-- Target Devices: Xilinx CoolRunner-II, XC2C64A-VQ44
-- Tool versions: Xilinx ISE 14.7
-- Description: 
--  Test bench for use with shift_reg_test.vhd.
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

entity shift_reg_tester_tb is
end entity;

architecture a1 of shift_reg_tester_tb is

    component shift_register_tester
    port ( sys_clk : in std_logic;
           start : in std_logic;
           sdi13 : in std_logic;
           sdi14 : std_logic;
           parallel_data_in : in std_logic_vector(6 downto 0);
           sdo : out std_logic;
           parallel_data_out : out std_logic_vector(7 downto 0);
           parallel_control : out std_logic;
           scl : out std_logic;
           parallel_out_en : out std_logic;
           out_valid : out std_logic;
           ic13_pass : out std_logic;
           ic14_pass : out std_logic);
    end component;
    
    constant half_period : time := 15250 ns;
    signal clk : std_logic := '0';
    
    signal start, sdi13, sdi14 : std_logic := '0';
    signal parallel_data_in : std_logic_vector(6 downto 0) := (others => '0');
    signal sdo, parallel_control, scl, parallel_out_en, out_valid, ic13_pass, ic14_pass : std_logic;
    signal parallel_data_out : std_logic_vector(7 downto 0);
    
    signal ic13 : std_logic_vector(7 downto 0) := (others => '0');
    signal ic14 : std_logic_vector(7 downto 0) := (others => '0');
    
begin

    clk <= not clk after half_period;
    
    uut : shift_register_tester
    port map (sys_clk => clk,
              start => start,
              sdi13 => sdi13,
              sdi14 => sdi14,
              parallel_data_in => parallel_data_in,
              sdo => sdo,
              parallel_data_out => parallel_data_out,
              parallel_control => parallel_control,
              scl => scl,
              parallel_out_en => parallel_out_en,
              out_valid => out_valid,
              ic13_pass => ic13_pass,
              ic14_pass => ic14_pass
              );
              
    sdi13 <= ic13(7);
    sdi14 <= ic14(7);

    testing : process
    begin
        wait for 30 ns;
        start <= '1';
        
        -- Load IC14
        wait until parallel_control = '0';
        wait until parallel_control = '1';
        ic14 <= parallel_data_out;
        
        -- Read out IC14, also loading SEQ1 into IC13/14
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        
        -- Read out IC13/14
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        wait until scl = '1';
        ic13 <= ic13(6 downto 0) & sdo;
        ic14 <= ic14(6 downto 0) & sdo;
        
        -- Parallel read of IC13
        wait until parallel_control = '0';
        wait until parallel_control = '1';
        parallel_data_in <= ic13(6 downto 0);
        
        wait until out_valid = '1';
        start <= '0';
        
        wait;
    end process testing;

    
end a1;