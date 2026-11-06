# Task 11: Briefing de mockups no Claude Design

**Quem executa:** Claude Code escreve; autor gera e aprova no Claude Design

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Definir o que cada mockup precisa mostrar **antes** de implementar interface.

## Contexto

A família tática da 1.1 foi aprovada pelo autor: novas telas devem estender esse tema, não criar outro. Mínimo: 1280×720 com texto de 18 px, teclado e controle. Sem marca nem termo de franquia.

## Entregáveis

- `docs/art-briefs/_design-mockups.md` com um item por tela: menu principal, seleção de lutador, HUD do duelo, pausa, opções.
- Para cada tela: propósito, conteúdo obrigatório, estados (foco, seleção, bloqueado), textos reais em português e inglês, resoluções, e o que reaproveita de `ui/widgets/`.
- Dados reais a usar, como o lutador com os nomes mais longos e 3 poderes.

## Critérios de aceite

- Cada tela lista todo dado que aparece hoje nela, sem perder função: conferir com `character_select.gd` e `main_menu.gd`.
- Critérios de aprovação claros para o autor.
- Nenhuma mudança em código.

## Arquivos afetados

- `docs/art-briefs/_design-mockups.md`

## Dependências

00.

## Ordem sugerida

Antes das tasks 12, 13 e 14.
