# Task 07: Sprites: Eco, Corsária e Lince

**Quem executa:** Codex nas imagens; autor na limpeza em Aseprite; Claude Code na integração

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Aplicar o fluxo validado no piloto a Eco, Corsária e Lince.

## Contexto

A Corsária e o Lince carregam armas de disparo desenhadas pelo jogo. Manter mão livre e coldre nas posições usadas pelas poses. Regra de lotes: **um frame-chave por vez, nunca folha completa de uma vez.** Ordem: idle, ataque, hit; depois bloqueio, andar, habilidade e poderes. Tamanho de lote conforme medido em `_lessons.md`; trabalhar um lutador por sessão se o plano limitar. Formato final conforme D1.

## Entregáveis

- Briefs completos: [echo.md](../art-briefs/echo.md), [corsair.md](../art-briefs/corsair.md), [lynx.md](../art-briefs/lynx.md), cada um com silhueta distinta, paleta, roupa e punho da lâmina, e referência do sprite atual.
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

- `docs/art-briefs/echo.md`, `art/source/echo/**`, `assets/characters/echo/**`
- `docs/art-briefs/corsair.md`, `art/source/corsair/**`, `assets/characters/corsair/**`
- `docs/art-briefs/lynx.md`, `art/source/lynx/**`, `assets/characters/lynx/**`
- `ASSETS.md`

## Dependências

03 aprovada.

## Ordem sugerida

Em qualquer ordem depois do piloto. Sugestão: esta numeração, deixando secretos e chefe por último.
