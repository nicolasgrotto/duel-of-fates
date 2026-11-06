# Task 13: Seleção de lutador

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Painel com moldura, retrato animado, ícones de poder, barras segmentadas com brilho e tema por Caminho.

## Contexto

`character_select.gd` tem 470 linhas, com passos de jogador, oponente, poderes, técnicas, traje e arena. Nada disso pode se perder. Os ícones atuais têm 24×24, e o pedido é 16×16: reduzir exige redesenho, não escala, e o `AbilityBar` das Operações os usa em 84 px. Sem moral: o tema Aurora ou Eclipse é só de interface.

## Entregáveis

- Painel com moldura e tema por Caminho, por tokens de `UiPalette`.
- Retrato animado, com a task 10 como base.
- Ícones de poder 16×16 redesenhados por `make_power_icons.py`, mantendo os de 24×24 onde já são usados, ou migração decidida.
- Barras de atributo segmentadas com brilho em `AttributeBars`.
- `design/UI_UX.md` atualizado.

## Critérios de aceite

- Corresponde ao mockup aprovado.
- Todos os passos atuais continuam funcionando com teclado, controle e mouse, em 1 e 2 jogadores.
- Lutadores bloqueados e cores por desafio continuam certos.
- Sem texto cortado nos dois idiomas em 720p.
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Testes sem falha.

## Arquivos afetados

- `screens/select/**`
- `ui/widgets/attribute_bars.gd`
- `tools/art/make_power_icons.py`, `assets/ui/powers/**`
- `ui/ui_palette.gd`, `ui/theme/main_theme.tres`
- `design/UI_UX.md`, `ASSETS.md`

## Dependências

10 e 11.

## Ordem sugerida

Depois dos retratos.
