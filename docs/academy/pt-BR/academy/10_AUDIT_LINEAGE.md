# Módulo 10 — Audit & Lineage

> Garantindo rastreabilidade completa do processamento dos dados.

---

# Objetivo

Ao final deste módulo você deverá compreender:

- o conceito de Auditoria;
- o conceito de Data Lineage;
- por que rastreabilidade é essencial em pipelines corporativos;
- como Auditoria e Lineage complementam Recovery, Reconciliation e Data Quality.

---

# O que é Auditoria?

Auditoria é o conjunto de informações que permite responder perguntas como:

- Quem executou?
- Quando executou?
- O que foi processado?
- Qual foi o resultado?

Esses registros permitem reconstruir a história operacional do pipeline.

---

# O que é Data Lineage?

Data Lineage descreve o caminho percorrido pelos dados.

Ele responde perguntas como:

- De onde veio este dado?
- Quais transformações ele sofreu?
- Em quais tabelas foi utilizado?
- Quais processos dependeram dele?

---

# Fluxo Conceitual

```mermaid
graph LR
A[Sistema Origem]
--> B[Staging]
--> C[Validação]
--> D[Transformação]
--> E[Trade]
--> F[Eventos]
--> G[Auditoria]
```

---

# Benefícios

- Rastreabilidade ponta a ponta.
- Apoio à investigação de incidentes.
- Evidências para auditorias.
- Maior confiança na informação.

---

# Relação com o Mini BOP

No Mini BOP, auditoria e lineage fazem parte da arquitetura de governança.

Esses mecanismos permitem acompanhar o ciclo de vida das informações desde sua entrada até sua disponibilização.

---

# Evolução para Data Engineering

Em plataformas modernas, Data Lineage costuma ser integrado a catálogos de dados e ferramentas de governança.

Independentemente da tecnologia utilizada, o objetivo permanece o mesmo: garantir transparência e rastreabilidade.

---

# Resumo

Após este módulo você compreende:

- a diferença entre Auditoria e Data Lineage;
- a importância da rastreabilidade;
- como esses conceitos fortalecem a governança do Mini BOP.

➡ Próximo módulo: **11_METADATA_ENGINE.md**
