# Relatório de Investigação: Problema com Instrução JUMP

## Problema Identificado
A instrução JUMP nunca é executada na simulação, mesmo com o programa de teste modificado. O processador alterna apenas entre os estados `s_le`, `s_decodifica` e `s_executa_load`, mas nunca atinge `s_executa_jump`.

## Análise da Simulação
Observando a forma de onda da simulação:
- **Clock**: 100 ps de período
- **Reset**: Pulso inicial de 70 ps
- **Estados**: Alternando entre `s_le` → `s_decodifica` → `s_executa_...` → `s_le`
- **PC**: Incrementando sequencialmente (00, 01, 02, etc.)
- **IR**: Carregando valores da memória

## Investigação Detalhada

### 1. Análise Temporal da Máquina de Estados
O problema está relacionado ao **timing** da máquina de estados. Vamos analisar o ciclo de execução:

**Ciclo 1 (PC=00):**
- Estado: `s_le` → IR carrega `0210` (LOAD 10)
- Próximo estado: `s_decodifica`

**Ciclo 2:**
- Estado: `s_decodifica` → Analisa IR = `0210`
- Opcode = `02` → Próximo estado: `s_executa_load`

**Ciclo 3:**
- Estado: `s_executa_load` → AC carrega dados
- Próximo estado: `s_le`

**Ciclo 4 (PC=01):**
- Estado: `s_le` → IR deveria carregar `0305` (JUMP 05)
- **PROBLEMA CRÍTICO IDENTIFICADO**

### 2. Causa Raiz do Problema

#### **PROBLEMA 1: Timing do Carregamento do IR**
No estado `s_le`, o IR é carregado com `dataBus`, mas há um problema de timing:

```vhdl
WHEN s_le => -- Ciclo de Busca (Fetch)
    IR <= dataBus;
    PC <= PC + 1;
```

O `dataBus` ainda pode conter o valor da operação anterior, causando uma condição de corrida (race condition).

#### **PROBLEMA 2: Ordem das Atualizações dos Registradores**
No processo sequencial, o estado é atualizado **ANTES** dos registradores:

```vhdl
ELSIF rising_edge(clock) THEN
    -- Atualiza estado da máquina
    estado_atual <= proximo_estado;  -- ← ATUALIZADO PRIMEIRO
    
    -- Atualiza registradores conforme o estado
    CASE estado_atual IS              -- ← USA O ESTADO ANTIGO!
```

Isso significa que quando `estado_atual` muda para `s_le`, o `CASE` ainda vê o estado anterior, causando um atraso de um ciclo.

#### **PROBLEMA 3: Dependência do addrBus**
O `addrBus` é configurado baseado no `estado_atual`:

```vhdl
WITH estado_atual SELECT
    addrBus <= IR(7 DOWNTO 0) WHEN s_executa_load,
               PC WHEN OTHERS;
```

Quando o estado muda, o `addrBus` muda, mas a memória pode não ter tempo suficiente para responder.

### 3. Evidências na Simulação
- **PC está incrementando**: Indica que `s_le` está sendo executado
- **Nunca aparece s_executa_jump**: Indica que a decodificação não está reconhecendo o opcode `03`
- **Padrão regular**: `s_le` → `s_decodifica` → `s_executa_load` sugere que todas as instruções estão sendo interpretadas como LOAD

## Diagnóstico Final
O IR não está sendo carregado corretamente com a instrução JUMP (`0305`) no endereço `01`. Provavelmente está mantendo o valor anterior (`0210`) ou carregando um valor incorreto devido aos problemas de timing identificados.

## Solução Implementada

### Correção Principal: Reordenação da Atualização de Estado
O problema principal estava na ordem das atualizações no processo sequencial. A correção implementada foi:

**ANTES (Problemático):**
```vhdl
ELSIF rising_edge(clock) THEN
    -- Atualiza estado da máquina
    estado_atual <= proximo_estado;  -- ← PRIMEIRO
    
    -- Atualiza registradores conforme o estado
    CASE estado_atual IS              -- ← USA ESTADO ANTIGO!
```

**DEPOIS (Corrigido):**
```vhdl
ELSIF rising_edge(clock) THEN
    -- Atualiza registradores conforme o estado ATUAL (antes de mudar)
    CASE estado_atual IS              -- ← USA ESTADO ATUAL!
        WHEN s_le =>
            IR <= dataBus;
            PC <= PC + 1;
        WHEN s_executa_jump =>
            PC <= IR(7 DOWNTO 0);     -- ← JUMP IMPLEMENTADO CORRETAMENTE
        -- ...
    END CASE;
    
    -- Atualiza estado da máquina DEPOIS dos registradores
    estado_atual <= proximo_estado;  -- ← POR ÚLTIMO
```

### Por que a Correção Resolve o Problema

1. **Timing Correto**: Os registradores são atualizados baseados no estado atual, não no próximo estado
2. **IR Carregado Corretamente**: No estado `s_le`, o IR agora carrega o valor correto do `dataBus`
3. **JUMP Executado**: No estado `s_executa_jump`, o PC é atualizado antes da transição de estado

### Comportamento Esperado Após a Correção

**Sequência de Execução:**
1. **PC=00, Estado=s_le**: Carrega IR com `0210` (LOAD 10), PC → 01
2. **PC=01, Estado=s_decodifica**: Reconhece opcode `02`, próximo estado → `s_executa_load`
3. **PC=01, Estado=s_executa_load**: Carrega AC com valor `00AA`, próximo estado → `s_le`
4. **PC=01, Estado=s_le**: Carrega IR com `0305` (JUMP 05), PC → 02
5. **PC=02, Estado=s_decodifica**: Reconhece opcode `03`, próximo estado → `s_executa_jump` ✅
6. **PC=02, Estado=s_executa_jump**: PC ← `05`, próximo estado → `s_le` ✅
7. **PC=05, Estado=s_le**: Carrega IR com `0212` (LOAD 12), PC → 06
8. **Loop continua...**

### Validação da Correção
Após implementar a correção, a simulação deve mostrar:
- ✅ Estado `s_executa_jump` aparecendo na forma de onda
- ✅ PC saltando de 02 para 05 (primeira instrução JUMP)
- ✅ PC saltando de 06 para 00 (segunda instrução JUMP)
- ✅ Endereços 02, 03, 04 nunca sendo acessados
- ✅ AC alternando entre `00AA` e `0000`
