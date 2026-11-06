# Task 00: Guia de estilo e grade 640×360

**Quem executa:** Claude Code, com aprovação do autor

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Transformar a proposta em decisão registrada: grade, paletas por lutador e por Caminho, regras de contorno e luz, tamanhos e checklist anti-mixel.

## Contexto

`ART_DIRECTION.md` é a fonte de verdade visual e hoje registra 2 u/px, 75 px e o descarte de sprites quadro a quadro. Pela hierarquia do `AGENTS.md`, o documento muda antes do código. As decisões D1 a D6 da proposta precisam de resposta do autor.

## Entregáveis

- Decisões D1 a D6 respondidas e registradas.
- `design/ART_DIRECTION.md` atualizado: grade, tamanhos, contorno, luz e checklist anti-mixel. O novo método de arte substitui a proibição de "filtro de pixelização" com a distinção entre converter uma fonte e limpá-la à mão, e o uso de imagem gerada fica registrado.
- `docs/art-briefs/_palettes.md`: paleta fixa por lutador, 12 a 16 cores por slot, para todo o elenco, mais o tema de cada Caminho.
- Linha em `ROADMAP.md`.

## Critérios de aceite

- Cada lutador tem paleta de 12 a 16 cores, com hexadecimais, e passa no teste de contraste: lâmina padrão com contraste maior que qualquer cor do traje.
- Nenhuma paleta usa cor de lâmina própria como cor dominante do traje.
- Contradições com o texto anterior de `ART_DIRECTION.md` removidas, não só acrescentadas.
- Sem alteração em código ou assets.

## Arquivos afetados

- `design/ART_DIRECTION.md`, `design/VFX.md`, `DESIGN.md` se preciso
- `docs/art-briefs/_palettes.md`
- `ROADMAP.md`

## Dependências

Nenhuma.

## Ordem sugerida

Primeira de todas. As tasks de arte dependem dela; a 02 pode ser adiantada.
