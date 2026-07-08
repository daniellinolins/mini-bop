# Módulo 01 — Fundamentos Financeiros

> Antes de compreender o código, precisamos compreender o negócio.

---

# Objetivo

Ao final deste módulo você deverá entender:

- O que é uma operação financeira (*Trade*);
- Por que instituições financeiras utilizam pipelines de processamento;
- Qual problema o Mini BOP procura representar;
- Como os conceitos de negócio aparecem no modelo Oracle.

---

# Pré-requisitos

Nenhum conhecimento prévio de finanças é necessário.

---

# 1. O que é um Trade?

Um **Trade** representa uma operação financeira realizada entre duas partes.

Exemplos:

- Compra de ações;
- Venda de títulos;
- Conversão de moedas;
- Contratos futuros;
- Opções;
- Swaps.

O Mini BOP utiliza o conceito de *Trade* como entidade central do pipeline.

---

# 2. Por que processar Trades?

Em uma plataforma corporativa, uma operação financeira não pode simplesmente ser gravada em uma tabela.

Antes disso normalmente ocorre:

```mermaid
graph LR
A[Recepção]
--> B[Validação]
--> C[Transformação]
--> D[Persistência]
--> E[Auditoria]
--> F[Qualidade]
--> G[Disponibilização]
```

Cada etapa reduz riscos operacionais e melhora a confiabilidade dos dados.

---

# 3. O problema que o Mini BOP resolve

O Mini BOP demonstra como construir um pipeline Oracle capaz de:

- receber dados brutos;
- validar regras de negócio;
- transformar informações;
- armazenar dados curados;
- registrar eventos;
- permitir recuperação;
- medir qualidade;
- manter rastreabilidade.

O foco não é reproduzir um sistema financeiro completo, mas sim demonstrar padrões arquiteturais encontrados em ambientes corporativos.

---

# 4. Como isso aparece no projeto?

Conceitualmente, o pipeline utiliza componentes equivalentes aos seguintes papéis:

| Camada | Responsabilidade |
|--------|------------------|
| Staging | Recepção dos dados |
| Validation | Regras de negócio |
| Transformation | Normalização e enriquecimento |
| Trade Repository | Dados consolidados |
| Audit | Histórico operacional |
| Governance | Qualidade e reconciliação |

Essas responsabilidades são implementadas por tabelas e packages especializadas, estudadas nos próximos módulos.

---

# Decisão de Engenharia

Um dos princípios mais importantes do Mini BOP é separar:

- lógica de negócio;
- processamento operacional;
- governança;
- observabilidade.

Essa separação reduz acoplamento e facilita evolução futura.

---

# O que você aprendeu

Após este módulo você já consegue responder:

- O que é um Trade?
- Por que existe um pipeline?
- Qual é o objetivo do Mini BOP?
- Por que o projeto começa pela camada Oracle?

---

# Próximo módulo

➡ **02_FINANCIAL_INSTRUMENTS.md**
