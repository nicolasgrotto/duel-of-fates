# Task 03: Piloto: Guardião do início ao fim

**Quem executa:** Codex nas imagens; autor na limpeza em Aseprite; Claude Code na integração

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Validar todo o fluxo com um lutador e **medir** o custo antes de comprometer o restante do elenco.

## Contexto

Fluxo: brief, imagem no Codex, pipeline, Godot. Este é o momento de confirmar D1 com dados: as poses-chave (idle, ataque, hit) saem uma por vez e a folha de peças vem delas. Não usar API key. O Guardião tem 33 peças, porque também serve de base à protagonista da História; nesta task, trocar só o conjunto do traje base.

## Entregáveis

- `docs/art-briefs/guardian.md` completo.
- Poses-chave aprovadas e peças ou quadros integrados no jogo, nos três trajes.
- Comparação lado a lado com o Guardião atual em captura.
- `docs/art-briefs/_lessons.md` preenchido: imagens geradas, aprovadas e descartadas por etapa; tempo por etapa, limite do plano encontrado, problemas de consistência entre imagens, ajustes no prompt-base; estimativa revista para o elenco.
- Recomendação final para D1, com os números.
- Linha em `ASSETS.md` com ferramenta, data e licença.

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Pipeline sem erro nos arquivos finais; checklist anti-mixel cumprido em toda peça.
- `test_guard_tracking` passa e as mãos seguem no cabo em todas as sequências do Guardião.
- Três trajes funcionando; luz da lâmina visível no corpo nas três cores.
- Execuções e peças cortadas continuam funcionando.
- Sem emblema, insígnia, logo ou texto, conferido à mão pelo autor.
- O autor aprova o resultado jogando.

## Arquivos afetados

- `docs/art-briefs/guardian.md`, `_lessons.md`
- `art/source/guardian/**`
- `assets/characters/guardian/**`
- `data/characters/guardian/*` só se a arte exigir
- `ASSETS.md`

## Dependências

00, 00b e 01. A 02 ajuda, sem ser obrigatória.

## Ordem sugerida

Depois da 01. **Nenhuma task 04+ começa antes de esta ser aprovada.**
