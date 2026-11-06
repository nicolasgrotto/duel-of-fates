# Task 18: Produção musical: método e entrega

**Quem executa:** Claude Code avalia; autor decide serviços pagos

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Escolher como gerar a música, com teste real, e fixar o formato de entrega.

## Contexto

Três caminhos: MIDI + FluidSynth com soundfont orquestral, síntese procedural em numpy (o projeto já usa em `synth_audio.py`) e geração externa (Suno, Udio). **Licença é o risco:** `AGENTS.md` não aceita asset sem licença conhecida e compatível, e os termos desses serviços variam por plano e mudam; é preciso confirmar no momento do uso. O soundfont também precisa de licença compatível.

## Entregáveis

- Teste de 30 s da mesma ficha nos caminhos viáveis, com comparação de qualidade, controle, custo e licença.
- Recomendação registrada em `design/AUDIO.md`.
- Especificação do que for gerado fora: prompt sem nome de artista ou obra, BPM, tom, duração, stems.
- Formato de entrega: mestre em WAV 44,1 kHz 16 bits, jogo em OGG Vorbis; loops com pontos de início e fim; camadas de duração igual; limite de clique na emenda.
- Orçamento de tamanho na Web.

## Critérios de aceite

- Licença de cada ferramenta e soundfont documentada com link e data.
- O autor ouve os testes e escolhe.
- Script, se houver, repetível e em `tools/audio/`.

## Arquivos afetados

- `design/AUDIO.md`
- `docs/art-briefs/audio/_production.md`
- `tools/audio/**` se preciso

## Dependências

15.

## Ordem sugerida

Antes da 16.
