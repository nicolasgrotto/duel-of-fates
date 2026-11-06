# Task 16: Faixas musicais

**Quem executa:** Claude Code, com as ferramentas da task 18; o autor aprova ouvindo

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Produzir as faixas da ficha, com camadas e loops prontos para o jogo, sem serviço externo.

## Contexto

Sem serviços pagos, Suno ou Udio (D7). Só MIDI + FluidSynth com soundfont de licença livre e síntese em numpy. `MusicData` já tem `base`, `percussion` e `tension`, tocadas em sincronia. Manter esse formato evita código novo. Música nova deve ser OGG: hoje são 16 MB de WAV ao todo.

## Entregáveis

- Abertura, menu, seleção Aurora, seleção Eclipse, 2 a 3 arenas, vitória, derrota, Arcade final.
- Camadas em arquivos de duração idêntica.
- Fonte de cada faixa em `tools/audio/music/`.
- `data/audio/*.tres`.
- Linha em `ASSETS.md` por faixa, com origem, soundfont, licença e atribuição.

## Critérios de aceite

- Loops sem clique, medidos: diferença de amostra na emenda abaixo do limite da task 18.
- Camadas alinhadas ao sample.
- Tamanho do `.pck` medido e dentro do orçamento da task 18.
- Toda faixa regenerável pelo comando da task 18.
- **Faixa sem licença confirmada não entra.**
- O autor aprova ouvindo.

## Arquivos afetados

- `assets/audio/music/**`
- `tools/audio/music/**`
- `data/audio/**`
- `ASSETS.md`

## Dependências

15 e 18.

## Ordem sugerida

Depois da 18.
