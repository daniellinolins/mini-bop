# SYSTEM_CONTEXT.md

# Mini BOP — System Context

> Visão de alto nível do ecossistema onde o Mini BOP está inserido.

> **Nota**
>
> Este documento descreve o contexto arquitetural de forma conceitual. A implementação efetiva deve sempre ser confirmada no código e na documentação oficial do projeto.

---

# Objetivo

Responder às seguintes perguntas:

- Onde o Mini BOP está posicionado?
- Quais são os principais atores?
- Quais sistemas interagem com o pipeline?
- Como os dados percorrem o ecossistema?

---

# Contexto do Sistema

```text
          Sistemas de Origem
                  │
                  ▼
        +-------------------+
        |     Mini BOP      |
        | Oracle Processing |
        +-------------------+
                  │
                  ▼
        Consumidores Internos
                  │
                  ▼
     Analytics / Big Data (Evolução)
```

---

# Principais Responsabilidades

## Sistemas de Origem

Fornecem os dados que serão processados.

## Mini BOP

Responsável por:

- ingestão;
- validação;
- transformação;
- persistência;
- governança;
- auditoria.

## Consumidores

Consomem os dados já processados para consultas, integração ou análises.

---

# Limites do Sistema

O Mini BOP concentra-se no processamento e governança dos dados.

Ele não substitui os sistemas de origem nem as plataformas analíticas externas.

---

# Relação com outros documentos

| Documento | Objetivo |
|-----------|----------|
| README.md | Visão geral do projeto |
| DOMAIN_MODEL.md | Conceitos de negócio |
| ARCHITECTURE.md | Arquitetura técnica |
| PROJECT_STRUCTURE.md | Organização do repositório |
| Academy | Onboarding técnico |
| ADR | Decisões arquiteturais |

---

# Próximos Diagramas

Este documento servirá de base para futuras representações:

- Context Diagram
- Component Diagram
- Sequence Diagrams
- Deployment Diagram

---

# Resumo

O Mini BOP ocupa a camada de processamento e governança, conectando dados provenientes de sistemas de origem aos consumidores internos e preparando o caminho para integrações futuras com plataformas de Engenharia de Dados.
