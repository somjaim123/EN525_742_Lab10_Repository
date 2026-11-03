----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/28/2026 05:57:01 PM
-- Design Name: 
-- Module Name: two_stage_dds_filter - Behavioral
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

entity two_stage_dds_filter is
    Port (
    aclk: in std_logic;
    aresetn: in std_logic;
    
    dds_mixed_radio_tdata_i: in std_logic_vector(15 downto 0);
    dds_mixed_radio_tvalid_i: in std_logic;
    
    dds_radio_filt_tdata_o: out std_logic_vector(15 downto 0);
    dds_radio_filt_tvalid_o: out std_logic
     );
end two_stage_dds_filter;

architecture Behavioral of two_stage_dds_filter is

-- Component Declarations
COMPONENT ila_1
PORT (
	clk : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(23 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe4 : IN STD_LOGIC_VECTOR(23 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
);
END COMPONENT  ;

COMPONENT dds_filt_stage_1 is
    Port ( 
    aclk : in STD_LOGIC;
    s_axis_data_tvalid : in STD_LOGIC;
    s_axis_data_tready : out STD_LOGIC;
    s_axis_data_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
    m_axis_data_tvalid : out STD_LOGIC;
    m_axis_data_tdata : out STD_LOGIC_VECTOR ( 23 downto 0 )
);
END COMPONENT;

COMPONENT dds_filt_stage_2 is
    Port ( 
    aclk : in STD_LOGIC;
    s_axis_data_tvalid : in STD_LOGIC;
    s_axis_data_tready : out STD_LOGIC;
    s_axis_data_tdata : in STD_LOGIC_VECTOR ( 23 downto 0 );
    m_axis_data_tvalid : out STD_LOGIC;
    m_axis_data_tdata : out STD_LOGIC_VECTOR ( 23 downto 0 )
);
END COMPONENT;

-- Signal Declarations
signal dds_filt_stage_1_tdata: std_logic_vector(23 downto 0);
signal dds_filt_stage_1_tvalid: std_logic;
signal dds_filt_stage_1_tready: std_logic;

signal dds_filt_stage_2_tdata: std_logic_vector(23 downto 0);
signal dds_filt_stage_2_tvalid: std_logic;
signal dds_filt_stage_2_tready: std_logic;

begin

    -- ILA Instantiation
    ila_dbg_filts: ila_1
    PORT MAP(
        clk => aclk,
        probe0 => dds_mixed_radio_tdata_i,
        probe1(0) => dds_mixed_radio_tvalid_i,
        probe2 => dds_filt_stage_1_tdata,
        probe3(0) => dds_filt_stage_1_tvalid,
        probe4 => dds_filt_stage_2_tdata,
        probe5(0) => dds_filt_stage_2_tvalid,
        probe6(0) => dds_filt_stage_1_tready,
        probe7(0) => dds_filt_stage_2_tready
    );

    filt_stage_1: dds_filt_stage_1
    Port map( 
    aclk => aclk,
    s_axis_data_tvalid => dds_mixed_radio_tvalid_i,
    s_axis_data_tready => dds_filt_stage_1_tready,
    s_axis_data_tdata => dds_mixed_radio_tdata_i,
    m_axis_data_tvalid => dds_filt_stage_1_tvalid,
    m_axis_data_tdata => dds_filt_stage_1_tdata
    );
    
    filt_stage_2: dds_filt_stage_2
    Port map( 
    aclk => aclk,
    s_axis_data_tvalid => dds_filt_stage_1_tvalid,
    s_axis_data_tready => dds_filt_stage_2_tready,
    s_axis_data_tdata => dds_filt_stage_1_tdata,
    m_axis_data_tvalid => dds_filt_stage_2_tvalid,
    m_axis_data_tdata => dds_filt_stage_2_tdata
    );
    dds_radio_filt_tvalid_o <= dds_filt_stage_2_tvalid;
    dds_radio_filt_tdata_o <= dds_filt_stage_2_tdata(15 downto 0);

end Behavioral;
