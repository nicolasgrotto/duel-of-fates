# Task 12: Menu principal

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Trocar a coluna de texto sobre preto por um menu vivo, conforme o mockup aprovado.

## Contexto

`main_menu.gd` já tem grupos de navegação e `MenuEmblem` com lâminas cruzadas. A navegação e o roteador de cenas não mudam. O fundo estrelado pode vir de `SpaceBackdrop` e da técnica de `SectorMap`, ou de fundo gerado.

## Entregáveis

- Fundo em parallax de estrelas e nebulosa, em camadas.
- Partículas discretas; pulso de luz no cruzamento das lâminas.
- Cursor em forma de lâmina no `MenuList` deste menu.
- Transições entre grupos.
- `design/UI_UX.md` atualizado.

## Critérios de aceite

- Corresponde ao mockup aprovado.
- Navegação por teclado, controle e mouse idêntica à atual.
- `reduced_effects` reduz partículas e parallax.
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Testes sem falha.

## Arquivos afetados

- `screens/menu/**`
- `ui/widgets/menu_list.gd` ou widget novo
- `ui/theme/main_theme.tres`, `ui/ui_palette.gd`
- `assets/ui/menu/**`, `ASSETS.md`
- `design/UI_UX.md`

## Dependências

11 aprovada. 02 para aproveitar a lâmina nova.

## Ordem sugerida

Depois da 11.
