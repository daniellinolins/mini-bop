
# SEQUENCE_DIAGRAMS.md

# Mini BOP — Sequence Diagrams

> Diagramas de sequência conceituais do fluxo de processamento.

> **Importante**
>
> Estes diagramas representam o comportamento esperado em alto nível. O fluxo exato deve sempre ser validado no código-fonte e na documentação oficial do projeto.

---

# Objetivo

Demonstrar, passo a passo, como um Trade percorre o pipeline do Mini BOP.

---

# Fluxo Principal

```mermaid
sequenceDiagram

participant SRC as Sistema de Origem
participant ING as Ingestion
participant VAL as Validation
participant TRF as Transformation
participant DB as Persistence
participant GOV as Governance

SRC->>ING: Envia dados
ING->>VAL: Registros recebidos
VAL->>TRF: Dados validados
TRF->>DB: Dados preparados
DB->>GOV: Dados persistidos
```

---

# Fluxo de Recovery

```mermaid
sequenceDiagram

participant Batch
participant Recovery
participant Pipeline

Batch-->>Recovery: Falha detectada
Recovery->>Pipeline: Solicita reprocessamento
Pipeline-->>Recovery: Processamento concluído
```

---

# Fluxo de Reconciliation

```mermaid
sequenceDiagram

participant Pipeline
participant Recon
participant Report

Pipeline->>Recon: Resultado do processamento
Recon->>Report: Evidências operacionais
```

---

# Fluxo de Data Quality

```mermaid
sequenceDiagram

participant Pipeline
participant Quality
participant Metrics

Pipeline->>Quality: Dados processados
Quality->>Metrics: Indicadores de qualidade
```

---

# Observações

Os diagramas apresentados possuem finalidade didática e complementam:

- SYSTEM_CONTEXT.md
- CONTEXT_DIAGRAM.md
- COMPONENT_DIAGRAM.md
- ARCHITECTURE.md
- Mini BOP Academy

O detalhamento das chamadas entre packages deverá ser refinado durante o code review, utilizando exclusivamente o código do projeto como referência.

---

# Próximo passo

Após compreender os fluxos conceituais recomenda-se aprofundar a implementação consultando:

1. ARCHITECTURE.md
2. Academy
3. ADR
4. Código-fonte
