# Módulo 08 — Reconciliation

> Comprovando que o pipeline produziu exatamente o resultado esperado.

---

# Objetivo

Ao final deste módulo você deverá compreender:

- o conceito de Reconciliação;
- por que finalizar um processamento não garante sua corretude;
- como evidências operacionais aumentam a confiança nos dados;
- a diferença entre Recovery e Reconciliation.

---

# O que é Reconciliação?

Reconciliação é o processo de comparar os resultados produzidos pelo pipeline com aquilo que era esperado.

Ela responde perguntas como:

- Todos os registros foram processados?
- Algum Trade foi perdido?
- Algum Trade foi duplicado?
- Os eventos esperados foram gerados?

---

# Fluxo Conceitual

```mermaid
graph LR
A[Dados de Origem]
--> B[Pipeline]
--> C[Trades Processados]
--> D[Reconciliação]
--> E[Evidência Operacional]
```

---

# Tipos de Reconciliação

## Quantidade

Compara o número de registros esperados com o número efetivamente processado.

---

## Chave de Negócio

Verifica se cada identificador esperado aparece exatamente uma vez.

---

## Estados do Pipeline

Confirma que todas as etapas produziram estados consistentes.

---

## Eventos

Valida se cada Trade gerou os eventos esperados durante seu ciclo de vida.

---

# Relação com Recovery

Recovery tenta corrigir falhas.

Reconciliation verifica se o resultado final está correto.

Embora trabalhem juntos, possuem responsabilidades diferentes.

---

# Benefícios

- Maior confiança operacional.
- Evidências para auditoria.
- Apoio à investigação de incidentes.
- Garantia adicional antes do consumo analítico.

---

# Evolução para Data Engineering

Os mesmos princípios podem ser encontrados em pipelines distribuídos utilizando metadados operacionais e processos automáticos de validação.

---

# Resumo

Após este módulo você compreende:

- o papel da Reconciliação;
- como ela complementa o Recovery;
- por que evidências operacionais são importantes;
- como esse conceito se aplica ao Mini BOP.

➡ Próximo módulo: **09_DATA_QUALITY.md**
