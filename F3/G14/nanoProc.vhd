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
TYPE t_estado IS (s_inicia, s_le, s_decodifica, s_executa_load, s_executa_jump, s_executa_store, s_executa_sum, s_executa_sub, s_executa_jneg);

SIGNAL AC, dataBus, IR	: STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL PC, addrBus		: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL MW					: STD_LOGIC;

-- Sinais da máquina de estados
SIGNAL estado_atual, proximo_estado : t_estado;

-- Sinais da ULA
SIGNAL ula_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL ula_op : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN
	-- Lógica da ULA (combinacional)
	WITH ula_op SELECT
		ula_out <= AC + dataBus WHEN "00", -- SUM
		           AC - dataBus WHEN "01", -- SUB
		           AC WHEN OTHERS;

	-- Lógica do address bus (combinacional, fora do processo)
	-- Usa PC para busca de instrução, IR(7 downto 0) para acesso a dados no LOAD, STORE, SUM e SUB
	WITH estado_atual SELECT
		addrBus <= IR(7 DOWNTO 0) WHEN s_executa_load | s_executa_store | s_executa_sum | s_executa_sub,
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
			-- Atualiza registradores conforme o estado ATUAL (antes de mudar)
			CASE estado_atual IS
				WHEN s_le => -- Ciclo de Busca (Fetch)
					IR <= dataBus;
					PC <= PC + 1;
				
				WHEN s_executa_jump => -- Ciclo de Execução do JUMP
					PC <= IR(7 DOWNTO 0);
					
				WHEN s_executa_load => -- Ciclo de Execução do LOAD
					AC <= dataBus;
					
				WHEN s_executa_sum => -- Ciclo de Execução do SUM
					AC <= ula_out;
					
				WHEN s_executa_sub => -- Ciclo de Execução do SUB
					AC <= ula_out;
					
				WHEN s_executa_jneg => -- Ciclo de Execução do JNEG
					IF (AC(15) = '1') THEN -- Verifica se AC é negativo (bit de sinal)
						PC <= IR(7 DOWNTO 0);
					END IF;
					
				WHEN OTHERS =>
					-- Nenhuma atualização necessária
			END CASE;
			
			-- Atualiza estado da máquina DEPOIS dos registradores
			estado_atual <= proximo_estado;
		END IF;
	END PROCESS;
	
	-- Processo combinacional para controle da máquina de estados
	PROCESS (estado_atual, IR)
	BEGIN
		-- Valores padrão para evitar latches
		MW <= '0';
		ula_op <= "00"; -- Operação padrão da ULA
		proximo_estado <= estado_atual;
		
		CASE estado_atual IS
			WHEN s_inicia =>
				proximo_estado <= s_le;
				
			WHEN s_le => -- Ciclo de Busca (Fetch)
				proximo_estado <= s_decodifica;
				
			WHEN s_decodifica => -- Ciclo de Decodificação
				-- Verifica o opcode da instrução (8 bits mais significativos)
				IF IR(15 DOWNTO 8) = X"00" THEN -- Instrução SUM (opcode 00_HEX)
					proximo_estado <= s_executa_sum;
				ELSIF IR(15 DOWNTO 8) = X"01" THEN -- Instrução STORE (opcode 01_HEX)
					proximo_estado <= s_executa_store;
				ELSIF IR(15 DOWNTO 8) = X"02" THEN -- Instrução LOAD (opcode 02_HEX)
					proximo_estado <= s_executa_load;
				ELSIF IR(15 DOWNTO 8) = X"03" THEN -- Instrução JUMP (opcode 03_HEX)
					proximo_estado <= s_executa_jump;
				ELSIF IR(15 DOWNTO 8) = X"04" THEN -- Instrução JNEG (opcode 04_HEX)
					proximo_estado <= s_executa_jneg;
				ELSIF IR(15 DOWNTO 8) = X"05" THEN -- Instrução SUB (opcode 05_HEX)
					proximo_estado <= s_executa_sub;
				ELSE
					-- Se a instrução não for reconhecida, volta a buscar a próxima
					proximo_estado <= s_le;
				END IF;
				
			WHEN s_executa_load => -- Ciclo de Execução do LOAD
				-- addrBus é automaticamente configurado pelo WITH SELECT
				proximo_estado <= s_le;
				
			WHEN s_executa_jump => -- Ciclo de Execução do JUMP
				proximo_estado <= s_le;
				
			WHEN s_executa_store => -- Ciclo de Execução do STORE
				MW <= '1'; -- Habilita a escrita na memória!
				proximo_estado <= s_le;
				
			WHEN s_executa_sum => -- Ciclo de Execução do SUM
				ula_op <= "00"; -- Operação de soma na ULA
				proximo_estado <= s_le;
				
			WHEN s_executa_sub => -- Ciclo de Execução do SUB
				ula_op <= "01"; -- Operação de subtração na ULA
				proximo_estado <= s_le;
				
			WHEN s_executa_jneg => -- Ciclo de Execução do JNEG
				proximo_estado <= s_le;
				
		END CASE;
	END PROCESS;
	
	-- sinais a serem passados para a TLE para apresentação
	-- no display de LCD na placa
	PCout <= PC;
	IRout <= IR;
	ACout <= AC;
	
END exec;