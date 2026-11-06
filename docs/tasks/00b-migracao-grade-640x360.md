# Task 00b: Migração do mundo para a grade 640×360

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Colocar o jogo inteiro na grade nova com a arte atual regenerada, antes de qualquer imagem gerada.

## Contexto

Hoje são 2 u/px. A proposta é 1,5 u/px. Os pintores de `tools/art/` trabalham em unidades, então podem regenerar peças e arenas na escala nova. Há valores fixos, como `GRID := 2.0` em `blade_view.gd`. Os modos top-down ficam fora (D6).

## Entregáveis

- `units_per_pixel` do duelo em 1,5 e valores fixos substituídos pelo config.
- `fighter_parts.py`, `paint_fighters.py`, `make_arenas.py`, `make_finishers.py` e `paint_blasters.py` parametrizados e peças e arenas regeneradas.
- `PixelStage` com ampliação inteira no enquadramento neutro em 720p, 1080p e 1440p.
- Folha de capturas antes e depois em `build/` (todas as arenas, seis lutadores).

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- No enquadramento neutro, a grade mede 640×360 em 1280×720 e 1920×1080, com ampliação de 2× e 3×.
- Lutador com 100 px ± 4 px de altura em pé.
- `test_guard_tracking` passa: a guarda desenhada continua no ponto do bloqueio real.
- Infiltração, Incursão e naves sem mudança visual.

## Arquivos afetados

- `data/balance/effects_config.*`
- `presentation/camera/pixel_stage.gd`
- `presentation/fighters/blade_view.gd` e demais com grade fixa
- `tools/art/*.py`
- `assets/characters/**`, `arenas/**`
- `ASSETS.md` se a origem mudar

## Dependências

00.

## Ordem sugerida

Logo após a 00, antes do piloto.
