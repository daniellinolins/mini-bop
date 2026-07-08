# Módulo 09 — Data Quality

> Garantindo que os dados processados sejam confiáveis para consumo operacional e analítico.

## Objetivo

- Compreender o conceito de Qualidade de Dados.
- Entender seu papel no pipeline do Mini BOP.
- Relacionar Data Quality com Governança de Dados.

## O que é Data Quality?

Data Quality representa o conjunto de práticas utilizadas para medir e melhorar a confiabilidade dos dados produzidos por um pipeline.

## Dimensões comuns

- Completude
- Consistência
- Precisão
- Validade
- Unicidade
- Atualidade

## Fluxo Conceitual

```mermaid
graph LR
A[Trades]
--> B[Regras de Qualidade]
--> C[Indicadores]
--> D[Governança]
```

## Exemplos de verificações

- Campos obrigatórios preenchidos.
- Instrumentos válidos.
- Datas coerentes.
- Registros duplicados.

## Benefícios

- Confiança nos dados.
- Apoio à auditoria.
- Base consistente para Analytics.

## Resumo

Após este módulo você compreende o papel da Qualidade de Dados dentro do Mini BOP.

➡ Próximo módulo: **10_AUDIT_LINEAGE.md**
