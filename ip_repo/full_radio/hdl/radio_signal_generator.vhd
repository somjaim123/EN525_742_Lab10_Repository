----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/28/2026 05:28:34 PM
-- Design Name: 
-- Module Name: radio_signal_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity radio_signal_generator is
    generic (
        REG_BITWIDTH: integer := 32
    ); Port ( 
        aclk: in std_logic;
        aresetn: in std_logic;
        cntrl_reg_i: in std_logic_vector(REG_BITWIDTH-1 downto 0);
        dds_phase_incr: in std_logic_vector(REG_BITWIDTH-1 downto 0);
        tuner_phase_incr: in std_logic_vector(REG_BITWIDTH-1 downto 0);
        filt_radio_o : out std_logic_vector(31 downto 0);
        filt_radio_valid_o : out std_logic
    );
end radio_signal_generator;

architecture Behavioral of radio_signal_generator is

COMPONENT ila_0
PORT (
	clk : IN STD_LOGIC;
	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe8 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	probe10 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	probe11 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	probe12 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;

COMPONENT fake_adc_compiler
    PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_phase_tvalid : IN STD_LOGIC;
    s_axis_phase_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END COMPONENT;
    
COMPONENT tuner_dds_compiler
    PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_phase_tvalid : IN STD_LOGIC;
    s_axis_phase_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END COMPONENT;

component radio_cmplx_mult
    PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

COMPONENT two_stage_dds_filter is
    Port (
    aclk: in std_logic;
    aresetn: in std_logic;
    dds_mixed_radio_tdata_i: in std_logic_vector(15 downto 0);
    dds_mixed_radio_tvalid_i: in std_logic;
    dds_radio_filt_tdata_o: out std_logic_vector(15 downto 0);
    dds_radio_filt_tvalid_o: out std_logic
     );
END COMPONENT;

-- Signal Declarations
signal fake_dds_tvalid_o: std_logic;
signal fake_dds_tdata_o: std_logic_vector(15 downto 0);
signal fake_dds_32b_tdata_o: std_logic_vector(31 downto 0);

signal dds_tuner_tvalid_o: std_logic;
signal dds_tuner_tdata_o: std_logic_vector(31 downto 0);

signal radio_mixer_tvalid_o: std_logic;
signal radio_mixer_tdata_o: std_logic_vector(31 downto 0);

signal radio_real_filt_tvalid_o: std_logic;
signal radio_real_filt_tdata_o: std_logic_vector(15 downto 0); 

signal radio_imag_filt_tvalid_o: std_logic;
signal radio_imag_filt_tdata_o: std_logic_vector(15 downto 0); 

begin
    -- Final Outputs
    filt_radio_o <= radio_imag_filt_tdata_o & radio_real_filt_tdata_o;
    filt_radio_valid_o <= radio_imag_filt_tvalid_o and radio_real_filt_tvalid_o;

    -- ILA instantiation
    ila_dbg: ila_0
    PORT MAP(
        clk => aclk,
        probe0(0) => fake_dds_tvalid_o,
        probe1 => fake_dds_tdata_o,
        probe2 => fake_dds_32b_tdata_o,
        probe3(0) => dds_tuner_tvalid_o,
        probe4 => dds_tuner_tdata_o,
        probe5(0) => radio_mixer_tvalid_o,
        probe6 => radio_mixer_tdata_o,
        probe7(0) => radio_real_filt_tvalid_o,
        probe8 => radio_real_filt_tdata_o,
        probe9(0) => radio_imag_filt_tvalid_o,
        probe10 => radio_imag_filt_tdata_o,
        probe11 => dds_phase_incr,
        probe12 => tuner_phase_incr
    );

    -- component instantiations
    fake_adc : fake_adc_compiler
        PORT MAP (
        aclk => aclk,
        aresetn => aresetn,
        s_axis_phase_tvalid => '1',
        s_axis_phase_tdata => dds_phase_incr,
        m_axis_data_tvalid => fake_dds_tvalid_o,
        m_axis_data_tdata => fake_dds_tdata_o
    );
    fake_dds_32b_tdata_o <= (fake_dds_tdata_o & X"0000");
      
    dds_tuner : tuner_dds_compiler
        PORT MAP (
        aclk => aclk,
        aresetn => aresetn,
        s_axis_phase_tvalid => '1',
        s_axis_phase_tdata => tuner_phase_incr,
        m_axis_data_tvalid => dds_tuner_tvalid_o,
        m_axis_data_tdata => dds_tuner_tdata_o
    );
      
    radio_mixer: radio_cmplx_mult
        PORT MAP(
        aclk => aclk,
        aresetn => aresetn,
        s_axis_a_tvalid => fake_dds_tvalid_o,
        s_axis_a_tdata => fake_dds_32b_tdata_o,
        s_axis_b_tvalid => dds_tuner_tvalid_o,
        s_axis_b_tdata => dds_tuner_tdata_o,
        m_axis_dout_tvalid => radio_mixer_tvalid_o,
        m_axis_dout_tdata => radio_mixer_tdata_o
    );
     
    radio_imag_filt: two_stage_dds_filter
        Port map(
        aclk => aclk,
        aresetn  => aresetn,
        dds_mixed_radio_tdata_i => radio_mixer_tdata_o (31 downto 16),
        dds_mixed_radio_tvalid_i  => radio_mixer_tvalid_o,
        dds_radio_filt_tdata_o => radio_imag_filt_tdata_o,
        dds_radio_filt_tvalid_o => radio_imag_filt_tvalid_o
    ); 
    
    radio_real_filt: two_stage_dds_filter
        Port map(
        aclk => aclk,
        aresetn  => aresetn,
        dds_mixed_radio_tdata_i => radio_mixer_tdata_o(15 downto 0),
        dds_mixed_radio_tvalid_i  => radio_mixer_tvalid_o,
        dds_radio_filt_tdata_o => radio_real_filt_tdata_o,
        dds_radio_filt_tvalid_o => radio_real_filt_tvalid_o
    );
end Behavioral;
