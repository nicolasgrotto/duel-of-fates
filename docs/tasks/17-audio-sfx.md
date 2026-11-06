# Task 17: Biblioteca de SFX

**Quem executa:** Claude Code, por `synth_audio.py`, onde bastar

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Elevar ignição, zumbido, golpe, choque, bloqueio, cada poder e interface ao nível da nova direção.

## Contexto

Já existem 104 sons sintetizados e semente local, e `SOUNDS` por evento. A meta é qualidade, não nomes novos: quem reage aos eventos continua igual. Zumbido por lutador vem de `WeaponData.hum_pitch` e `hum_detune`.

## Entregáveis

- Sons refeitos para ignição, zumbido, swing leve e forte, choque, bloqueio, parry, os 21 poderes, UI.
- Timbre próprio por lutador mantido.
- `design/AUDIO.md` atualizado.
- Linhas em `ASSETS.md`.

## Critérios de aceite

- Mesmos nomes de som, ou migração completa em `sound_bank.tres`.
- Geração repetível por script, com semente.
- Sem clipagem: pico abaixo de −1 dBFS.
- Choque continua o som mais forte dos contatos, e o parry perfeito continua abafando o mundo.
- Testes sem falha.

## Arquivos afetados

- `tools/audio/synth_audio.py`
- `assets/audio/sfx/**`, `assets/audio/powers/**`
- `data/audio/sound_bank.tres`
- `design/AUDIO.md`, `ASSETS.md`

## Dependências

15.

## Ordem sugerida

Em paralelo às faixas.
