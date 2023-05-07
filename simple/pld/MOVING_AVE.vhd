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
type    Sum1ArrayType   is array(0 to TAP/2-1) of std_logic_vector(DW downto 0);
type    Sum2ArrayType   is array(0 to TAP/4-1) of std_logic_vector(DW+1 downto 0);
type    Sum3ArrayType   is array(0 to TAP/8-1) of std_logic_vector(DW+2 downto 0);
type    Sum4ArrayType   is array(0 to TAP/16-1) of std_logic_vector(DW+3 downto 0);
type    Sum5ArrayType   is array(0 to TAP/32-1) of std_logic_vector(DW+4 downto 0);
type    Sum6ArrayType   is array(0 to TAP/64-1) of std_logic_vector(DW+5 downto 0);
signal  data_array      : DataArrayType;                                -- Data array
signal  sum_1_array     : Sum1ArrayType;                                -- Summation data array
signal  sum_2_array     : Sum2ArrayType;                                -- Summation data array
signal  sum_3_array     : Sum3ArrayType;                                -- Summation data array
signal  sum_4_array     : Sum4ArrayType;                                -- Summation data array
signal  sum_5_array     : Sum5ArrayType;                                -- Summation data array
signal  sum_6_array     : Sum6ArrayType;                                -- Summation data array
signal  sum_7           : std_logic_vector(DW+6 downto 0);              -- Summation data array
signal  aso_valid_i     : std_logic_vector(7 downto 0);                 -- Avalon-ST source data valid

begin

-- ============================================================================
--  Ready output
-- ============================================================================
ASI_READY <= RESET_n;


-- ============================================================================
--  Error output
-- ============================================================================
ASO_ERROR <= '0';

-- ============================================================================
--  Valid output
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        aso_valid_i <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        aso_valid_i(0) <= ASI_VALID;
        aso_valid_i(7 downto 1) <= aso_valid_i(6 downto 0);
    end if;
end process;

ASO_VALID <= aso_valid_i(7);


-- ============================================================================
--  Data register
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        data_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            data_array(0) <= ASI_DATA;
            for i in 1 to TAP-1 loop
                data_array(i) <= data_array(i-1);
        end loop;
        end if;
    end if;
end process;


-- ============================================================================
--  Summation
-- ============================================================================
--1st adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_1_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            for i in 0 to TAP/2-1 loop
                sum_1_array(i) <= ('0' & data_array(i*2)) + ('0' & data_array(i*2+1));
            end loop;
        end if;
    end if;
end process;

--2nd adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_2_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            for i in 0 to TAP/4-1 loop
                sum_2_array(i) <= ('0' & sum_1_array(i*2)) + ('0' & sum_1_array(i*2+1));
            end loop;
        end if;
    end if;
end process;

--3rd adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_3_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            for i in 0 to TAP/8-1 loop
                sum_3_array(i) <= ('0' & sum_2_array(i*2)) + ('0' & sum_2_array(i*2+1));
            end loop;
        end if;
    end if;
end process;

--4th adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_4_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            for i in 0 to TAP/16-1 loop
                sum_4_array(i) <= ('0' & sum_3_array(i*2)) + ('0' & sum_3_array(i*2+1));
            end loop;
        end if;
    end if;
end process;

--5th adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_5_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            for i in 0 to TAP/32-1 loop
                sum_5_array(i) <= ('0' & sum_4_array(i*2)) + ('0' & sum_4_array(i*2+1));
            end loop;
        end if;
    end if;
end process;

--6th adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_6_array <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            for i in 0 to TAP/64-1 loop
                sum_6_array(i) <= ('0' & sum_5_array(i*2)) + ('0' & sum_5_array(i*2+1));
            end loop;
        end if;
    end if;
end process;

--7th adder
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sum_7 <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            sum_7 <= ('0' & sum_6_array(1)) + ('0' & sum_6_array(0));
        end if;
    end if;
end process;

-- ============================================================================
--  Data output
-- ============================================================================
ASO_DATA <= sum_7(DW+6 downto DW-9) when (aso_valid_i(7) = '1') else (others => '0');


end RTL; --MOVING_AVE