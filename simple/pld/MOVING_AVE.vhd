-- ============================================================================
--  Title       : Moving average
--
--  File Name   : MOVING_AVE.vhd
--  Project     : Sample
--  Designer    : toms74209200 <https://github.com/toms74209200>
--  Created     : 2023/05/05
--  Copyright   : 2023 toms74209200
--  License     : MIT License.
--                http://opensource.org/licenses/mit-license.php
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity MOVING_AVE is
    generic(
        DW              : integer := 16                                 -- Data width
    );
    port(
    -- System --
        RESET_n         : in    std_logic;                              --(n) Reset
        CLK             : in    std_logic;                              --(p) Clock

    -- Control --
        ASI_READY       : out   std_logic;                              --(p) Avalon-ST sink data ready
        ASI_VALID       : in    std_logic;                              --(p) Avalon-ST sink data valid
        ASI_DATA        : in    std_logic_vector(DW-1 downto 0);        --(p) Avalon-ST sink data
        ASO_VALID       : out   std_logic;                              --(p) Avalon-ST source data valid
        ASO_DATA        : out   std_logic_vector(DW-1 downto 0);        --(p) Avalon-ST source data
        ASO_ERROR       : out   std_logic                               --(p) Avalon-ST source error
    );
end MOVING_AVE;

architecture RTL of MOVING_AVE is

-- Parameters --
constant TAP            : integer := 128;                               -- Moving average tap


-- Internal signals --
type    DataArrayType   is array(0 to TAP-1) of std_logic_vector(DW-1 downto 0);
type    SumArrayType    is array(0 to TAP-1) of std_logic_vector(DW+TAP-1 downto 0);
signal  data_array      : DataArrayType;                                -- Data array
signal  sum_array       : SumArrayType;                                 -- Summation data array

begin

-- ============================================================================
--  Ready output
-- ============================================================================
ASI_READY <= not RESET_n;


-- ============================================================================
--  Error output
-- ============================================================================
ASO_ERROR <= '0';

-- ============================================================================
--  Valid output
-- ============================================================================
ASO_VALID <= ASI_VALID;


-- ============================================================================
--  Data register
-- ============================================================================
process (CLK, RESET_n) begin
    for i in 0 to TAP-1 loop
        if (RESET_n = '0') then
            data_array(i) <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (ASI_VALID = '1') then
                data_array(i) <= ASI_DATA;
            end if;
        end if;
    end loop;
end process;


-- ============================================================================
--  Summation
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_array(0) <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            sum_array(0) <= (X"0000_0000_0000_0000_0000_0000_0000" & data_array(0)) + (X"0000_0000_0000_0000_0000_0000_0000_0000" & data_array(1));
        end if;
    end if;
end process;

process (CLK, RESET_n) begin
    for i in 1 to TAP-1 loop
        if (RESET_n = '0') then
            sum_array(i) <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (ASI_VALID = '1') then
                sum_array(i) <= data_array(i) + sum_array(i-1);
            end if;
        end if;
    end loop;
end process;


-- ============================================================================
--  Data output
-- ============================================================================
ASO_DATA <= sum_array(TAP-1)(DW+TAP-1 downto TAP);


end RTL; --MOVING_AVE