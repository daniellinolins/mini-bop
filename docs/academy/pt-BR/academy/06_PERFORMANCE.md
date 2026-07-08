# Módulo 06 — Performance

> Construindo pipelines eficientes sem comprometer a qualidade e a governança.

---

# Objetivo

Ao final deste módulo você deverá compreender:

- por que performance é um requisito arquitetural;
- como o Mini BOP trata grandes volumes de dados;
- os principais conceitos utilizados em Oracle para processamento em lote;
- como essas decisões facilitam uma futura evolução para Big Data.

---

# Performance como requisito

Em plataformas corporativas não basta produzir resultados corretos.

Os resultados precisam ser produzidos **dentro da janela operacional**.

Isso significa que desempenho faz parte dos requisitos funcionais do sistema.

---

# Principais objetivos

O pipeline procura:

- reduzir tempo de processamento;
- reduzir leituras desnecessárias;
- minimizar trocas entre SQL e PL/SQL;
- aumentar throughput;
- manter rastreabilidade.

---

# Conceitos apresentados

## Collections

Permitem carregar conjuntos de registros em memória para processamento mais eficiente.

---

## BULK COLLECT

Reduz o número de mudanças de contexto entre SQL e PL/SQL carregando vários registros em uma única operação.

---

## FORALL

Executa operações DML em lote utilizando os dados presentes nas Collections.

---

## Chunk Processing

Grandes volumes são divididos em pequenos blocos de processamento.

Benefícios:

- menor consumo de memória;
- recuperação simplificada;
- possibilidade de paralelismo futuro.

---

# Fluxo Conceitual

```mermaid
graph LR
A[Consulta SQL]
--> B[BULK COLLECT]
--> C[Collection]
--> D[FORALL]
--> E[Persistência]
```

---

# Decisão de Engenharia

A otimização foi mantida separada da lógica de negócio.

Isso significa que novas estratégias de processamento podem ser introduzidas sem alterar as regras funcionais.

---

# Evolução futura

Os mesmos conceitos serão comparados futuramente com:

- Apache Spark;
- processamento distribuído;
- particionamento;
- paralelismo.

---

# Resumo

Após este módulo você compreende:

- por que performance é importante;
- o papel de Collections, BULK COLLECT e FORALL;
- a importância do processamento em blocos;
- como a arquitetura prepara a evolução para plataformas distribuídas.

➡ Próximo módulo: **07_RECOVERY.md**
