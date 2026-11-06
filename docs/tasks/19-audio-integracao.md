# Task 19: Integração de áudio no Godot

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Tocar a música nova com crossfade, loops sem emenda, camadas por intensidade e mixagem revisada.

## Contexto

`AudioDirector.play_music` e `MusicData` existem, e os buses também (Master, Music, Effects, Blades, Interface, Ambience). As reações seguem a regra do projeto: áudio lê estado e eventos, nunca muda a simulação. A Web exige interação do usuário antes do primeiro som.

## Entregáveis

- Crossfade entre faixas por tela, pelo roteador sem acoplar telas.
- Camadas por intensidade: vida baixa e clímax, lidas do estado do duelo.
- Música de abertura, menu, seleção por Caminho, vitória, derrota e Arcade final ligadas.
- Mixagem revisada, com níveis por bus anotados em `design/AUDIO.md`.
- Opções de volume conferidas.
- Créditos do jogo com as atribuições exigidas pela task 18.
- Teste de lógica da camada: dado o estado, qual camada toca.

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Sem emenda audível nos loops, na Web e no nativo.
- Trocar de tela em sequência rápida nunca deixa duas músicas tocando.
- Abafar no parry perfeito e no K.O. continua funcionando.
- Duelo inalterado: nenhum arquivo em `simulation/`.

## Arquivos afetados

- `core/audio_director.gd`
- `data/audio/**`
- `presentation/audio/*`
- `screens/**` só para indicar a música
- `default_bus_layout.tres`
- `design/AUDIO.md`

## Dependências

16 e 17. Nenhum serviço externo em tempo de jogo ou de build: o CI usa o áudio já renderizado no repositório.

## Ordem sugerida

Última da trilha de áudio.
