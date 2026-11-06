# Task 20: Revisão de marcas e imagem de carregamento

**Quem executa:** Claude Code; o autor decide

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Conferir, antes de divulgar o repositório, que nada público carrega emblema, logo ou imagem de franquia.

## Contexto

A imagem original de carregamento trazia um emblema de franquia e **nunca foi commitada**; o que está no repositório e nas releases é `assets/boot_splash_clean.png`, editada por script. O repositório no GitHub já é público, então esta revisão vale para o que já foi publicado. Esta não é análise jurídica: o que é uso aceitável segue decisão do autor. O README já declara a inspiração e a falta de afiliação.

## Entregáveis

- Conferência de `boot_splash_clean.png` em tamanho natural e como aparece no jogo e na Web, inclusive `index.png` e ícone.
- Conferência do histórico: `git log --all -- assets/boot_splash1.png` vazio, e busca por binários de imagem removidos.
- Revisão de `MenuEmblem`, ícone, previews e capturas no repositório e nas releases.
- Busca de termos de franquia em código, nomes de assets, textos de tradução e documentos, com tabela do que achou e por que fica ou sai. Exemplo a julgar: a referência a uma trilogia em `ART_DIRECTION.md`, e os arquétipos descritos em `content/CHARACTERS.md`.
- Lista curta de ações para o autor decidir; nada de reescrever histórico sem aprovação.

## Critérios de aceite

- Relatório em `docs/tasks/_revisao-marca.md`, com cada item conferido e o resultado.
- Nenhuma imagem do jogo ou da release com emblema, conferido à mão.
- O disclaimer do README e das notas de release continua presente.
- O autor aprova a lista de ações.

## Arquivos afetados

- `docs/tasks/_revisao-marca.md`
- Só o que o autor aprovar

## Dependências

Nenhuma.

## Ordem sugerida

Curta; fazer logo, antes de qualquer divulgação do repositório.
