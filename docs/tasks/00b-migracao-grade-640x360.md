# Task 00b: Migração do mundo para a grade 640×360

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Colocar o jogo inteiro na grade nova com a arte atual regenerada, antes de qualquer imagem gerada, e testar a câmera nessa grade.

## Contexto

Hoje são 2 u/px; a decisão é 1,5 u/px. Os pintores de `tools/art/` trabalham em unidades, então podem regenerar peças e arenas. Há valores fixos, como `GRID := 2.0` em `blade_view.gd`. Os modos top-down ficam fora (D6). O zoom contínuo e o punch-in ficam (D2), e por isso a ampliação só é inteira no enquadramento neutro: fora dele, `pixel_upscale.gdshader` precisa dar conta.

## Entregáveis

- `units_per_pixel` do duelo em 1,5 e valores fixos substituídos pelo config.
- `fighter_parts.py`, `paint_fighters.py`, `make_arenas.py`, `make_finishers.py` e `paint_blasters.py` parametrizados, e peças e arenas regeneradas.
- `PixelStage` com ampliação inteira no enquadramento neutro em 720p, 1080p e 1440p.
- **Teste de câmera:** ferramenta em `build/` que percorre zoom contínuo e punch-in, com um padrão de teste e com um duelo real, em 720p e 1080p, no nativo e no Chrome. Medir a largura em tela de cada pixel da grade (histograma) e o shimmer, comparando quadros seguidos com o conteúdo parado e a câmera em movimento lento.
- **Relatório em `docs/tasks/_camera-640x360.md`:** números, capturas e recomendação. Se houver shimmer ou largura desigual visível, propor e testar duas alternativas: degraus inteiros de zoom, ou transição curta entre degraus. O autor decide olhando as capturas.
- Folha de capturas antes e depois em `build/`: todas as arenas e seis lutadores.

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- No enquadramento neutro, a grade mede 640×360 em 1280×720 e 1920×1080, com ampliação de 2× e 3×.
- No neutro, todo pixel da grade tem a mesma largura em tela.
- Durante o zoom, nenhum pixel difere da largura média em mais de 1 pixel de tela, ou o relatório justifica a alternativa adotada.
- O punch-in continua perceptível em golpe forte, parry perfeito e K.O.
- Lutador com 100 px ± 4 px de altura em pé.
- `test_guard_tracking` passa: a guarda desenhada continua no ponto do bloqueio real.
- Infiltração, Incursão e naves sem mudança visual.

## Arquivos afetados

- `data/balance/effects_config.*`
- `presentation/camera/pixel_stage.gd`, `camera_rig.gd`, `pixel_upscale.gdshader`
- `presentation/fighters/blade_view.gd` e demais com grade fixa
- `tools/art/*.py`
- `assets/characters/**`, `arenas/**`
- `docs/tasks/_camera-640x360.md`
- `ASSETS.md` se a origem mudar

## Dependências

00.

## Ordem sugerida

Logo após a 00, antes do piloto. Precisa terminar antes das tasks 20 a 22 do Codex.
