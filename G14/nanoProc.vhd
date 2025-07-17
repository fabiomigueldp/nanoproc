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

BEGIN
	-- Lógica do address bus (combinacional, fora do processo)
	-- Usa PC para busca de instrução, IR(7 downto 0) para acesso a dados no LOAD
	WITH estado_atual SELECT
		addrBus <= IR(7 DOWNTO 0) WHEN s_executa_load,
		           PC WHEN OTHERS;
	
	-- Componente de memória definida no arquivo DMEMORY.vhd
	memoria : dmemory PORT MAP(	
							read_data	=> dataBus,
							address		=> addrBus,
							write_data	=> AC,
							memWrite		=> MW,
							clock			=> clock,
							reset			=> reset);
							
	-- PC, IR e AC são registradores, portanto sensíveis ao clock
	-- Processo sequencial principal
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN
			PC <= X"00";
			IR <= X"0000";
			AC <= X"0000";
			estado_atual <= s_inicia;
		ELSIF rising_edge(clock) THEN
			-- Atualiza estado da máquina
			estado_atual <= proximo_estado;
			
			-- Atualiza registradores conforme o estado
			CASE estado_atual IS
				WHEN s_le => -- Ciclo de Busca (Fetch)
					IR <= dataBus;
					PC <= PC + 1;
					
				WHEN s_executa_load => -- Ciclo de Execução do LOAD
					AC <= dataBus;
					
				WHEN OTHERS =>
					-- Nenhuma atualização necessária
			END CASE;
		END IF;
	END PROCESS;
	
	-- Processo combinacional para controle da máquina de estados
	PROCESS (estado_atual, IR)
	BEGIN
		-- Valores padrão para evitar latches
		MW <= '0';
		proximo_estado <= estado_atual;
		
		CASE estado_atual IS
			WHEN s_inicia =>
				proximo_estado <= s_le;
				
			WHEN s_le => -- Ciclo de Busca (Fetch)
				proximo_estado <= s_decodifica;
				
			WHEN s_decodifica => -- Ciclo de Decodificação
				-- Verifica o opcode da instrução (8 bits mais significativos)
				IF IR(15 DOWNTO 8) = X"02" THEN -- Instrução LOAD (opcode 02_HEX)
					proximo_estado <= s_executa_load;
				ELSE
					-- Se não for LOAD, volta a buscar a próxima instrução
					proximo_estado <= s_le;
				END IF;
				
			WHEN s_executa_load => -- Ciclo de Execução do LOAD
				-- addrBus é automaticamente configurado pelo WITH SELECT
				proximo_estado <= s_le;
				
		END CASE;
	END PROCESS;
	
	-- sinais a serem passados para a TLE para apresentação
	-- no display de LCD na placa
	PCout <= PC;
	IRout <= IR;
	ACout <= AC;
	
END exec;