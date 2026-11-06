# Task 18: Produção musical com MIDI, FluidSynth e numpy

**Quem executa:** Claude Code; o autor ouve e aprova

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Montar a produção musical própria e repetível, e fixar o formato de entrega.

## Contexto

Sem serviços pagos, Suno ou Udio (D7). Só MIDI + FluidSynth com soundfont de licença livre e síntese em numpy. `tools/audio/synth_audio.py` já sintetiza todos os sons em numpy, com semente. FluidSynth não está instalado nesta máquina: é ferramenta de render, offline, e não vai no jogo. O soundfont também não vai: só o áudio renderizado. **Faixa sem licença confirmada não entra.** Candidatos a soundfont para checar: FluidR3_GM, MuseScore_General, GeneralUser GS e conversões de VSCO 2 CE. A lista é ponto de partida: a licença de cada arquivo precisa ser lida na fonte, porque varia por versão. Sonatina e bibliotecas com cláusula não comercial ou de amostragem ficam de fora.

## Entregáveis

- `tools/audio/music/`: composição em dados ou MIDI, render por FluidSynth, camadas em numpy, mixagem e exportação, tudo por um comando.
- `docs/art-briefs/audio/_production.md`: instalação, versão das ferramentas e licenças.
- Tabela de licenças: para cada soundfont ou amostra, link da fonte, texto da licença, data da consulta, atribuição exigida e SHA-256 do arquivo.
- Atribuições exigidas incluídas em `ASSETS.md` e nos créditos do jogo.
- Teste de 30 s de uma ficha, para o autor ouvir antes de produzir o restante.
- Formato de entrega: mestre em WAV 44,1 kHz 16 bits, jogo em OGG Vorbis; pontos de loop; camadas de duração igual; limite de clique na emenda.
- Orçamento de tamanho na Web.

## Critérios de aceite

- Licença livre (CC0 ou permissiva) confirmada, com link e data, para tudo que for usado. Sem confirmação, o material sai.
- Nenhum serviço pago ou externo em qualquer etapa; o render funciona sem rede.
- O mesmo comando, com a mesma entrada, gera áudio idêntico, com checagem por hash.
- O soundfont não entra no repositório nem no `.pck`, salvo se a licença permitir e o tamanho justificar.
- O autor aprova o teste de 30 s.

## Arquivos afetados

- `tools/audio/music/**`
- `docs/art-briefs/audio/_production.md`
- `design/AUDIO.md`
- `ASSETS.md`

## Dependências

15.

## Ordem sugerida

Antes da 16.
