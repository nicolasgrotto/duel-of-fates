# Task 08: Sprites: Soberano, Ancião e Predestinado

**Quem executa:** Codex nas imagens; autor na limpeza em Aseprite; Claude Code na integração

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Aplicar o fluxo validado no piloto a Soberano, Ancião e Predestinado.

## Contexto

Secretos. O Predestinado tem variante Eclipse com peças próprias (`foretold_eclipse`). Regra de lotes: **um frame-chave por vez, nunca folha completa de uma vez.** Ordem: idle, ataque, hit; depois bloqueio, andar, habilidade e poderes. Tamanho de lote conforme medido em `_lessons.md`; trabalhar um lutador por sessão se o plano limitar. Formato final conforme D1.

## Entregáveis

- Briefs completos: [sovereign.md](../art-briefs/sovereign.md), [elder.md](../art-briefs/elder.md), [foretold.md](../art-briefs/foretold.md), cada um com silhueta distinta, paleta, roupa e punho da lâmina, e referência do sprite atual.
- Poses-chave aprovadas e arte integrada, em todos os trajes.
- Folha de capturas: pose, trajes e silhueta em preto.
- Lições novas em `_lessons.md`.
- Linhas em `ASSETS.md`.

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Pipeline sem erro; checklist anti-mixel cumprido.
- Teste da silhueta: os três se distinguem em preto entre si e do Guardião.
- Luz da lâmina funcionando nas três cores; execuções e peças cortadas funcionando.
- Sem emblema, logo, insígnia ou texto, conferido à mão.
- O autor aprova jogando.

## Arquivos afetados

- `docs/art-briefs/sovereign.md`, `art/source/sovereign/**`, `assets/characters/sovereign/**`
- `docs/art-briefs/elder.md`, `art/source/elder/**`, `assets/characters/elder/**`
- `docs/art-briefs/foretold.md`, `art/source/foretold/**`, `assets/characters/foretold/**`
- `ASSETS.md`

## Dependências

03 aprovada.

## Ordem sugerida

Em qualquer ordem depois do piloto. Sugestão: esta numeração, deixando secretos e chefe por último.
