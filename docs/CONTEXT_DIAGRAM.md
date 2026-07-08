# CONTEXT_DIAGRAM.md

# Mini BOP — Context Diagram

> Diagrama de contexto do sistema.

> **Importante**
>
> Este documento apresenta uma visão conceitual. As integrações efetivamente implementadas devem ser confirmadas no código-fonte e na documentação oficial do projeto.

---

# Objetivo

Representar visualmente o posicionamento do Mini BOP dentro do ecossistema.

---

# Context Diagram

```mermaid
flowchart LR

    A[Sistemas de Origem]
    B[Mini BOP]
    C[Consumidores]
    D[Plataformas Analíticas\n(Evolução Conceitual)]

    A -->|Dados de Entrada| B
    B -->|Dados Processados| C
    C -.->|Integração futura| D
```

---

# Atores

## Sistemas de Origem

Produzem os dados que serão processados pelo Mini BOP.

## Mini BOP

Responsável pelo pipeline de processamento, governança e persistência.

## Consumidores

Aplicações e processos que utilizam os dados já processados.

## Plataformas Analíticas

Representam uma possível evolução para ambientes de Data Engineering e Analytics. Não devem ser interpretadas como funcionalidades implementadas, salvo confirmação no código.

---

# Limites do Sistema

O Mini BOP atua como núcleo de processamento.

Não substitui:

- sistemas de origem;
- ferramentas analíticas;
- mecanismos externos de visualização.

---

# Relação com a documentação

| Documento | Complementa |
|-----------|-------------|
| README.md | Visão geral |
| SYSTEM_CONTEXT.md | Contexto textual |
| DOMAIN_MODEL.md | Conceitos de negócio |
| ARCHITECTURE.md | Arquitetura técnica |
| Academy | Formação progressiva |

---

# Próximo nível de detalhamento

Após compreender este diagrama recomenda-se consultar:

1. COMPONENT_DIAGRAM.md
2. SEQUENCE_DIAGRAMS.md
3. ARCHITECTURE.md
4. Academy

---

# Resumo

Este diagrama fornece uma visão executiva do posicionamento do Mini BOP e serve como ponto de partida para compreender as demais representações arquiteturais.
