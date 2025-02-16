library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_env is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (4 downto 0);
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (7 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end test_env;

architecture Behavioral of test_env is

component MPG is
    Port ( enable : out STD_LOGIC;
           btn : in STD_LOGIC;
           clk : in STD_LOGIC);
end component;

component SSD is
    Port ( clk : in STD_LOGIC;
           digits : in STD_LOGIC_VECTOR(31 downto 0);
           an : out STD_LOGIC_VECTOR(7 downto 0);
           cat : out STD_LOGIC_VECTOR(6 downto 0));
end component;

component IFetch
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           BranchAddress : in STD_LOGIC_VECTOR(31 downto 0);
           JumpAddress : in STD_LOGIC_VECTOR(31 downto 0);
           Jump : in STD_LOGIC;
           PCSrc : in STD_LOGIC;
           Instruction : out STD_LOGIC_VECTOR(31 downto 0);
           PCp4 : out STD_LOGIC_VECTOR(31 downto 0));
end component;

component ID
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;    
           Instr : in STD_LOGIC_VECTOR(25 downto 0);
           WD : in STD_LOGIC_VECTOR(31 downto 0);
           RegWrite : in STD_LOGIC;
           RegDst : in STD_LOGIC;
           ExtOp : in STD_LOGIC;
           WriteAddress: in std_logic_vector(4 downto 0);
           RD1 : out STD_LOGIC_VECTOR(31 downto 0);
           RD2 : out STD_LOGIC_VECTOR(31 downto 0);
           Ext_Imm : out STD_LOGIC_VECTOR(31 downto 0);
           func : out STD_LOGIC_VECTOR(5 downto 0);
           sa : out STD_LOGIC_VECTOR(4 downto 0));
end component;

component UC
    Port ( Instr : in STD_LOGIC_VECTOR(5 downto 0);
           RegDst : out STD_LOGIC;
           ExtOp : out STD_LOGIC;
           ALUSrc : out STD_LOGIC;
           Branch : out STD_LOGIC;
           Jump : out STD_LOGIC;
           ALUOp : out STD_LOGIC_VECTOR(2 downto 0);
           MemWrite : out STD_LOGIC;
           MemtoReg : out STD_LOGIC;
           RegWrite : out STD_LOGIC);
end component;

component EX is
    Port ( PCp4 : in STD_LOGIC_VECTOR(31 downto 0);
           RD1 : in STD_LOGIC_VECTOR(31 downto 0);
           RD2 : in STD_LOGIC_VECTOR(31 downto 0);
           Ext_Imm : in STD_LOGIC_VECTOR(31 downto 0);
           func : in STD_LOGIC_VECTOR(5 downto 0);
           sa : in STD_LOGIC_VECTOR(4 downto 0);
           ALUSrc : in STD_LOGIC;
           ALUOp : in STD_LOGIC_VECTOR(2 downto 0);
           BranchAddress : out STD_LOGIC_VECTOR(31 downto 0);
           ALURes : out STD_LOGIC_VECTOR(31 downto 0);
           Zero : out STD_LOGIC);
end component;

component MEM
    port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           ALUResIn : in STD_LOGIC_VECTOR(31 downto 0);
           RD2 : in STD_LOGIC_VECTOR(31 downto 0);
           MemWrite : in STD_LOGIC;			
           MemData : out STD_LOGIC_VECTOR(31 downto 0);
           ALUResOut : out STD_LOGIC_VECTOR(31 downto 0));
end component;

signal Instruction, PCp4, RD1, RD2, WD, Ext_imm : STD_LOGIC_VECTOR(31 downto 0); 
signal JumpAddress, BranchAddress, ALURes, ALURes1, MemData : STD_LOGIC_VECTOR(31 downto 0);
signal func : STD_LOGIC_VECTOR(5 downto 0);
signal sa : STD_LOGIC_VECTOR(4 downto 0);
signal zero : STD_LOGIC;
signal digits : STD_LOGIC_VECTOR(31 downto 0);
signal en, rst, PCSrc : STD_LOGIC; 
-- main controls 
signal RegDst, ExtOp, ALUSrc, Branch, Jump, MemWrite, MemtoReg, RegWrite : STD_LOGIC;
signal ALUOp : STD_LOGIC_VECTOR(2 downto 0);

--pipeline registers
signal Reg_IF_ID: std_logic_vector(63 downto 0);
signal Reg_ID_EX: std_logic_vector(157 downto 0);
signal Reg_EX_MEM: std_logic_vector(105 downto 0);
signal Reg_MEM_WB: std_logic_vector(70 downto 0);


signal WriteAddress: std_logic_vector(4 downto 0);

begin

    monopulse : MPG port map(en, btn(0), clk);
    
    -- main units
    inst_IFetch : IFetch port map(clk, btn(1), en, Reg_EX_MEM(35 downto 4), JumpAddress, Jump, PCSrc, Instruction, PCp4);
    inst_ID : ID port map(clk, en, Reg_IF_ID(57 downto 32), WD, Reg_MEM_WB(1), RegDst, ExtOp, Reg_MEM_WB(70 downto 66), RD1, RD2, Ext_imm, func, sa);
    inst_UC : UC port map(Reg_IF_ID(63 downto 58), RegDst, ExtOp, ALUSrc, Branch, Jump, ALUOp, MemWrite, MemtoReg, RegWrite);
    inst_EX : EX port map(Reg_ID_EX(40 downto 9), Reg_ID_EX(72 downto 41), Reg_ID_EX(104 downto 73), Reg_ID_EX(141 downto 110), 
                          Reg_ID_EX(147 downto 142), Reg_ID_EX(109 downto 105), Reg_ID_EX(7), Reg_ID_EX(6 downto 4), BranchAddress, ALURes, Zero); 
    inst_MEM : MEM port map(clk, en, Reg_EX_MEM(68 downto 37), Reg_EX_MEM(100 downto 69), Reg_EX_MEM(2), MemData, ALURes1);


    --pipeline registers
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
            
                    Reg_IF_ID(63 downto 32) <= Instruction;
                    Reg_IF_ID(31 downto 0) <= PCp4;
   
                    Reg_ID_EX(157 downto 153) <= Instruction(15 downto 11);
                    Reg_ID_EX(152 downto 148) <= Instruction(20 downto 16);
                    Reg_ID_EX(147 downto 142) <= Instruction(5 downto 0);
                    Reg_ID_EX(141 downto 110) <= Ext_imm;
                    Reg_ID_EX(109 downto 105) <= Instruction(10 downto 6);
                    Reg_ID_EX(104 downto 73) <= RD2; 
                    Reg_ID_EX(72 downto 41) <= RD1;
                    Reg_ID_EX(40 downto 9) <= PCp4;
                    Reg_ID_EX(8) <= RegDst;
                    Reg_ID_EX(7) <= ALUSrc;
                    Reg_ID_EX(6 downto 4) <= ALUOp;
                    Reg_ID_EX(3) <= Branch;
                    Reg_ID_EX(2) <= MemWrite;
                    Reg_ID_EX(1) <= RegWrite;
                    Reg_ID_EX(0) <= MemtoReg;
                    
                    Reg_EX_MEM(105 downto 101) <= WriteAddress;
                    Reg_EX_MEM(100 downto 69) <= RD2;
                    Reg_EX_MEM(68 downto 37) <= ALURes;
                    Reg_EX_MEM(36) <= Zero;
                    Reg_EX_MEM(35 downto 4) <= BranchAddress;
                    Reg_EX_MEM(3) <= Branch;
                    Reg_EX_MEM(2) <= MemWrite;
                    Reg_EX_MEM(1) <= RegWrite;
                    Reg_EX_MEM(0) <= MemtoReg;
                    
                    Reg_MEM_WB(70 downto 66) <=  WriteAddress;
                    Reg_MEM_WB(65 downto 34) <=  ALURes;
                    Reg_MEM_WB(33 downto 2) <= MemData;
                    Reg_MEM_WB(1) <= RegWrite;
                    Reg_MEM_WB(0) <= MemtoReg;
                    
            end if;
        end if;
    end process;
    
    --mux ul cu RegDst
    WriteAddress <= Reg_ID_EX(157 downto 153) when Reg_ID_EX(8) = '1' else Reg_ID_EX(152 downto 148); 
    
    
    -- Write-Back unit 
    WD <= MemData when MemtoReg = '1' else ALURes1; 

    -- branch control
    PCSrc <= Zero and Branch;

    -- jump address
    JumpAddress <= PCp4(31 downto 28) & Instruction(25 downto 0) & "00";

   -- SSD display MUX
    with sw(7 downto 5) select
        digits <=  Instruction when "000", 
                   PCp4 when "001",
                   RD1 when "010",
                   RD2 when "011",
                   Ext_Imm when "100",
                   ALURes when "101",
                   MemData when "110",
                   WD when "111",
                   (others => 'X') when others; 

    display : SSD port map(clk, digits, an, cat);
    
    -- main controls on the leds
    led(10 downto 0) <= ALUOp & RegDst & ExtOp & ALUSrc & Branch & Jump & MemWrite & MemtoReg & RegWrite;
    
    
end Behavioral;