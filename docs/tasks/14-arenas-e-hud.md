# Task 14: Arenas e HUD

**Quem executa:** Claude Code; Codex nos fundos, se o brief pedir

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Mais contraste, camadas de névoa e luz, reflexo no chão, e HUD com a moldura dos menus.

## Contexto

Doze arenas, com pintura por `make_arenas.py`. Reflexo já existe em algumas (`fighter_reflection.gd`, reflexo de lâmina). Regra que continua: nenhuma luz de cena mais forte que a lâmina. O HUD do duelo tem regras próprias em `design/UI_UX.md`.

## Entregáveis

- Uma arena-piloto refeita (sugestão: Santuário Alagado, por causa da água), medida e aprovada, antes das outras onze.
- Camadas de névoa e luz por dados da arena.
- Reflexo no chão onde couber.
- HUD do duelo com a moldura dos menus, conforme mockup.
- Briefs de fundo em `docs/art-briefs/arenas/` se forem gerados.
- `content/ARENAS.md` e `design/UI_UX.md` atualizados.

## Critérios de aceite

- Contraste: lutador e lâmina legíveis contra o fundo em captura, nas 12 arenas e nos 16 lutadores por amostragem.
- Sem gameplay alterado: chão, paredes e obstáculos idênticos (`git diff` de colisão vazio).
- HUD inteiro em 720p e 1080p; barra de vida e Vigor legíveis.
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).

## Arquivos afetados

- `arenas/**`, `data/arenas/*`
- `tools/art/make_arenas.py`
- `presentation/hud/*`, `screens/duel/*`
- `content/ARENAS.md`, `design/UI_UX.md`, `ASSETS.md`

## Dependências

00b e 11.

## Ordem sugerida

Depois dos menus, ou em paralelo ao elenco.
