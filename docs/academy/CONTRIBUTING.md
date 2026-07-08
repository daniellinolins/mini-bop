# Academy CONTRIBUTING Guide

> Guia para manter a documentação da Mini BOP Academy consistente.

---

# Objetivo

Este documento define o padrão editorial e técnico para todos os capítulos da Academy.

A Academy deve evoluir de forma consistente, independentemente do autor.

---

# Princípios

1. O código-fonte é a principal fonte de verdade.
2. Não invente funcionalidades inexistentes.
3. Diferencie claramente:
   - Implementação atual;
   - Possíveis evoluções (Roadmap);
   - Débito Técnico.
4. Explique primeiro o problema de negócio e depois a solução técnica.

---

# Estrutura obrigatória dos capítulos

Todos os módulos devem seguir, sempre que aplicável:

1. Objetivo
2. Pré-requisitos
3. Contexto de Negócio
4. Conceitos
5. Implementação no Mini BOP
6. Code Review
7. Decisões de Engenharia
8. Boas Práticas
9. Resumo
10. Próximo Módulo

---

# Padrão de escrita

- Utilize linguagem clara e objetiva.
- Prefira exemplos práticos.
- Evite jargões sem explicação.
- Sempre que possível utilize diagramas Mermaid.

---

# Diagramas

Priorize Mermaid para representar:

- Fluxos
- Arquiteturas
- Pipelines
- Dependências
- Ciclo de vida

---

# Idiomas

Cada idioma possui sua própria árvore de documentação:

docs/academy/
├── pt-BR/
├── en-US/
└── fr-FR/

Os três idiomas devem permanecer sincronizados quanto à estrutura.

---

# Referências ao código

Sempre baseie a documentação em:

- código-fonte;
- scripts SQL;
- packages;
- documentação oficial do projeto.

Nunca documente funcionalidades não implementadas como se fossem existentes.

---

# Technical Debt

Melhorias identificadas durante estudos devem ser registradas como Débito Técnico, nunca incorporadas ao texto como comportamento atual.

---

# Roadmap

Novas funcionalidades devem ser registradas no ROADMAP do projeto.

---

# Revisões

Antes de publicar uma alteração:

- validar consistência técnica;
- revisar links internos;
- revisar diagramas;
- revisar navegação;
- revisar sincronização entre idiomas.

---

# Objetivo final

A Academy deve permitir que um novo colaborador compreenda a arquitetura do Mini BOP de forma progressiva e consiga navegar pelo código com segurança.
