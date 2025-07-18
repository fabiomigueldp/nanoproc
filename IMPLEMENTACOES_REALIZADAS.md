# 📋 Resumo das Implementações - Nanoprocessador Sequencial

## ✅ Implementações Realizadas

### 1. Unidade Lógica e Aritmética (ULA)
- **Sinais adicionados:**
  - `ula_out`: Saída de 16 bits da ULA
  - `ula_op`: Seletor de operação de 2 bits
- **Operações implementadas:**
  - `"00"`: SUM (AC + dataBus)
  - `"01"`: SUB (AC - dataBus)
- **Lógica combinacional:** Implementada com `WITH SELECT`

### 2. Novas Instruções Implementadas

#### 2.1 SUM (Opcode 00_HEX)
- **Funcionalidade:** AC ← AC + MEM[endereço]
- **Estado:** `s_executa_sum`
- **Operação ULA:** "00"

#### 2.2 SUB (Opcode 05_HEX)
- **Funcionalidade:** AC ← AC - MEM[endereço]
- **Estado:** `s_executa_sub`
- **Operação ULA:** "01"

#### 2.3 JNEG (Opcode 04_HEX)
- **Funcionalidade:** Se AC < 0, então PC ← endereço
- **Estado:** `s_executa_jneg`
- **Condição:** Verifica bit de sinal AC(15)

### 3. Conjunto Completo de Instruções
| Opcode | Instrução | Descrição |
|--------|-----------|-----------|
| 00     | SUM       | AC ← AC + MEM[endereço] |
| 01     | STORE     | MEM[endereço] ← AC |
| 02     | LOAD      | AC ← MEM[endereço] |
| 03     | JUMP      | PC ← endereço |
| 04     | JNEG      | Se AC < 0, PC ← endereço |
| 05     | SUB       | AC ← AC - MEM[endereço] |

### 4. Máquina de Estados Atualizada
- **Estados adicionados:**
  - `s_executa_sum`
  - `s_executa_sub`
  - `s_executa_jneg`
- **Lógica de endereçamento:** Atualizada para incluir SUM e SUB

## 📁 Arquivos Atualizados

### 1. `nanoProc.vhd`
- ✅ ULA implementada
- ✅ Três novas instruções (SUM, SUB, JNEG)
- ✅ Máquina de estados completa
- ✅ Sintaxe VHDL correta

### 2. `PROGRAM.MIF`
- ✅ Programa de teste da Fase 3
- ✅ Teste de soma (13 + 5 = 18)
- ✅ Teste de saltos condicionais

### 3. `final_program.mif` (NOVO)
- ✅ Algoritmo da Seção 5.1 implementado
- ✅ Comparação de notas e soma
- ✅ Lógica condicional completa

## 🧪 Programa de Teste da Fase 3 (PROGRAM.MIF)
```assembly
00: LOAD 08    ; AC = 13
01: SUM 09     ; AC = 13 + 5 = 18
02: JUMP 04    ; Pula para endereço 04
03: JUMP 03    ; Loop infinito
04: STORE 0A   ; MEM[0A] = 18
05: JNEG 03    ; Não salta (AC = 18 > 0)
06: LOAD 0B    ; AC = -1
07: JNEG 03    ; Salta para loop (AC = -1 < 0)
```

## 🎯 Algoritmo Final (final_program.mif)
O programa implementa o algoritmo especificado:
1. **Soma das notas:** Carrega nota1 (3A) e soma nota2 (3B)
2. **Teste condicional:** Se soma > 12, salva em 3C, senão salva 0
3. **Comparação:** Determina a maior nota e salva em endereço 40

### Exemplo com valores de teste:
- Nota1 = 8, Nota2 = 7
- Soma = 15 (> 12) → Salva 15 em 3C
- Maior nota = 8 → Salva 8 em endereço 40

## ✅ Critérios de Sucesso Atendidos
1. ✅ Código VHDL sintaticamente correto
2. ✅ ULA implementada com operações SUM e SUB
3. ✅ Três novas instruções funcionais
4. ✅ Máquina de estados completa (6 instruções)
5. ✅ Programa de teste da Fase 3 implementado
6. ✅ Programa final da Seção 5.1 implementado
