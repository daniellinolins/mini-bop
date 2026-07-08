# Módulo 07 — Recovery

> Garantindo que falhas operacionais possam ser tratadas com segurança.

---

# Objetivo

Neste módulo você aprenderá:

- o conceito de Recovery;
- por que pipelines corporativos precisam ser resilientes;
- como o reprocessamento se integra ao pipeline;
- a diferença entre recuperação e processamento normal.

---

# O problema

Falhas acontecem.

Uma indisponibilidade de infraestrutura, uma inconsistência de dados ou uma interrupção inesperada não podem impedir a continuidade da operação.

Por isso o pipeline deve ser capaz de retomar o processamento de forma controlada.

---

# Fluxo de Recovery

```mermaid
graph LR
A[Batch]
--> B[Falha]
--> C[Recovery]
--> D[Reprocessamento]
--> E[Pipeline Normal]
```

---

# Princípios

- Não duplicar dados.
- Preservar auditoria.
- Reutilizar o pipeline existente.
- Manter o processamento idempotente.

---

# Recovery x Replay

## Recovery

Reprocessa apenas o necessário.

## Replay

Executa novamente todo o processamento quando a integridade global não pode ser garantida.

---

# Benefícios

- Maior disponibilidade.
- Menor impacto operacional.
- Facilidade de investigação.
- Continuidade do negócio.

---

# Relação com o Mini BOP

No Mini BOP, Recovery é tratado como uma responsabilidade independente da lógica de negócio.

Essa separação reduz acoplamento e facilita futuras evoluções.

---

# Evolução para Data Engineering

Em plataformas modernas, responsabilidades equivalentes podem ser implementadas utilizando mecanismos de retry, reexecução e políticas de recuperação em ferramentas de orquestração.

---

# Resumo

Após este módulo você compreende:

- por que Recovery existe;
- diferença entre Recovery e Replay;
- importância da idempotência;
- benefícios da separação entre processamento e recuperação.

➡ Próximo módulo: **08_RECONCILIATION.md**
