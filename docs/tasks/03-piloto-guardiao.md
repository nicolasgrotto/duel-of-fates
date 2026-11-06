# Task 03: Piloto: Guardião, duas abordagens

**Quem executa:** Codex nas imagens; limpeza em Aseprite; Claude Code na integração e nas peças por código

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Validar o fluxo com um lutador e escolher, com números e capturas, como fazer as peças do restante do elenco.

## Contexto

O rig fica (D1). O que se compara é a origem das peças, as duas a partir dos frames-chave idle, ataque e hit, gerados um por vez.

- **(a) Tudo por IA:** todas as peças saem da imagem gerada.
- **(b) Híbrido:** IA só nas peças de identidade (cabeça, torso, capa e punho); as demais por código, nos pintores de `tools/art/`.

No jogo, o punho é desenhado por `hilt_view.gd`: a abordagem que usar punho gerado precisa de uma peça para ele. O Guardião tem 33 peças porque também é base da protagonista; aqui troca-se o conjunto do traje base. Sem API key. Sem recorte pintado nas peças (D4).

## Entregáveis

- `docs/art-briefs/guardian.md` completo.
- Frames-chave aprovados, e as duas versões integradas em ramos de dados separáveis, para alternar em captura. Nada de branch de git.
- **Tabela em `docs/art-briefs/_lessons.md`, por abordagem:** imagens consumidas (geradas, aprovadas, descartadas), tempo de limpeza no Aseprite, tempo de integração, limite do plano atingido, problemas de consistência entre peças.
- **Folha de capturas lado a lado** (atual, a, b): em pé, guarda, ataque, hit, os três trajes e as três cores de lâmina, em 720p, além de silhueta em preto.
- Recomendação, com estimativa de custo para o restante do elenco. **O autor decide** antes de qualquer task 04+.
- A versão vencedora fica no jogo; a outra sai do repositório, ficando só as capturas no relatório.
- Linha em `ASSETS.md` com ferramenta, data e licença.

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Pipeline sem erro nos arquivos finais; checklist anti-mixel cumprido em toda peça.
- `test_guard_tracking` passa, e as mãos seguem no cabo em todas as sequências do Guardião.
- Três trajes funcionando; luz da lâmina visível no corpo nas três cores, sem recorte pintado.
- Execuções e peças cortadas continuam funcionando.
- Sem emblema, insígnia, logo ou texto, conferido à mão.
- Números reais na tabela, sem campo estimado.
- O autor aprova o resultado jogando.

## Arquivos afetados

- `docs/art-briefs/guardian.md`, `_lessons.md`
- `art/source/guardian/**`
- `assets/characters/guardian/**`
- `tools/art/*.py` para a parte por código
- `presentation/fighters/hilt_view.gd` se o punho virar peça
- `data/characters/guardian/*` só se a arte exigir
- `ASSETS.md`

## Dependências

00, 00b e 01. A 02 ajuda, sem ser obrigatória.

## Ordem sugerida

Depois da 01. **Nenhuma task 04+ começa antes da decisão do autor.** Precisa terminar antes das tasks 20 a 22 do Codex.
