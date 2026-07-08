# Módulo 05 — Pipeline Batch

> Entendendo como um Trade percorre o Mini BOP do início ao fim.

---

# Objetivo

Neste módulo você aprenderá:

- por que o Mini BOP utiliza processamento em lote (Batch);
- quais são as etapas do pipeline;
- como cada etapa possui uma responsabilidade específica;
- por que essa arquitetura facilita auditoria, recuperação e evolução.

---

# O que é um Pipeline?

Um pipeline é uma sequência organizada de etapas de processamento.

Cada etapa recebe uma entrada, executa uma responsabilidade bem definida e entrega o resultado para a etapa seguinte.

No Mini BOP, o pipeline foi desenhado para privilegiar **confiabilidade**, **governança** e **rastreabilidade**, antes mesmo da performance.

---

# Fluxo Conceitual

```mermaid
graph LR
A[Sistema Origem]
--> B[Staging]
--> C[Validação]
--> D[Transformação]
--> E[Persistência]
--> F[Eventos]
--> G[Observabilidade]
--> H[Recovery]
--> I[Reconciliation]
--> J[Data Quality]
--> K[Audit & Lineage]
--> L[Exportação]
```

---

# Etapas do Pipeline

## 1. Ingestão

Recebe os dados provenientes de sistemas externos.

Objetivos:

- preservar os dados originais;
- desacoplar origem e processamento;
- permitir reprocessamento.

---

## 2. Validação

Confirma se os dados atendem às regras de negócio e aos dados de referência.

Exemplos:

- instrumento existente;
- moeda válida;
- campos obrigatórios.

---

## 3. Transformação

Enriquece e normaliza os dados antes da carga definitiva.

---

## 4. Persistência

Os Trades aprovados são gravados no repositório principal.

---

## 5. Governança

Após a persistência entram responsabilidades operacionais:

- observabilidade;
- recovery;
- reconciliation;
- data quality;
- audit & lineage.

---

# Princípios Arquiteturais

O pipeline foi dividido em pequenas responsabilidades para:

- reduzir acoplamento;
- facilitar manutenção;
- permitir evolução independente de cada etapa.

Esse desenho também simplifica futuras migrações para plataformas distribuídas.

---

# Comparação com Data Engineering

As responsabilidades permanecem praticamente as mesmas em arquiteturas modernas.

| Mini BOP | Plataforma Moderna |
|-----------|--------------------|
| Scheduler | Airflow |
| Transformação | Spark / dbt |
| Exportação | Data Lake |
| Governança | Catálogo + Observabilidade |

---

# Resumo

Após este módulo você compreende:

- por que existe um pipeline;
- quais são suas etapas;
- como a arquitetura foi organizada;
- como ela prepara a evolução para Big Data.

➡ Próximo módulo: **06_PERFORMANCE.md**
