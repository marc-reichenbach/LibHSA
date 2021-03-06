-- Copyright (C) 2017 Philipp Holzinger
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

library ieee;
use IEEE.std_logic_1164.all;

package config is
	constant CONF_START_ADDRESS		: std_logic_vector(31 downto 0)	:= x"00000000";
	constant CONF_EXCEPTION_HANDLER_ADDRESS	: std_logic_vector(31 downto 0) := x"00000060";
        constant CONF_TIMER_INTERRUPT           : boolean := false;
        constant CONF_NUM_HW_INTERRUPTS         : integer := 2;
	constant CONF_NUM_SND_INTERRUPTS	: integer := 3;
        constant CONF_EXC_ADDRESS_ERROR_LOAD    : boolean := true;
        constant CONF_EXC_ADDRESS_ERROR_FETCH   : boolean := true;
        constant CONF_EXC_ADDRESS_ERROR_STORE   : boolean := true;
        constant CONF_EXC_INSTRUCTION_BUS_ERROR : boolean := true;
        constant CONF_EXC_DATA_BUS_ERROR        : boolean := true;
        constant CONF_EXC_SYSCALL               : boolean := false;
        constant CONF_EXC_BREAKPOINT            : boolean := false;
        constant CONF_EXC_RESERVED_INSTRUCTION  : boolean := false;
        constant CONF_EXC_COP_UNIMPLEMENTED     : boolean := false;
        constant CONF_EXC_ARITHMETIC_OVERFLOW   : boolean := false;
        constant CONF_EXC_TRAP                  : boolean := false;
        constant CONF_EXC_FLOATING_POINT        : boolean := false;
	constant CONF_DATA_LOW_ADDR		: std_logic_vector	:= x"11000000";
	constant CONF_DATA_HIGH_ADDR		: std_logic_vector	:= x"20000000";
	constant CONF_DATA_AXI_ADDR_WIDTH	: integer		:= 32;
	constant CONF_DATA_AXI_DATA_WIDTH	: integer		:= 32;
	constant CONF_IRQ_SND_NUM_ADDR		: std_logic_vector	:= x"10000000";
    	constant CONF_IMEM_LOW_ADDR       	: std_logic_vector	:= x"00000000";
    	constant CONF_DMEM_LOW_ADDR       	: std_logic_vector 	:= x"01000000";
    	constant CONF_IMEM_LOW_BUS_ADDR       	: std_logic_vector	:= x"0004000000000000";
    	constant CONF_DMEM_LOW_BUS_ADDR       	: std_logic_vector 	:= x"0004000001000000";
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;


entity tb_rom_accel_cmd_processor_top IS
generic(
        G_MEM_NUM_4K_DATA_MEMS          : integer := 4;
        G_MEM_NUM_4K_INSTR_MEMS         : integer := 4;
        G_IMEM_INIT_FILE    		: string  := "";
        G_DMEM_INIT_FILE    		: string  := ""
);
end tb_rom_accel_cmd_processor_top;

architecture behav of tb_rom_accel_cmd_processor_top is
signal s_rcv_irq			: std_logic_vector(CONF_NUM_HW_INTERRUPTS-1 downto 0);
signal s_rcv_irq_ack			: std_logic_vector(CONF_NUM_HW_INTERRUPTS-1 downto 0);
signal s_snd_irq			: std_logic_vector(CONF_NUM_SND_INTERRUPTS-1 downto 0);
signal s_snd_irq_ack			: std_logic_vector(CONF_NUM_SND_INTERRUPTS-1 downto 0);
signal s_data_axi_awaddr		: std_logic_vector(CONF_DATA_AXI_ADDR_WIDTH-1 downto 0);
signal s_data_axi_awprot		: std_logic_vector(2 downto 0);
signal s_data_axi_awvalid		: std_logic;
signal s_data_axi_awready		: std_logic;
signal s_data_axi_wdata			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH-1 downto 0);
signal s_data_axi_wstrb			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH/8-1 downto 0);
signal s_data_axi_wvalid		: std_logic;
signal s_data_axi_wready		: std_logic;
signal s_data_axi_bresp			: std_logic_vector(1 downto 0);
signal s_data_axi_bvalid		: std_logic;
signal s_data_axi_bready		: std_logic;
signal s_data_axi_araddr		: std_logic_vector(CONF_DATA_AXI_ADDR_WIDTH-1 downto 0);
signal s_data_axi_arprot		: std_logic_vector(2 downto 0);
signal s_data_axi_arvalid		: std_logic;
signal s_data_axi_arready		: std_logic;
signal s_data_axi_rdata			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH-1 downto 0);
signal s_data_axi_rresp			: std_logic_vector(1 downto 0);
signal s_data_axi_rvalid		: std_logic;
signal s_data_axi_rready		: std_logic;
signal halt				: std_logic;
signal reset				: std_logic;
signal clock				: std_logic;
signal data_clock			: std_logic;
signal data_reset			: std_logic;

component rom_accel_cmd_processor_top is
    generic(
	G_START_ADDRESS			: std_logic_vector(31 downto 0)	:= x"00000000";
	G_EXCEPTION_HANDLER_ADDRESS	: std_logic_vector(31 downto 0) := x"00000060";
        -- interrupts
        G_TIMER_INTERRUPT               : boolean := false;
        G_NUM_HW_INTERRUPTS         	: integer range 0 to 6 := 2;
	G_NUM_SND_INTERRUPTS		: integer := 3;
        -- exceptions
        G_EXC_ADDRESS_ERROR_LOAD        : boolean := true;
        G_EXC_ADDRESS_ERROR_FETCH       : boolean := true;
        G_EXC_ADDRESS_ERROR_STORE       : boolean := true;
        G_EXC_INSTRUCTION_BUS_ERROR     : boolean := true;
        G_EXC_DATA_BUS_ERROR            : boolean := true;
        G_EXC_SYSCALL                   : boolean := false;
        G_EXC_BREAKPOINT                : boolean := false;
        G_EXC_RESERVED_INSTRUCTION      : boolean := false;
        G_EXC_COP_UNIMPLEMENTED         : boolean := false;
        G_EXC_ARITHMETIC_OVERFLOW       : boolean := false;
        G_EXC_TRAP                      : boolean := false;
        G_EXC_FLOATING_POINT            : boolean := false;
        -- memory configuration
        G_MEM_NUM_4K_DATA_MEMS          : integer := 4;
        G_MEM_NUM_4K_INSTR_MEMS         : integer := 4;
	-- configuration addresses	
	C_DATA_LOW_ADDR			: std_logic_vector	:= x"11000000";
	C_DATA_HIGH_ADDR		: std_logic_vector	:= x"20000000";
	C_DATA_AXI_ADDR_WIDTH		: integer		:= 32;
	C_DATA_AXI_DATA_WIDTH		: integer		:= 32;
	C_IRQ_SND_NUM_ADDR		: std_logic_vector	:= x"10000000";
    	C_IMEM_LOW_ADDR       		: std_logic_vector	:= x"00000000";
        C_IMEM_INIT_FILE    		: string 		:= "";
    	C_DMEM_LOW_ADDR       		: std_logic_vector 	:= x"01000000";
        C_DMEM_INIT_FILE    		: string 		:= ""
    );
    port(
        tp_clk                  : in  std_logic;
        tp_rstn                 : in  std_logic;
        tp_halt                 : in  std_logic;
    	--ingoing interrupts
	rcv_irq		: in std_logic_vector(G_NUM_HW_INTERRUPTS-1 downto 0);
	rcv_irq_ack	: out std_logic_vector(G_NUM_HW_INTERRUPTS-1 downto 0);
        -- outgoing interrupts
        snd_irq		: out std_logic_vector(G_NUM_SND_INTERRUPTS-1 downto 0);
        snd_irq_ack	: in std_logic_vector(G_NUM_SND_INTERRUPTS-1 downto 0);
	
	-- axi interfaces
	data_axi_aclk     : in    std_logic;                                              
	data_axi_aresetn  : in    std_logic;	
	data_axi_awaddr	 : out std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);     
	data_axi_awprot	 : out std_logic_vector(2 downto 0);
	data_axi_awvalid : out std_logic;
	data_axi_awready : in std_logic;
	data_axi_wdata	 : out std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
	data_axi_wstrb   : out std_logic_vector(C_DATA_AXI_DATA_WIDTH/8-1 downto 0);
	data_axi_wvalid	 : out std_logic;
	data_axi_wready	 : in std_logic;
	data_axi_bresp	 : in std_logic_vector(1 downto 0);
	data_axi_bvalid	 : in std_logic;
	data_axi_bready	 : out std_logic;
	data_axi_araddr  : out std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_arprot	 : out std_logic_vector(2 downto 0);
	data_axi_arvalid : out std_logic;
	data_axi_arready : in std_logic;
	data_axi_rdata	 : in std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
	data_axi_rresp	 : in std_logic_vector(1 downto 0);
	data_axi_rvalid	 : in std_logic;
	data_axi_rready	 : out std_logic
    );
end component;

component generic_memory is
    generic(
		C_LOW_ADDR				: std_logic_vector	:= x"0001000000000000";
		C_AXI_ADDR_WIDTH			: integer		:= 64;
		C_AXI_DATA_WIDTH			: integer		:= 64;	
		C_NUM_1K_BRAM_BLOCKS			: integer		:= 4;
		C_BRAM_LINE_WIDTH			: integer		:= 32
    );
    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
	
    	S_AXI_ACLK    	: in std_logic;
    	S_AXI_ARESETN   : in std_logic;
    	S_AXI_AWADDR    : in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    	S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
    	S_AXI_AWVALID   : in std_logic;
    	S_AXI_AWREADY   : out std_logic;
    	S_AXI_WDATA    	: in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    	S_AXI_WSTRB    	: in std_logic_vector((C_AXI_DATA_WIDTH/8)-1 downto 0);
    	S_AXI_WVALID    : in std_logic;
    	S_AXI_WREADY    : out std_logic;
    	S_AXI_BRESP    	: out std_logic_vector(1 downto 0);
    	S_AXI_BVALID    : out std_logic;
    	S_AXI_BREADY    : in std_logic;
    	S_AXI_ARADDR    : in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    	S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
    	S_AXI_ARVALID   : in std_logic;
    	S_AXI_ARREADY   : out std_logic;
    	S_AXI_RDATA     : out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    	S_AXI_RRESP     : out std_logic_vector(1 downto 0);
    	S_AXI_RVALID    : out std_logic;
    	S_AXI_RREADY    : in  std_logic
    );
end component;

begin

uut: rom_accel_cmd_processor_top
    generic map(
	G_START_ADDRESS			=> CONF_START_ADDRESS,			
	G_EXCEPTION_HANDLER_ADDRESS	=> CONF_EXCEPTION_HANDLER_ADDRESS,	
        -- interrupts                     
        G_TIMER_INTERRUPT               => CONF_TIMER_INTERRUPT,               
        G_NUM_HW_INTERRUPTS         	=> CONF_NUM_HW_INTERRUPTS, 
	G_NUM_SND_INTERRUPTS		=> CONF_NUM_SND_INTERRUPTS,
        -- exceptions                    
        G_EXC_ADDRESS_ERROR_LOAD        => CONF_EXC_ADDRESS_ERROR_LOAD,        
        G_EXC_ADDRESS_ERROR_FETCH       => CONF_EXC_ADDRESS_ERROR_FETCH,       
        G_EXC_ADDRESS_ERROR_STORE       => CONF_EXC_ADDRESS_ERROR_STORE,       
        G_EXC_INSTRUCTION_BUS_ERROR     => CONF_EXC_INSTRUCTION_BUS_ERROR,     
        G_EXC_DATA_BUS_ERROR            => CONF_EXC_DATA_BUS_ERROR,            
        G_EXC_SYSCALL                   => CONF_EXC_SYSCALL,                   
        G_EXC_BREAKPOINT                => CONF_EXC_BREAKPOINT,                
        G_EXC_RESERVED_INSTRUCTION      => CONF_EXC_RESERVED_INSTRUCTION,      
        G_EXC_COP_UNIMPLEMENTED         => CONF_EXC_COP_UNIMPLEMENTED,         
        G_EXC_ARITHMETIC_OVERFLOW       => CONF_EXC_ARITHMETIC_OVERFLOW,       
        G_EXC_TRAP                      => CONF_EXC_TRAP,                      
        G_EXC_FLOATING_POINT            => CONF_EXC_FLOATING_POINT,            
        -- memory configuration          
        G_MEM_NUM_4K_DATA_MEMS          => G_MEM_NUM_4K_DATA_MEMS,          
        G_MEM_NUM_4K_INSTR_MEMS         => G_MEM_NUM_4K_INSTR_MEMS,         
	-- configuration addresses	 
	C_DATA_LOW_ADDR			=> CONF_DATA_LOW_ADDR,			
	C_DATA_HIGH_ADDR		=> CONF_DATA_HIGH_ADDR,		
	C_DATA_AXI_ADDR_WIDTH		=> CONF_DATA_AXI_ADDR_WIDTH,		
	C_DATA_AXI_DATA_WIDTH		=> CONF_DATA_AXI_DATA_WIDTH,		
	C_IRQ_SND_NUM_ADDR		=> CONF_IRQ_SND_NUM_ADDR,
    	C_IMEM_LOW_ADDR       		=> CONF_IMEM_LOW_ADDR,       		
        C_IMEM_INIT_FILE        	=> G_IMEM_INIT_FILE,
    	C_DMEM_LOW_ADDR       		=> CONF_DMEM_LOW_ADDR, 
        C_DMEM_INIT_FILE        	=> G_DMEM_INIT_FILE
    )                                    
    port map(
        tp_clk              	=> clock,    
        tp_rstn             	=> reset,    
        tp_halt             	=> halt,    
        --ingoing interrupts
        rcv_irq		=> s_rcv_irq,	
        rcv_irq_ack 	=> s_rcv_irq_ack,
        -- outgoing interrupts 
        snd_irq		=> s_snd_irq,	
        snd_irq_ack 	=> s_snd_irq_ack,

	-- AXI	
        data_axi_aclk   => data_clock,
        data_axi_aresetn=> data_reset,
	data_axi_awaddr	 => s_data_axi_awaddr,
	data_axi_awprot	 => s_data_axi_awprot,
	data_axi_awvalid => s_data_axi_awvalid,
	data_axi_awready => s_data_axi_awready,
	data_axi_wdata	 => s_data_axi_wdata,
	data_axi_wstrb   => s_data_axi_wstrb,
	data_axi_wvalid	 => s_data_axi_wvalid,
	data_axi_wready	 => s_data_axi_wready,
	data_axi_bresp	 => s_data_axi_bresp,
	data_axi_bvalid	 => s_data_axi_bvalid,
	data_axi_bready	 => s_data_axi_bready,
	data_axi_araddr  => s_data_axi_araddr,
	data_axi_arprot	 => s_data_axi_arprot,
	data_axi_arvalid => s_data_axi_arvalid,
	data_axi_arready => s_data_axi_arready,
	data_axi_rdata	 => s_data_axi_rdata,
	data_axi_rresp	 => s_data_axi_rresp,
	data_axi_rvalid	 => s_data_axi_rvalid,
	data_axi_rready	 => s_data_axi_rready
   );

inst_config: generic_memory
    generic map(
		C_LOW_ADDR		=> CONF_DATA_LOW_ADDR,
		C_AXI_ADDR_WIDTH	=> CONF_DATA_AXI_ADDR_WIDTH,
		C_AXI_DATA_WIDTH	=> CONF_DATA_AXI_DATA_WIDTH,
		C_NUM_1K_BRAM_BLOCKS	=> 100,
		C_BRAM_LINE_WIDTH	=> 32
    )
    port map(
        clk       	=> clock,
        rstn            => reset,
	
	S_AXI_ACLK	=> data_clock,
	S_AXI_ARESETN	=> data_reset,
	S_AXI_AWADDR	=> s_data_axi_awaddr,   
	S_AXI_AWPROT	=> s_data_axi_awprot,
	S_AXI_AWVALID	=> s_data_axi_awvalid,
	S_AXI_AWREADY	=> s_data_axi_awready,
	S_AXI_WDATA	=> s_data_axi_wdata,
	S_AXI_WSTRB	=> s_data_axi_wstrb,
	S_AXI_WVALID	=> s_data_axi_wvalid,
	S_AXI_WREADY	=> s_data_axi_wready,
	S_AXI_BRESP	=> s_data_axi_bresp,
	S_AXI_BVALID	=> s_data_axi_bvalid,
	S_AXI_BREADY	=> s_data_axi_bready,
	S_AXI_ARADDR	=> s_data_axi_araddr,
	S_AXI_ARPROT	=> s_data_axi_arprot,
	S_AXI_ARVALID	=> s_data_axi_arvalid,
	S_AXI_ARREADY	=> s_data_axi_arready,
	S_AXI_RDATA	=> s_data_axi_rdata,
	S_AXI_RRESP	=> s_data_axi_rresp,
	S_AXI_RVALID	=> s_data_axi_rvalid,
	S_AXI_RREADY	=> s_data_axi_rready
);

stimuli: process
begin
  reset 	<= '0';
  data_reset 	<= '0';
  halt 		<= '1';
  -- for the moment no interrupts arrive
  s_rcv_irq		<= (others => '0');	
  s_snd_irq_ack 	<= (others => '0');
  wait for 25 ns;
  reset <= '1';
  data_reset <= '1';
  halt <= '0';

  -- write testcase
  wait for 100 ns;
  s_rcv_irq <= "10";
  wait until s_rcv_irq_ack = "10";
  s_rcv_irq <= "00";
  wait;
end process;

clock_P: process
begin
clock <= '0';
wait for 10 ns;
clock <= '1';
wait for 10 ns;
end process;

data_clock_P: process
begin
data_clock <= '0';
wait for 10 ns;
data_clock <= '1';
wait for 10 ns;
end process;

end behav;

