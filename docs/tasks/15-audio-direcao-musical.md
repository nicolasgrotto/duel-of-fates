# Task 15: Direção musical

**Quem executa:** Claude Code, com aprovação do autor

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Definir clima, instrumentação e tom por faixa, antes de produzir qualquer música.

## Contexto

Decisão do autor: **synth sombrio, pads, baixos, coro sintético e percussão, com orquestral só como textura.** Sem serviços pagos, Suno ou Udio (D7). Só MIDI + FluidSynth com soundfont de licença livre e síntese em numpy. Regra do projeto: composição original. Referências são só de **clima**, em palavras, nunca nome de obra, compositor ou franquia.

## Entregáveis

- `design/AUDIO.md` com a direção: paleta instrumental, faixa de BPM, tonalidades, motivo melódico original e como ele varia entre Aurora e Eclipse.
- `docs/art-briefs/audio/_direction.md` com uma ficha por faixa: abertura, menu, seleção (Aurora e Eclipse), 2 a 3 arenas, vitória, derrota, Arcade final.
- Em cada ficha, o que vem de numpy (pads, baixos, coro, percussão) e o que vem do soundfont (textura orquestral).
- Camadas por intensidade: normal, vida baixa, clímax.

## Critérios de aceite

- Cada ficha tem clima, BPM, tom, duração, ponto de loop, camadas, bus e origem de cada instrumento.
- Orquestral aparece só como textura, nunca como condutor.
- Sem nome de obra, compositor ou franquia.
- Aprovado pelo autor.

## Arquivos afetados

- `design/AUDIO.md`
- `docs/art-briefs/audio/_direction.md`

## Dependências

Nenhuma.

## Ordem sugerida

Início da trilha de áudio, independente da arte.
