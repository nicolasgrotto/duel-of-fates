# Task 09: Sprites: Sombra Desperta, Coldre e protagonista

**Quem executa:** Codex nas imagens; autor na limpeza em Aseprite; Claude Code na integração

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Aplicar o fluxo validado no piloto a Sombra Desperta, Coldre e protagonista.

## Contexto

Chefe e História. Coldre e protagonista reutilizam o rig do Guardião e as variantes de rosto e cabelo escolhidas pelo jogador: conferir todas as combinações. Regra de lotes: **um frame-chave por vez, nunca folha completa de uma vez.** Ordem: idle, ataque, hit; depois bloqueio, andar, habilidade e poderes. Tamanho de lote conforme medido em `_lessons.md`; trabalhar um lutador por sessão se o plano limitar. Formato final conforme D1.

## Entregáveis

- Briefs completos: [awakened_shadow.md](../art-briefs/awakened_shadow.md), [holster.md](../art-briefs/holster.md), [protagonist.md](../art-briefs/protagonist.md), cada um com silhueta distinta, paleta, roupa e punho da lâmina, e referência do sprite atual.
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

- `docs/art-briefs/awakened_shadow.md`, `art/source/awakened_shadow/**`, `assets/characters/awakened_shadow/**`
- `docs/art-briefs/holster.md`, `art/source/holster/**`, `assets/characters/holster/**`
- `docs/art-briefs/protagonist.md`, `art/source/protagonist/**`, `assets/characters/protagonist/**`
- `ASSETS.md`

## Dependências

03 aprovada.

## Ordem sugerida

Em qualquer ordem depois do piloto. Sugestão: esta numeração, deixando secretos e chefe por último.
