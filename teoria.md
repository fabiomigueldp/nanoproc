# 📚 Teoria Completa do Nanoprocessador Sequencial

## 📖 Índice
1. [Introdução aos Processadores](#1-introdução-aos-processadores)
2. [Arquitetura do Nanoprocessador](#2-arquitetura-do-nanoprocessador)
3. [Máquinas de Estados Finitos](#3-máquinas-de-estados-finitos)
4. [Ciclo de Execução de Instruções](#4-ciclo-de-execução-de-instruções)
5. [Conjunto de Instruções](#5-conjunto-de-instruções)
6. [Estrutura dos Arquivos do Projeto](#6-estrutura-dos-arquivos-do-projeto)
7. [Implementação em VHDL](#7-implementação-em-vhdl)
8. [Análise do Código Implementado](#8-análise-do-código-implementado)

---

## 1. Introdução aos Processadores

### 1.1 O que é um Processador?
Um **processador** (ou CPU - Central Processing Unit) é o "cérebro" de qualquer sistema computacional. Ele é responsável por:
- **Buscar** instruções da memória
- **Decodificar** essas instruções
- **Executar** as operações especificadas
- **Armazenar** os resultados

### 1.2 Componentes Básicos de um Processador
Todo processador possui elementos fundamentais:

- **🧠 Unidade de Controle (UC)**: Coordena todas as operações
- **🔢 Unidade Lógica e Aritmética (ULA)**: Realiza cálculos e operações lógicas
- **📋 Registradores**: Armazenamento temporário de dados
- **🔗 Barramentos**: Caminhos para transferência de dados

### 1.3 Tipos de Arquiteturas
- **Von Neumann**: Instruções e dados compartilham a mesma memória
- **Harvard**: Instruções e dados têm memórias separadas
- **RISC**: Conjunto reduzido de instruções simples
- **CISC**: Conjunto complexo de instruções

**Nosso nanoprocessador segue a arquitetura Von Neumann com características RISC.**

---

## 2. Arquitetura do Nanoprocessador

### 2.1 Visão Geral da Arquitetura

```
    ┌─────────────────────────────────────────────────────────┐
    │                NANOPROCESSADOR                          │
    │                                                         │
    │  ┌──────────┐    ┌──────────┐    ┌──────────┐           │
    │  │    PC    │    │    IR    │    │    AC    │           │
    │  │ (8 bits) │    │(16 bits) │    │(16 bits) │           │
    │  └──────────┘    └──────────┘    └──────────┘           │
    │                                                         │
    │              ┌──────────────────┐                       │
    │              │  Máquina de      │                       │
    │              │  Estados (MEF)   │                       │
    │              └──────────────────┘                       │
    │                                                         │
    │  ┌─────────────────────────────────────────────────┐    │
    │  │              MEMÓRIA (256x16)                   │    │
    │  │  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐    │    │
    │  │  │ 00H │ 01H │ 02H │ ... │ FEH │ FFH │     │    │    │
    │  │  └─────┴─────┴─────┴─────┴─────┴─────┴─────┘    │    │
    │  └─────────────────────────────────────────────────┘    │
    └─────────────────────────────────────────────────────────┘
```

### 2.2 Registradores Principais

#### 📍 **PC (Program Counter) - Contador de Programa**
- **Tamanho**: 8 bits (endereça 256 posições)
- **Função**: Armazena o endereço da próxima instrução a ser executada
- **Comportamento**: Incrementa automaticamente após buscar cada instrução

#### 📋 **IR (Instruction Register) - Registrador de Instrução**
- **Tamanho**: 16 bits
- **Função**: Armazena a instrução atual sendo executada
- **Estrutura**:
  ```
  |15    8|7     0|
  |-------|-------|
  |OPCODE |OPERAND|
  ```
  - **Bits 15-8**: Código da operação (opcode)
  - **Bits 7-0**: Operando (endereço ou dado)

#### 🎯 **AC (Accumulator) - Acumulador**
- **Tamanho**: 16 bits
- **Função**: Registrador principal para operações aritméticas e lógicas
- **Comportamento**: Recebe resultados de operações e dados carregados da memória

### 2.3 Memória
- **Capacidade**: 256 palavras de 16 bits cada
- **Endereçamento**: 8 bits (00H a FFH)
- **Tipo**: Unificada (instruções e dados no mesmo espaço)
- **Inicialização**: Arquivo PROGRAM.MIF define o conteúdo inicial

---

## 3. Máquinas de Estados Finitos

### 3.1 Conceito de MEF
Uma **Máquina de Estados Finitos** é um modelo matemático que descreve o comportamento de um sistema através de:
- **Estados**: Situações específicas do sistema
- **Transições**: Mudanças entre estados
- **Condições**: Eventos que causam transições

### 3.2 Tipos de MEF
- **Moore**: Saídas dependem apenas do estado atual
- **Mealy**: Saídas dependem do estado atual e das entradas

**Nosso nanoprocessador usa uma MEF do tipo Moore.**

### 3.3 Estados do Nanoprocessador

```
     ┌─────────────┐
     │  s_inicia   │
     │ (inicial)   │
     └─────┬───────┘
           │
           ▼
     ┌─────────────┐     ┌─────────────────┐
     │    s_le     │────▶│ s_decodifica    │
     │  (fetch)    │     │ (decode)        │
     └─────▲───────┘     └─────┬───────────┘
           │                   │
           │                   ▼
           │             ┌─────────────────┐
           └─────────────│ s_executa_load  │
                         │ (execute LOAD)  │
                         └─────────────────┘
```

#### 🔄 **s_inicia** (Estado Inicial)
- **Função**: Estado de inicialização após reset
- **Ações**: Nenhuma (registradores já foram zerados)
- **Próximo**: Sempre vai para `s_le`

#### 📖 **s_le** (Leitura/Fetch)
- **Função**: Busca a próxima instrução na memória
- **Ações**:
  - Coloca PC no barramento de endereços
  - Habilita carregamento da instrução no IR
  - Habilita incremento do PC
- **Próximo**: Sempre vai para `s_decodifica`

#### 🔍 **s_decodifica** (Decodificação)
- **Função**: Analisa a instrução e decide o que fazer
- **Ações**:
  - Examina o opcode da instrução
  - Se for LOAD (02H): prepara endereço do operando
  - Se não for LOAD: volta para buscar próxima instrução
- **Próximo**: `s_executa_load` ou `s_le`

#### ⚡ **s_executa_load** (Execução LOAD)
- **Função**: Executa a instrução LOAD
- **Ações**:
  - Habilita carregamento do dado da memória no AC
- **Próximo**: Sempre vai para `s_le`

---

## 4. Ciclo de Execução de Instruções

### 4.1 Ciclo Clássico Fetch-Decode-Execute

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    FETCH     │───▶│    DECODE    │───▶│   EXECUTE    │
│  (Buscar)    │    │ (Decodificar)│    │  (Executar)  │
└──────────────┘    └──────────────┘    └──────┬───────┘
       ▲                                       │
       └───────────────────────────────────────┘
```

### 4.2 Exemplo Prático: Execução de LOAD 10H

**Instrução**: `0210` (LOAD endereço 10H)

#### **Clock 1 - Estado s_le**
```
PC = 00H, IR = 0000H, AC = 0000H
Ações:
- addrBus ← PC (00H)
- Memória[00H] → dataBus (0210H)
- ir_enable = '1' (prepara carregamento do IR)
- pc_enable = '1' (prepara incremento do PC)
```

#### **Clock 2 - Estado s_decodifica**
```
PC = 01H, IR = 0210H, AC = 0000H
Ações:
- IR(15-8) = 02H → Detecta instrução LOAD
- addrBus ← IR(7-0) (10H)
- Memória[10H] → dataBus (00AAH)
- Próximo estado: s_executa_load
```

#### **Clock 3 - Estado s_executa_load**
```
PC = 01H, IR = 0210H, AC = 0000H
Ações:
- ac_enable = '1' (carrega dataBus no AC)
- Próximo estado: s_le
```

#### **Clock 4 - Estado s_le (próxima instrução)**
```
PC = 01H, IR = 0210H, AC = 00AAH
A instrução LOAD foi concluída!
```

---

## 5. Conjunto de Instruções

### 5.1 Formato das Instruções
Todas as instruções seguem o formato de 16 bits:

```
|15    8|7     0|
|-------|-------|
|OPCODE |OPERAND|
```

### 5.2 Instrução LOAD (Implementada na Fase 1)

#### **LOAD** - Carregar da Memória
- **Opcode**: `02H`
- **Formato**: `02XX` (onde XX é o endereço)
- **Operação**: `AC ← Memória[XX]`
- **Exemplo**: `0210` carrega o conteúdo do endereço 10H no AC

### 5.3 Instruções Futuras (Fases 2 e 3)

#### **STORE** - Armazenar na Memória
- **Opcode**: `01H`
- **Operação**: `Memória[XX] ← AC`

#### **ADD** - Somar
- **Opcode**: `00H`
- **Operação**: `AC ← AC + Memória[XX]`

#### **SUB** - Subtrair
- **Opcode**: `05H`
- **Operação**: `AC ← AC - Memória[XX]`

#### **JUMP** - Salto Incondicional
- **Opcode**: `03H`
- **Operação**: `PC ← XX`

#### **JNEG** - Salto se Negativo
- **Opcode**: `04H`
- **Operação**: `Se AC < 0 então PC ← XX`

---

## 6. Estrutura dos Arquivos do Projeto

### 6.1 Arquivos Principais

#### **📄 nanoProc.vhd**
```
Descrição: Módulo principal do processador
Contém:
- Definição da entidade nanoProc
- Máquina de estados finitos
- Lógica de controle dos registradores
- Conexão com a memória
```

#### **📄 DMEMORY.VHD**
```
Descrição: Módulo de memória unificada
Características:
- 256 palavras de 16 bits
- Interface síncrona
- Inicialização via PROGRAM.MIF
- Suporte a leitura e escrita
```

#### **📄 TLE_Proc.vhd**
```
Descrição: Top-level entity (módulo principal)
Função:
- Conecta nanoProc com LCD
- Gerencia sinais de clock
- Interface com a placa FPGA
```

#### **📄 LCD_Display.vhd**
```
Descrição: Controlador do display LCD
Função:
- Mostra valores dos registradores
- Interface de usuário visual
```

#### **📄 PROGRAM.MIF**
```
Descrição: Arquivo de inicialização da memória
Conteúdo:
- Programa de teste
- Dados de exemplo
- Formato hexadecimal
```

### 6.2 Hierarquia do Projeto

```
TLE_Proc (Top Level)
├── nanoProc (Processador)
│   └── dmemory (Memória)
└── LCD_Display (Interface)
```

---

## 7. Implementação em VHDL

### 7.1 Conceitos de VHDL Utilizados

#### **Tipos de Dados**
```vhdl
-- Tipo personalizado para estados
TYPE t_estado IS (s_inicia, s_le, s_decodifica, s_executa_load);

-- Vetores de bits
SIGNAL AC : STD_LOGIC_VECTOR(15 DOWNTO 0);  -- 16 bits
SIGNAL PC : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- 8 bits
```

#### **Processos Sequenciais**
```vhdl
-- Sensível a clock e reset
PROCESS (clock, reset)
BEGIN
    IF (reset = '1') THEN
        -- Inicialização
    ELSIF rising_edge(clock) THEN
        -- Lógica síncrona
    END IF;
END PROCESS;
```

#### **Processos Combinacionais**
```vhdl
-- Sensível a mudanças nos sinais
PROCESS (estado_atual, IR, dataBus)
BEGIN
    -- Lógica combinacional
    CASE estado_atual IS
        WHEN s_inicia =>
            -- Ações do estado
    END CASE;
END PROCESS;
```

### 7.2 Sinais de Controle

#### **Sinais de Enable (Habilitação)**
- **pc_enable**: Controla quando o PC é incrementado
- **ir_enable**: Controla quando o IR é carregado
- **ac_enable**: Controla quando o AC é carregado

#### **Barramentos**
- **addrBus**: Barramento de endereços (8 bits)
- **dataBus**: Barramento de dados (16 bits)

#### **Controle de Memória**
- **MW (Memory Write)**: Controla escrita na memória

---

## 8. Análise do Código Implementado

### 8.1 Declarações e Sinais

```vhdl
-- Tipo para máquina de estados
TYPE t_estado IS (s_inicia, s_le, s_decodifica, s_executa_load);

-- Registradores principais
SIGNAL AC, dataBus, IR : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL PC, addrBus     : STD_LOGIC_VECTOR(7 DOWNTO 0);

-- Controle da máquina de estados
SIGNAL estado_atual, proximo_estado : t_estado;

-- Sinais de habilitação
SIGNAL pc_enable, ir_enable, ac_enable : STD_LOGIC;
```

**Explicação**:
- Define todos os tipos e sinais necessários
- Separação clara entre dados (16 bits) e endereços (8 bits)
- Controle explícito através de sinais de enable

### 8.2 Processo Sequencial Principal

```vhdl
PROCESS (clock, reset)
BEGIN
    IF (reset = '1') THEN
        PC <= X"00";
        IR <= X"0000";
        AC <= X"0000";
        estado_atual <= s_inicia;
    ELSIF rising_edge(clock) THEN
        -- Atualização condicional dos registradores
        IF (pc_enable = '1') THEN
            PC <= PC + 1;
        END IF;
        IF (ir_enable = '1') THEN
            IR <= dataBus;
        END IF;
        IF (ac_enable = '1') THEN
            AC <= dataBus;
        END IF;
        -- Atualização do estado
        estado_atual <= proximo_estado;
    END IF;
END PROCESS;
```

**Características importantes**:
- **Reset assíncrono**: Inicializa imediatamente quando reset='1'
- **Controle condicional**: Registradores só mudam se habilitados
- **Sincronização**: Tudo ocorre na borda de subida do clock

### 8.3 Processo Combinacional de Controle

```vhdl
PROCESS (estado_atual, IR, dataBus)
BEGIN
    -- Valores padrão (evita latches)
    pc_enable <= '0';
    ir_enable <= '0';
    ac_enable <= '0';
    MW <= '0';
    addrBus <= PC;
    proximo_estado <= estado_atual;
    
    CASE estado_atual IS
        WHEN s_inicia =>
            proximo_estado <= s_le;
            
        WHEN s_le =>
            addrBus <= PC;
            ir_enable <= '1';
            pc_enable <= '1';
            proximo_estado <= s_decodifica;
            
        WHEN s_decodifica =>
            IF IR(15 DOWNTO 8) = X"02" THEN
                addrBus <= "00000000" & IR(7 DOWNTO 0);
                proximo_estado <= s_executa_load;
            ELSE
                proximo_estado <= s_le;
            END IF;
            
        WHEN s_executa_load =>
            ac_enable <= '1';
            proximo_estado <= s_le;
    END CASE;
END PROCESS;
```

**Pontos-chave**:
- **Valores padrão**: Evita inferência de latches indesejados
- **Estrutura CASE**: Clara separação das ações por estado
- **Decodificação**: Análise do opcode para determinar a instrução

### 8.4 Fluxo de Execução Detalhado

#### **1. Inicialização (Reset)**
```
Estado: s_inicia
PC = 00H, IR = 0000H, AC = 0000H
Próximo: s_le
```

#### **2. Busca de Instrução (Fetch)**
```
Estado: s_le
Ações:
- addrBus = PC (endereço da instrução)
- ir_enable = '1' (carrega instrução no próximo clock)
- pc_enable = '1' (incrementa PC no próximo clock)
Próximo: s_decodifica
```

#### **3. Decodificação**
```
Estado: s_decodifica
Ações:
- Analisa IR(15-8) para identificar opcode
- Se opcode = 02H (LOAD):
  * addrBus = IR(7-0) (endereço do operando)
  * Próximo: s_executa_load
- Se opcode ≠ 02H:
  * Próximo: s_le (ignora instrução)
```

#### **4. Execução LOAD**
```
Estado: s_executa_load
Ações:
- ac_enable = '1' (carrega dado no AC)
- O dado vem de dataBus (memória)
Próximo: s_le
```

### 8.5 Vantagens da Implementação

#### ✅ **Modularidade**
- Separação clara entre lógica sequencial e combinacional
- Estados bem definidos e independentes

#### ✅ **Controle Preciso**
- Registradores só mudam quando necessário
- Evita atualizações desnecessárias

#### ✅ **Extensibilidade**
- Fácil adição de novos estados
- Estrutura preparada para novas instruções

#### ✅ **Robustez**
- Valores padrão evitam comportamentos indefinidos
- Reset garante estado inicial conhecido

### 8.6 Diferenças da Versão Original

#### **Antes (Versão Simplista)**
```vhdl
PROCESS (clock, reset)
BEGIN
    IF (reset = '1') THEN
        PC <= X"00";
        IR <= X"0000";
        AC <= X"0000";
    ELSIF clock'EVENT AND clock = '1' THEN
        IR <= dataBus;  -- Sempre carrega
        PC <= PC + 1;   -- Sempre incrementa
    END IF;
END PROCESS;
```

**Problemas**:
- Atualização incondicional a cada clock
- Sem controle de quando fazer cada operação
- Sem suporte a diferentes instruções

#### **Depois (Versão com MEF)**
```vhdl
-- Controle preciso com sinais de enable
IF (pc_enable = '1') THEN
    PC <= PC + 1;
END IF;
IF (ir_enable = '1') THEN
    IR <= dataBus;
END IF;
-- ... e máquina de estados completa
```

**Vantagens**:
- Controle temporal preciso
- Suporte a múltiplas instruções
- Base sólida para expansão

---

## 🎯 Conclusão

Este projeto implementa um **nanoprocessador educacional** que demonstra os conceitos fundamentais de arquitetura de computadores:

1. **🧠 Processamento Sequencial**: Execução passo-a-passo de instruções
2. **🔄 Máquina de Estados**: Controle sistemático do fluxo de execução
3. **📊 Gestão de Recursos**: Uso eficiente de registradores e memória
4. **⚡ Sincronização**: Coordenação temporal via clock

A implementação da **instrução LOAD** na Fase 1 estabelece a base para:
- **Fase 2**: Adição de mais instruções (STORE, ADD, SUB)
- **Fase 3**: Implementação de saltos condicionais e incondicionais

O projeto é uma excelente introdução ao mundo dos processadores, combinando teoria sólida com implementação prática em VHDL.
