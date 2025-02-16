library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IFetch is
    Port (clk : in STD_LOGIC;
          rst : in STD_LOGIC;
          en : in STD_LOGIC;
          BranchAddress : in STD_LOGIC_VECTOR(31 downto 0);
          JumpAddress : in STD_LOGIC_VECTOR(31 downto 0);
          Jump : in STD_LOGIC;
          PCSrc : in STD_LOGIC;
          Instruction : out STD_LOGIC_VECTOR(31 downto 0);
          PCp4 : out STD_LOGIC_VECTOR(31 downto 0));
end IFetch;

architecture Behavioral of IFetch is

-- Memorie ROM
type tROM is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
signal ROM : tROM := (

-------------- PROGRAM DE TEST --------------
-- Acest program testeaza toate instructiunile implementate,
-- folosind scrierea si citirea din memorie pentru verificare
-- si, de asemenea, instructiunile de salt BEQ si J.

--    B"000000_00001_00000_00010_00000_100000",   -- X"00201020", 00: ADD $2, $1, $0 
--    B"000000_00011_00010_00010_00000_100010",   -- X"00622022", 01: SUB $2, $3, $2
--    B"000000_00000_00010_00010_00001_000000",   -- X"00021040", 02: SLL $2, $2, 1
--    B"000000_00000_00010_00010_00001_000010",   -- X"00021042", 03: SRL $2, $2, 1
--    B"000000_00011_00010_00100_00000_100100",   -- X"00622024", 04: AND $4, $3, $2
--    B"000000_00101_00100_00100_00000_100101",   -- X"00A42025", 05: OR $4, $5, $4
--    B"000000_00100_00100_00100_00000_100110",   -- X"00842026", 06: XOR $4, $4, $4
--    B"000000_00010_00011_00100_00000_101010",   -- X"0043202A", 07: SLT $4, $2, $3
--    B"001000_00000_00100_0000000000000100",     -- X"20040004", 08: ADDI $4, $0, 4
--    B"100011_00001_00101_0000000000000000",     -- X"8C250000", 09: LW $5, 0($1)
--    B"101011_00100_00101_0000000000000000",     -- X"AC850000", 10: SW $5, 0($4)
--    B"000100_00001_00001_0000000000000001",     -- X"10210001", 11: BEQ $1, $1, 1
--    B"001100_00100_00101_0000000000000100",     -- X"30850004", 12: ANDI $5, $4, 4
--    B"001101_00101_00110_0000000000000011",     -- X"34A60003", 13: ORI $6, $5, 3
--    B"000010_00000000000000000000000011",       -- X"08000003", 14: J 3

--------------FIBONACCI------------------		
-- Acest program calculeaza sirului lui Fibonacci
-- incarcand initial 0 si 1 in 2 registre.
-- Se efectueaza scrierea in memorie la 2 adrese diferite
-- si apoi citirea de la aceleasi adrese pentru a verifica 
-- corectitudinea.
-- Calculul elementelor din sir se face intr-o bucla, folosind
-- instructiunea J.

    B"001000_00000_00001_0000000000000000",     -- X"20010000", 00: ADDI $1, $0, 0
    B"001000_00000_00010_0000000000000001",     -- X"20020001", 01: ADDI $2, $0, 1    
    B"001000_00000_00011_0000000000000000",     -- X"20030000", 02: ADDI $3, $0, 0    
    B"001000_00000_00100_0000000000000100",     -- X"20040004", 03: ADDI $4, $0, 4
    B"000000_00000_00000_0000000000000000",     -- X"00000000", 04: NOOP (SLL $0, $0, 0)
    B"101011_00011_00001_0000000000000000",     -- X"AC610000", 05: SW $1, 0($3)
    B"101011_00100_00010_0000000000000000",     -- X"AC820000", 06: SW $2, 0($4)
    B"100011_00011_00001_0000000000000000",     -- X"8C610000", 07: LW $1, 0($3)
    B"100011_00100_00010_0000000000000000",     -- X"8C820000", 08: LW $2, 0($4)
    B"000000_00000_00000_0000000000000000",     -- X"00000000", 09: NOOP (SLL $0, $0, 0)
    B"000000_00000_00000_0000000000000000",     -- X"00000000", 10: NOOP (SLL $0, $0, 0)
    B"000000_00001_00010_00101_00000_100000",   -- X"00222820", 11: ADD $5, $1, $2
    B"000000_00000_00010_00001_00000_100000",   -- X"00020820", 12: ADD $1, $0, $2
    B"000000_00000_00000_0000000000000000",     -- X"00000000", 13: NOOP (SLL $0, $0, 0)
    B"000000_00000_00101_00010_00000_100000",   -- X"00051020", 14: ADD $2, $0, $5
    B"000010_00000000000000000000001011",       -- X"0800000B", 15: J 11 
    B"000000_00000_00000_0000000000000000",     -- X"00000000", 16: NOOP (SLL $0, $0, 0)

  
-----------------------------------------
    others => X"00000000");                     -- X"00000000", NOOP (SLL $0, $0, 0)
-----------------------------------------

signal PC : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal PCAux, NextAddr, AuxSgn : STD_LOGIC_VECTOR(31 downto 0);

begin

    -- Program Counter
    process(clk, rst)
    begin
        if rst = '1' then
            PC <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                PC <= NextAddr;
            end if;
        end if;
    end process;

    -- Instruction OUT
    Instruction <= ROM(conv_integer(PC(6 downto 2)));

    -- PC + 4
    PCAux <= PC + 4;
    PCp4 <= PCAux;

    -- MUX for branch
    AuxSgn <= BranchAddress when PCSrc = '1' else PCAux;  
    
    -- MUX for jump
    NextAddr <= JumpAddress when Jump = '1' else AuxSgn;
    
end Behavioral;