# Task 16: Faixas musicais

**Quem executa:** Conforme o método escolhido na task 18

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Produzir as faixas da ficha, com camadas e loops prontos para o jogo.

## Contexto

`MusicData` já tem `base`, `percussion` e `tension`, tocadas em sincronia. Manter esse formato evita código novo. A build Web pesa pouco hoje (16 MB de WAV ao todo): música nova deve ser OGG.

## Entregáveis

- Abertura, menu, seleção Aurora, seleção Eclipse, 2 a 3 arenas, vitória, derrota, Arcade final.
- Camadas em arquivos de duração idêntica.
- `data/audio/*.tres`.
- Linhas em `ASSETS.md`, com ferramenta, plano e licença de cada faixa.

## Critérios de aceite

- Loops sem clique, medidos: diferença de amostra na emenda abaixo do limite definido na task 18.
- Camadas alinhadas ao sample.
- Tamanho total do `.pck` medido e dentro do orçamento da task 18.
- Nenhuma faixa com licença incerta; se não for possível confirmar, a faixa não entra.
- O autor aprova ouvindo.

## Arquivos afetados

- `assets/audio/music/**`
- `data/audio/**`
- `ASSETS.md`

## Dependências

15 e 18.

## Ordem sugerida

Depois da 18.
