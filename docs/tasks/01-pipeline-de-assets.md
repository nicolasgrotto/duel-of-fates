# Task 01: Pipeline de assets

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Levar imagens de `art/source/` até o formato do jogo por script, com relatório de erros, sem etapa manual escondida.

## Contexto

As imagens virão do Codex, em tamanho grande e sem grade. Ver [_style-base.md](../art-briefs/_style-base.md). As peças do rig (D1) têm como destino o par material + normal usado pelo `fighter_material.gdshader`. Retratos, ícones e molduras vão para atlas. O manifesto declara a origem de cada peça, `ai` ou `code`, porque a task 03 compara as duas abordagens. A pasta `art/` não pode entrar no export: acrescentar ao `exclude_filter`.

## Entregáveis

- `tools/art/pipeline/` com etapas separadas: remover chroma `#FF00FF` com tolerância configurável; reduzir para a grade por detecção do bloco, sem reamostragem bilinear; quantizar para a paleta fixa de `_palettes.md`; validar dimensões; gerar atlas e spritesheets.
- Peças do rig: recorte por manifesto (`art/source/<id>/parts.json`, com origem `ai` ou `code` por peça), mapeamento de cor para slot de paleta, normal gerado por bisel da silhueta. Sem luz de recorte nas peças: a etapa acusa cor de recorte que tenha escapado (D4).
- Exportador de referência: renderiza a pose atual de um lutador em PNG em `art/reference/<id>/`, para acompanhar o brief.
- Relatório por execução: erros por arquivo, cores fora da paleta, pixels parcialmente transparentes, resíduo de magenta, tamanho errado, contagem de cores.
- Testes do pipeline com imagens sintéticas em `tools/art/pipeline/tests/`.
- `art/source/` e `art/reference/` em `exclude_filter`; `docs/art-briefs/_style-base.md` revisado.

## Critérios de aceite

- Imagem sintética com fundo magenta, escala 7× e ruído de borda sai idêntica à original em pixels.
- Resíduo de magenta e cor fora da paleta são **erro**, não aviso, e devolvem código de saída diferente de zero.
- A execução é repetível: a mesma entrada gera arquivos byte a byte iguais.
- Um relatório de erro indica arquivo e coordenada.
- A pasta `art/` não aparece no `.pck` exportado.

## Arquivos afetados

- `tools/art/pipeline/**`
- `export_presets.cfg`
- `docs/art-briefs/_style-base.md`
- `.gitignore` se a fonte bruta for grande

## Dependências

00 para a paleta. Pode começar antes, com paleta de teste.

## Ordem sugerida

Depois da 00; pode correr junto da 00b.
