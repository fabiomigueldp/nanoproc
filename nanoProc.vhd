LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.ALL;
USE  IEEE.STD_LOGIC_ARITH.ALL;
USE  IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY nanoProc IS
	port(	reset	: IN STD_LOGIC;
			clock	: IN STD_LOGIC;
			ACout	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			IRout	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			PCout	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END nanoProc;

ARCHITECTURE exec OF nanoProc IS

COMPONENT dmemory
	PORT(	read_data 	: OUT	STD_LOGIC_VECTOR( 15 DOWNTO 0 );
        	address 		: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
        	write_data 	: IN 	STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	   	memWrite 	: IN 	STD_LOGIC;
         clock,reset	: IN 	STD_LOGIC );
END COMPONENT;

-- Declaração do tipo para a máquina de estados
TYPE t_estado IS (s_inicia, s_le, s_decodifica, s_executa_load);

SIGNAL AC, dataBus, IR	: STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL PC, addrBus		: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL MW					: STD_LOGIC;

-- Sinais da máquina de estados
SIGNAL estado_atual, proximo_estado : t_estado;

-- Sinais de habilitação para controle dos registradores
SIGNAL pc_enable, ir_enable, ac_enable : STD_LOGIC;

BEGIN
	-- Componente de memória definida no arquivo DMEMORY.vhd
	memoria : dmemory PORT MAP(	
							read_data	=> dataBus,
							address		=> addrBus,
							write_data	=> AC,
							memWrite		=> MW,
							clock			=> clock,
							reset			=> reset);
							
	-- PC, IR e AC são registradores, portanto sensíveis ao clock
	-- Processo sequencial principal com controle por sinais de enable
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN
			PC <= X"00";
			IR <= X"0000";
			AC <= X"0000";
			estado_atual <= s_inicia;
		ELSIF rising_edge(clock) THEN
			-- Atualiza registradores somente se habilitados
			IF (pc_enable = '1') THEN
				PC <= PC + 1;
			END IF;
			IF (ir_enable = '1') THEN
				IR <= dataBus;
			END IF;
			IF (ac_enable = '1') THEN
				AC <= dataBus;
			END IF;
			-- Atualiza estado da máquina
			estado_atual <= proximo_estado;
		END IF;
	END PROCESS;
	
	-- Processo combinacional para controle da máquina de estados
	PROCESS (estado_atual, IR, dataBus)
	BEGIN
		-- Valores padrão para evitar latches
		pc_enable <= '0';
		ir_enable <= '0';
		ac_enable <= '0';
		MW <= '0';
		addrBus <= PC;
		proximo_estado <= estado_atual;
		
		CASE estado_atual IS
			WHEN s_inicia =>
				-- Nenhuma ação de escrita, reset já zerou os registradores
				proximo_estado <= s_le;
				
			WHEN s_le => -- Ciclo de Busca (Fetch)
				-- Coloca o endereço da instrução no barramento
				addrBus <= PC;
				-- Habilita a escrita no IR com o dataBus no próximo clock
				ir_enable <= '1';
				-- Habilita o incremento do PC no próximo clock
				pc_enable <= '1';
				proximo_estado <= s_decodifica;
				
			WHEN s_decodifica => -- Ciclo de Decodificação
				-- Verifica o opcode da instrução (8 bits mais significativos)
				IF IR(15 DOWNTO 8) = X"02" THEN -- Instrução LOAD (opcode 02_HEX)
					-- Coloca o endereço do operando no barramento
					addrBus <= "00000000" & IR(7 DOWNTO 0);
					proximo_estado <= s_executa_load;
				ELSE
					-- Se não for LOAD, volta a buscar a próxima instrução
					proximo_estado <= s_le;
				END IF;
				
			WHEN s_executa_load => -- Ciclo de Execução do LOAD
				-- Habilita a escrita no AC com o dado vindo do dataBus
				ac_enable <= '1';
				-- addrBus já foi configurado no estado anterior
				proximo_estado <= s_le;
				
		END CASE;
	END PROCESS;
	
	-- sinais a serem passados para a TLE para apresentação
	-- no display de LCD na placa
	PCout <= PC;
	IRout <= IR;
	ACout <= AC;
	
END exec;