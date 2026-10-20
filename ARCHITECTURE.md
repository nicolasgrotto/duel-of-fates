# ARCHITECTURE — Projeto Godot

Como o projeto é organizado. Segue [GAME_DESIGN.md](GAME_DESIGN.md). Decisões ainda abertas estão marcadas como **Decisão** e entram no [ROADMAP.md](ROADMAP.md).

## Stack

- **Godot 4.7**, **GDScript** com tipagem estática.
- Renderer: **Compatibility** (`gl_compatibility`), janela com `stretch_mode = canvas_items` e `aspect = expand`. Combina com a técnica de arte escolhida, 2D com esqueleto (ver [design/ART_DIRECTION.md](design/ART_DIRECTION.md#técnica-de-apresentação)).
- Resolução base: **1920×1080**, escalável; a interface é ancorada nas bordas para telas mais largas.
- Plataforma principal: Windows. Linux e Web depois, se o renderer permitir.
- Addons, GDExtensions e C# só com autorização do autor.

### Addons autorizados

| Addon | Uso | Observação |
| --- | --- | --- |
| Godot MCP Toolkit (`addons/godot_mcp_toolkit`, MIT) | ponte MCP para agentes (Claude Code, Codex) controlarem o editor | só ferramenta de desenvolvimento: registra o autoload `MCPRuntimeServer`, que se desliga fora do editor. Nos presets de exportação, excluir `res://addons/godot_mcp_toolkit/*` ou usar Script Export Mode **Text**, para nenhum script do addon ir para o build. Configuração do servidor em `.mcp.json`. O jogo nunca depende dele. |

## Visão geral

O jogo tem duas metades que nunca se misturam:

```
                ┌──────────────── Simulação (lógica pura) ────────────────┐
 Controladores  │                                                          │
 (jogador, IA,  │  MatchSimulation.step(intents)  ── 60 Hz, determinística │
 boneco, replay)│     FighterState ×2, projéteis, arena, regras, RNG       │
   ── intents ─▶│     → CombatEvent[] do tick                              │
                └───────────────┬──────────────────────────────────────────┘
                                │ estado (somente leitura) + eventos
                ┌───────────────▼──────── Apresentação (nós da Godot) ─────┐
                │  FighterView (animação), BladeView, EffectsDirector,     │
                │  CameraRig, AudioDirector, Hud, StatsTracker, objetivos  │
                └──────────────────────────────────────────────────────────┘
```

**Por que uma simulação própria, separada dos nós:**

- **Determinismo**: mesmo estado + mesmas intenções = mesmo resultado. Isso dá o replay do golpe final por re-simulação, testes reproduzíveis, simulações IA × IA para balanceamento e deixa o caminho aberto para rollback online no futuro.
- **Justiça da IA**: ela lê o mesmo estado que o jogador vê.
- **Testes sem tela**: a simulação roda headless.
- Colisões de combate (hitbox, hurtbox, lâmina, corpo, paredes) são retângulos e segmentos calculados na simulação, não o motor de física. O motor de física fica livre para a apresentação (pedaços de finalização, detritos), sem afetar resultados.

## Pastas

```
res://
  core/           autoloads e serviços (configurações, save, roteador de cenas, áudio, localização)
  simulation/     lógica do duelo, sem nós (RefCounted)
    combat/       ataques, defesa, choque, disputa, consequências, finalizações
    powers/       poderes, técnicas, projéteis, interação por Fluxo
    rules/        regras por modo (capacidades ligadas)
  controllers/    intent, jogador, IA, boneco, replay
    ai/
  data/           scripts de Resource e as instâncias .tres
    characters/   um CharacterData por personagem (+ golpes, aparência, IA)
    powers/       um PowerData por poder e técnica
    arenas/       ArenaData (referência à cena da arena, música, frase)
    story/        encontros, finais, recompensas
    balance/      configs globais (combate, Vigor, Fluxo, IA, efeitos, modos)
  presentation/   cenas e scripts de visualização do duelo
    fighters/     FighterView, BladeView, skins
    effects/      receitas de efeito, pools
    camera/
    hud/
  arenas/         uma cena por arena
  screens/        abertura, menu, seleção, duelo, pausa, resultado, história, diálogos, listas, opções
  modes/          fluxo de cada modo (versus, arcade, sobrevivência, história, tutorial, treino...)
  ui/             tema, paleta, widgets compartilhados (lista de menu, barra, dica de controles)
  localization/   tabelas de tradução (pt_BR, en)
  assets/         arte, fontes, áudio (com registro em ASSETS.md)
  tests/          testes da simulação e dos dados
  tools/          scripts headless (simulador, matriz de confronto, validação de dados)
```

Arquivos e pastas em `snake_case`; classes com `class_name` em `PascalCase`.

## Simulação

- **`MatchSimulation`**: dono do tick. `step(intents)` avança 1/60 s: aplica intenções, máquina de estados dos lutadores, movimento, colisão de corpos, fases dos golpes, choques, acertos, poderes, projéteis, consequências, regeneração, fim de round. Acumula `CombatEvent` do tick.
- **`FighterState`**: dados puros de um lutador (posição, velocidade, estado, golpe atual, fase, tempo na fase, vida, Vigor, Fluxo, status, ferimento, buffer, contadores). Nunca lê `Input` nem nós.
- **Máquina de estados** com os estados de GAME_DESIGN, seção 5; cada estado é uma classe pequena com `enter`, `step`, `exit` e `debug_lines()`.
- **Resolvedores** separados: hitbox × hurtbox, lâmina × lâmina, corpo × corpo, poder × alvo (tabela de Fluxo), projétil × alvo.
- **Tempo**: só o tick fixo. Nada de `delta` real dentro da lógica. **Hit stop** congela os participantes por N ticks. **Câmera lenta** é aplicada pelo executor (menos ticks por segundo real); a apresentação interpola.
- **Aleatoriedade**: um `RandomNumberGenerator` por partida com seed guardada (IA, sorteios, chance de cabeça na finalização). Nada usa o RNG global.
- **Regras por modo**: um conjunto de capacidades (`powers`, `exhaustion`, `wounds`, `focus_evade`, `blade_lock`, `finishers`) passado à simulação; a simulação nunca pergunta "qual é o modo".
- **Snapshot**: o estado completo pode ser copiado e restaurado (replay, desafios com seed, futuro rollback).

### Como está implementada (fases 1 e 2)

| Arquivo | Papel |
| --- | --- |
| `simulation/match_simulation.gd` (`MatchSimulation`) | dono do tick, fases da partida (`INTRO`, `FIGHT`, `KO`, `OVER`), rounds, eventos, snapshot (`capture`/`restore`) |
| `simulation/fighter_state.gd` (`FighterState`) | dados puros do lutador; enums `State`, `Phase`, `Action`, `DodgeKind`, `Wound` |
| `simulation/intent.gd` (`Intent`) | direção + comandos segurados/apertados (`Intent.Command`), empacotáveis num `int` para gravação |
| `simulation/action_starter.gd` | buffer de entrada (0,15 s, prioridade esquiva > empurrão > forte > rápido > guarda) e início de ações com custo de Vigor |
| `simulation/states/` | um `StateLogic` por estado: `GroundState` (IDLE/WALKING), `AirState`, `AttackState` (ATTACKING/HEAVY_ATTACK), `BlockState`, `DodgeState`, `BladeLockState`, `RecoilState` (HIT/STAGGERED/STUNNED), `DeadState` |
| `simulation/combat/` | `ClashResolver`, `BladeLockResolver`, `HitResolver` (acerto, guarda, parry, parry perfeito, empurrão, esquiva de precisão), `BodyResolver` (corpos e paredes), `Consequences` (exaustão, ferimento, membro da finalização), `CombatGeometry` (caixas) |
| `simulation/rules/match_rules.gd` | capacidades por modo: `rounds_to_win`, `exhaustion`, `wounds`, `blade_lock`, `finishers`, `endless` |

Decisões:

- **Ordem do tick**: buffer de entrada dos dois → estado de cada lutador (com integração física) → corpos e paredes → virar de frente → choque de lâminas → acertos → disputa de lâminas → fim de round. O choque é resolvido antes dos acertos (tem prioridade). Os acertos dos dois lados são coletados antes de aplicados, para a troca simultânea valer.
- **Hit stop** é `freeze_ticks` nos dois participantes: o lutador congelado não avança estado nem posição, mas o buffer continua aceitando comandos.
- **Resolvedores estáticos**: os resolvedores e o `ActionStarter` são funções estáticas que recebem a simulação. Assim não há ciclo de referência entre `MatchSimulation` e ajudantes (`RefCounted` em ciclo vaza memória).
- **Sem alocação por tick**: eventos vêm de um pool (`events` + `event_count`), os arrays de trabalho dos acertos vivem na simulação. Os eventos só valem até o próximo `step`: quem precisa guardar copia os campos.
- **Snapshot** lê as variáveis de script de `FighterState` pela lista de propriedades; o estado de RNG entra no snapshot.
- **Geometria**: hurtbox = retângulo do corpo; hitbox = retângulo à frente da borda do corpo, com `reach` e faixa vertical do golpe; colisão de lâmina = mesmo retângulo com `blade_reach` (mais curto), usado só no choque.
- **Distâncias** de knockback, empurrão no bloqueio e separação são dados em u; a simulação converte em velocidade inicial que a desaceleração de chão consome (`CombatConfig.slide_speed_for`).

## Dados

Tudo o que é conteúdo é `Resource` editável no inspetor:

| Recurso | Conteúdo |
| --- | --- |
| `CharacterData` | id, chave do nome, caminho, atributos, potencial, golpes, habilidade, traço, conjunto base, variantes, perfil de IA, cores de lâmina e desafios, trajes, referência à cena visual, timbre do zumbido |
| `MoveData` | tempos, dano, Vigor, knockback, stuns, hitbox (em u, relativa ao corpo), trilha da lâmina por fase (para a colisão de lâmina), rotas de encadeamento, armadura, elegibilidade de ferimento, membro da finalização |
| `PowerData` | categoria, caminho, custo, nível mínimo, tempos, alcance, tabela de interação por diferença, escalas por tier, cor da marca de custo |
| `ArenaData` | id, cena, música, ambiência, frase, flags de apresentação (reflexo, cristais, vento, sombra, poeira) |
| `EncounterData` / `EndingData` | adversário, variante, arena, ajuste de IA, recompensas, condições de saída, chaves das falas |
| Configs de balanceamento | combate, Vigor, Fluxo, disputa, consequências, IA por dificuldade e perfil, efeitos, modos |

Implementados até a fase 2:

- `data/move_data.gd`, `data/character_data.gd`, `data/arena_data.gd`.
- `data/characters/<id>/<id>.tres`: Guardião e Sombra, com a sequência de rápidos e os fortes como sub-recursos; `data/characters/common/` guarda os golpes compartilhados (contra-ataque, empurrão, aéreos). O perfil de IA de cada personagem fica ao lado (`<id>_ai.tres`).
- `data/balance/`: `combat_config.tres` (movimento, Vigor, parry, esquiva, choque, hit stop, câmera lenta, replay, partida), `blade_lock_config.tres`, `consequence_config.tres`, `effects_config.tres` (receitas de efeito por evento, enquadramento da câmera, lâmina, letterbox), `training_config.tres`, `ai/difficulty_*.tres`.
- Os números iniciais vêm de GAME_DESIGN; os que o documento não definia (distância da esquiva, hitstun e blockstun por golpe, alcance de choque) estão nos recursos e citados em GAME_DESIGN.

Nenhum número de balanceamento no código. Os valores iniciais estão nos documentos de `content/` e em GAME_DESIGN.

## Controladores e entrada

- Ações do InputMap com nomes neutros: `move_left`, `move_right`, `jump`, `light_attack`, `heavy_attack`, `block`, `dodge`, `evade`, `special`, `power`, `pause` e as de menu. Conjuntos por jogador (P1/P2) e por dispositivo.
- **`Intent`**: o que o lutador pede neste tick (direção, botões apertados/segurados/soltos). É a única entrada da simulação.
- **`PlayerController`**: lê o InputMap do seu jogador e monta o `Intent` (com o buffer de 0,15 s e a janela do acorde do quarto poder).
- **`AiController`**: pensa em intervalos, lê o estado visível e produz `Intent`. Perfis e dificuldades vêm de dados. Nunca toca no estado.
- **`DummyController`** (Treino, Tutorial) e **`ReplayController`** (reproduz intents gravados).
- Remapeamento salvo em `user://`; telas mostram os bindings atuais com ícones do dispositivo em uso.

Implementação:

- As ações têm prefixo de jogador: `p1_move_left`, `p1_light_attack`, `p2_block`... Ferramentas: `debug_overlay` (F3), `training_dummy_behavior` (F5), `training_record` (F6), `training_playback` (F7). Menus usam as ações `ui_*` da Godot.
- InputMap montado em tempo de execução por `Settings` a partir da tabela de `core/input_bindings.gd` (única fonte de teclas e botões do projeto). Motivo: os bindings de gamepad precisam do `device` por jogador, e o remapeamento da fase 6 vai sobrescrever a mesma tabela com o que estiver salvo. O `project.godot` não guarda ações de jogo.
- Padrão atual: J1 usa o preset de um jogador do teclado (GAME_DESIGN, seção 3) e o gamepad 0; J2 usa o gamepad 1. O preset de teclado de 2 jogadores entra com o modo 2 Jogadores (fase 6).
- `PlayerController` junta os toques recebidos por evento entre dois ticks (nenhum toque se perde em câmera lenta) com o estado segurado lido do `Input`.
- `AiController` (`controllers/ai/`): pensa a cada `reaction_time` com variação, por prioridade (defender → punir → empurrar → recuperar → atacar → posicionar), agenda o toque de parry pela fase do golpe visível do oponente, continua a sequência só quando o golpe conectou, pressiona na disputa depois do tempo de reação, e usa `AiHabitMemory` (memória de hábitos com janela em segundos) no Difícil e no Chefe. Perfis em `AiProfileData`, dificuldades em `AiDifficultyData`.
- `DummyController`: parado, em guarda, atacando ou reproduzindo uma gravação (`IntentRecording` relativa à frente do lutador, então a gravação espelha no boneco).
- `ReplayController`: reproduz uma `IntentRecording` absoluta.

## Apresentação

- **`DuelScreen`**: monta arena, `FighterView` ×2, `CameraRig`, `Hud`, `EffectsDirector`; um executor de tick chama a simulação e despacha os eventos do tick para quem escuta (sinais).
- **`FighterView`**: lê o `FighterState` e escolhe a animação e o ponto dela pela **fase e progresso do golpe** (a animação segue a simulação, nunca o contrário). Trajes trocam materiais e peças, não a lógica.
- **`BladeView`**: camadas da lâmina, luz, rastro, ignição, apagar, tremulação.
- **`EffectsDirector`**: receitas de efeito por evento, com pools de partículas e luzes; respeita "efeitos reduzidos".
- **`CameraRig`**: enquadramento dos dois lutadores, punch-in, tremor, mini-cinemáticas de poder, letterbox.
- **`Hud`**: barras, marcas, rounds, mensagens; lê estado e eventos.
- **`StatsTracker`**, objetivos do tutorial e desafios: escutam eventos.
- Debug **F3**: hitboxes, hurtboxes, colisão de lâmina, estado, fase, Vigor, Fluxo, intents, decisões da IA, FPS, tick.

Implementação provisória (fases 1 e 2, arte de formas simples):

- `presentation/tick_runner.gd` (`TickRunner`): executor de passo fixo com acumulador, no máximo 5 ticks por quadro, câmera lenta (K.O. e parry perfeito, valores em `CombatConfig`), gravação das intenções do round e snapshot no início de cada round. Emite `ticked` e `combat_event`; a interpolação de posição usa `alpha`.
- `presentation/fighters/`: `FighterView` desenha a silhueta provisória em código a partir de `FighterPose` (pose por estado, fase e progresso do golpe; ângulos de preparação e golpe vêm de `MoveData`), `BladeView` desenha a lâmina em três camadas aditivas com rastro e `PointLight2D`, `SeveredPiece` é a peça da finalização (física própria da apresentação).
- `presentation/effects/`: `EffectsDirector` (faíscas e anéis em pool, desenhados num único nó aditivo; emite impulsos para câmera e flash), `ScreenEffects` (flash, letterbox, rótulo do replay).
- `presentation/camera/camera_rig.gd`, `presentation/hud/` (`Hud`, `HudBar`, `RoundMarks`, `TrainingPanel`), `presentation/debug/debug_overlay.gd`, `presentation/stats_tracker.gd`.
- `presentation/duel_environment.tres`: `WorldEnvironment` com fundo Canvas e glow.
- **Replay do golpe final**: a cada round o executor guarda o snapshot do início e as intenções. Depois do K.O. decisivo, `DuelScreen` cria uma nova simulação, restaura o snapshot, re-simula até 3,5 s antes do K.O. e passa a mostrar essa simulação a 45% com `ReplayController`. Nenhuma lógica é reaproveitada da partida original: o replay é a própria simulação de novo.
- **Verificação técnica do renderer** (fase 0): no Compatibility, o glow do `WorldEnvironment` com fundo Canvas funciona em LDR (limiar abaixo de 1); com intensidade alta aparecem blocos de baixa resolução, por isso o glow fica sutil e a maior parte do brilho vem das camadas aditivas da lâmina. `PointLight2D` ilumina corpos e cenário. HDR 2D não é usado. Mapas de normal e reflexos (BackBufferCopy) ficam para o protótipo de arte da fase 3.

**Validação lâmina × animação**: a colisão de lâmina vem da trilha em `MoveData`. Uma ferramenta de editor (ou teste) compara a trilha com a posição real da lâmina na animação, para o que se vê bater com o que acerta.

## Telas e fluxo

- **`SceneRouter`** (autoload): troca de telas por id (`change`, `push`, `pop`), com transições (fade, letterbox). Telas não se importam entre si.
- A pausa é uma tela empilhada sobre o duelo congelado.
- Cada modo é um objeto de fluxo (`modes/`) que monta os parâmetros do duelo (lutadores, variantes, conjuntos, arena, dificuldade, capacidades, rounds, seed) e decide o que acontece no resultado.

Implementação: `SceneRouter.change(id, params)` troca a tela com fade; `push`/`pop` empilham telas sobre a atual e pausam a árvore. Telas recebem os parâmetros em `open(params)`. Ids: `menu`, `duel`, `pause`, `result`. Modos: `DuelMode` (base: `build_setup()`, `result_options()`, `restart()`, `choose()`), `VersusMode` (Guardião contra Sombra na IA, dificuldade das configurações) e `TrainingMode` (boneco, regras `endless`, sem rounds). O menu atual é provisório (Duelar, Treino, Dificuldade, Sair) até o menu completo da fase 6.

## Serviços (autoloads)

- **`Settings`**: opções, idioma, bindings (arquivo `ConfigFile` em `user://`).
- **`SaveService`**: progresso (desbloqueios, recordes, campanha), com versão de formato e migração.
- **`SceneRouter`**: navegação.
- **`AudioDirector`**: música dinâmica em camadas, barramentos, zumbido das lâminas.
- **Localização**: tabelas da Godot (`TranslationServer`, `tr()`), uma chave por texto, marcadores com `format()`. A fonte é `localization/strings.csv` (colunas `pt_BR` e `en`); os `.translation` são gerados pelo import e ficam fora do git.
- **Tema**: `ui/theme/main_theme.tres` (tema do projeto, fonte Oxanium e variações de tipo `TitleLabel`, `SubtitleLabel`, `MenuItemLabel`, `MenuItemSelectedLabel`, `HintLabel`, `HudNameLabel`, `HudWoundLabel`, `HudMessageLabel`, `DebugLabel`) e `ui/palette.tres` (`UiPalette`, cores de interface, HUD e efeitos). Scripts nunca escrevem cores soltas: leem a paleta.
- Dicas de controle são montadas por `ui/widgets/control_hints.gd` a partir do InputMap; listas de menu usam `ui/widgets/menu_list.gd`.

## Testes

- Testes da simulação headless: regras de combate, janelas de parry, disputa, consequências, interação de poderes, IA (com seed), determinismo (mesma seed e intents = mesmo estado final), progressão da História, saves.
- Testes de dados: todo personagem tem golpes válidos, todo texto existe nos dois idiomas, todo asset tem linha em ASSETS.md.
- Testes automatizados aprovados pelo autor. Executor: mínimo e próprio, em `tools/run_tests.gd`, rodado com `godot --headless --script`. Um addon de testes (gdUnit4 ou GUT) só entra se o executor próprio não bastar, com autorização.
- **Simulador**: `godot --headless --script tools/simulate.gd -- --duels 300 --difficulty normal` roda duelos IA × IA e relata vitórias, golpes até o K.O. e duração; uma matriz todos-contra-todos acompanha o equilíbrio do elenco.

Como rodar:

```
godot --headless --path . --import                                   # só com o editor fechado
godot --headless --path . --script res://tools/run_tests.gd          # todos os testes
godot --headless --path . --script res://tools/run_tests.gd -- --filter test_defense
godot --headless --path . --script res://tools/simulate.gd -- --duels 100 --difficulty hard --p1 guardian --p2 shadow --seed 1
```

- Testes ficam em `tests/` (arquivos `test_*.gd`, classe base `TestCase`, métodos `test_*`, `before_each`). `tests/support/duel_fixture.gd` monta um duelo Guardião × Sombra, posiciona os lutadores e registra os eventos.
- O executor resolve `class_name` pelo cache global da Godot. Com o editor aberto, não rode `--import` por fora: o editor e o processo headless disputam o cache e o editor deixa de enxergar as classes novas (e o addon MCP perde o registro). Com o editor aberto, basta ele reescanear os arquivos.
- `tools/headless_duel.gd` (`HeadlessDuel`) roda um duelo IA × IA sem tela; serve ao simulador e aos testes de IA.

## Desempenho

- 60 FPS estáveis. Nada de alocação por tick na simulação; pools na apresentação.
- Medir com o profiler da Godot em cada fase, nas arenas mais pesadas (reflexo, chuva, Tempestade) e com dois lutadores detalhados.
- **Decisão**: verificar mapas de normal em luzes 2D e o custo de reflexos no renderer Compatibility com o protótipo de arte da fase 3. Glow e luzes 2D já foram verificados (ver Apresentação).
