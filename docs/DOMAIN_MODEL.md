# DOMAIN_MODEL.md

# Mini BOP — Domain Model

> Modelo conceitual do domínio de negócio do Mini BOP.

> **Importante**
>
> Este documento descreve o domínio de forma conceitual. Sempre que houver dúvida sobre a implementação, o código-fonte e a documentação oficial do projeto são a fonte de verdade.

---

# Objetivo

Este documento apresenta os principais conceitos de negócio utilizados pelo Mini BOP antes de entrar nos detalhes técnicos da implementação.

Ele complementa:

- README.md
- ARCHITECTURE.md
- PROJECT_STRUCTURE.md
- Academy

---

# Visão do Domínio

```text
Mercado Financeiro
        │
        ▼
Instrumentos Financeiros
        │
        ▼
Trades
        │
        ▼
Validação
        │
        ▼
Transformação
        │
        ▼
Persistência
        │
        ▼
Governança
```

---

# Conceitos Fundamentais

## Instrumento Financeiro

Representa o ativo ou contrato negociado.

Exemplos:

- Equity
- Bond
- Future
- Option
- FX
- Swap

---

## Trade

Representa uma operação realizada utilizando um Instrumento Financeiro.

Um Trade descreve **o evento de negociação**, enquanto o Instrumento representa **o ativo negociado**.

---

## Master Data

Dados de referência utilizados durante o processamento.

Conceitualmente incluem cadastros relativamente estáveis utilizados pelas validações.

---

## Pipeline

Sequência organizada de etapas responsáveis por transformar dados recebidos em informações confiáveis para consumo.

---

# Modelo Conceitual

```text
Instrument
        │
        ▼
Trade
        │
        ▼
Validation
        │
        ▼
Transformation
        │
        ▼
Trade Repository
        │
        ▼
Trade Events
        │
        ▼
Recovery
        │
        ▼
Reconciliation
        │
        ▼
Data Quality
        │
        ▼
Audit & Lineage
```

---

# Linguagem do Domínio

| Conceito | Descrição |
|----------|-----------|
| Instrument | Ativo negociado |
| Trade | Operação financeira |
| Batch | Conjunto de Trades processados |
| Recovery | Reprocessamento controlado |
| Reconciliation | Evidência operacional |
| Data Quality | Avaliação da qualidade dos dados |
| Audit | Histórico operacional |
| Lineage | Rastreabilidade do dado |

---

# Relação com a Arquitetura

Este documento descreve **o domínio**.

Os detalhes técnicos são apresentados em:

- ARCHITECTURE.md
- Academy
- ADRs

---

# Relação com Big Data

Os mesmos conceitos de domínio permanecem válidos quando o processamento evolui para plataformas distribuídas.

A tecnologia muda; o domínio permanece.

---

# Próximos documentos

Sugestão de leitura:

1. ARCHITECTURE.md
2. Academy
3. ADR Index
4. Big Data Academy (quando disponível)
