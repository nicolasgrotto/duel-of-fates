# Task 05: Sprites: Espelho, Haste e Brasa

**Quem executa:** Codex nas imagens; autor na limpeza em Aseprite; Claude Code na integração

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Aplicar o fluxo validado no piloto a Espelho, Haste e Brasa.

## Contexto

O Espelho é o único traje claro do elenco. A Haste usa lâmina em haste. A Brasa tem lâminas longa e curta em mãos separadas. Regra de lotes: **um frame-chave por vez, nunca folha completa de uma vez.** Ordem de referência: idle, ataque, hit; depois, só se a abordagem pedir, bloqueio, andar, habilidade e poderes. Tamanho de lote conforme medido em `_lessons.md`; trabalhar um lutador por sessão se o plano limitar. As peças seguem a abordagem escolhida na task 03. Sem recorte pintado nas peças (D4). Trajes de risco conforme a proposta: por código ou com formas genéricas (D8).

## Entregáveis

- Briefs completos: [mirror.md](../art-briefs/mirror.md), [lance.md](../art-briefs/lance.md), [ember.md](../art-briefs/ember.md), cada um com silhueta distinta, paleta, roupa e punho da lâmina, e referência do sprite atual.
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

- `docs/art-briefs/mirror.md`, `art/source/mirror/**`, `assets/characters/mirror/**`
- `docs/art-briefs/lance.md`, `art/source/lance/**`, `assets/characters/lance/**`
- `docs/art-briefs/ember.md`, `art/source/ember/**`, `assets/characters/ember/**`
- `ASSETS.md`

## Dependências

03 aprovada.

## Ordem sugerida

Em qualquer ordem depois do piloto. Sugestão: esta numeração, deixando secretos e chefe por último.
