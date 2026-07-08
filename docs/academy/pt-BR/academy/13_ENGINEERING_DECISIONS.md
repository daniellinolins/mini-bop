# Módulo 13 — Engineering Decisions

> Entendendo as principais decisões arquiteturais adotadas no Mini BOP.

---

# Objetivo

Este módulo resume as decisões de engenharia observadas ao longo da Academy e explica por que elas contribuem para uma arquitetura sustentável.

---

# Princípios adotados

## Separação de Responsabilidades

Cada componente possui uma responsabilidade específica.

Benefícios:

- menor acoplamento;
- maior coesão;
- manutenção simplificada.

---

## Pipeline em Camadas

O processamento é dividido em etapas independentes:

- Ingestão
- Validação
- Transformação
- Persistência
- Governança

Essa organização facilita testes, evolução e reprocessamento.

---

## Governança Integrada

Recursos como:

- Recovery
- Reconciliation
- Data Quality
- Audit & Lineage

fazem parte da arquitetura principal, e não de processos externos.

---

## Processamento Batch

O processamento em lote favorece:

- previsibilidade;
- auditoria;
- repetibilidade;
- controle operacional.

---

## Evolução Tecnológica

Uma decisão importante foi separar responsabilidades de tecnologia.

Assim, a mesma arquitetura pode evoluir para Hadoop, Spark, Airflow ou dbt sem alterar os conceitos fundamentais.

---

# Trade-offs

Toda decisão arquitetural possui vantagens e limitações.

Exemplos:

| Decisão | Benefício | Trade-off |
|---------|-----------|-----------|
| Batch | Controle operacional | Maior latência |
| Camadas | Organização | Mais componentes |
| Governança | Confiabilidade | Complexidade adicional |

---

# Lições Aprendidas

- Arquitetura é mais importante que tecnologia.
- Governança deve nascer junto com o pipeline.
- Responsabilidades bem definidas simplificam a evolução.

---

# Resumo

Após este módulo você compreende as principais decisões de engenharia que orientam o desenho do Mini BOP e servem de base para futuras evoluções.

➡ Próximo módulo: **14_TECHNICAL_DEBT.md**
