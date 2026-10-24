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
| `simulation/states/` | um `StateLogic` por estado (o `DodgeState` cobre esquiva, dash aéreo, esquiva de precisão, avanço e a esquiva com giro `SPIN`: invulnerabilidade atrasada, deslocamento que atravessa o corpo até o outro lado, virada no fim do deslocamento): `GroundState` (IDLE/WALKING), `AirState`, `AttackState` (ATTACKING/HEAVY_ATTACK), `BlockState`, `DodgeState`, `BladeLockState`, `RecoilState` (HIT/STAGGERED/STUNNED), `DeadState` |
| `simulation/combat/` | `ClashResolver`, `BladeLockResolver`, `HitResolver` (acerto, guarda, parry, parry perfeito, empurrão, esquiva de precisão), `BodyResolver` (corpos e paredes), `Consequences` (exaustão, ferimento, membro da finalização), `CombatGeometry` (caixas) |
| `simulation/combat/blade_press.gd` (`BladePress`) | contador de contatos da Pressão de lâminas (fase 7.5): lê os eventos do tick no fim do `step` (choque de rápidos e parry de rápido contam; acerto, forte, técnica, esquiva, empurrão, poder e disputa zeram; 0,6 s sem contato zera) e abre a pressão pelo `BladeLockResolver.start(..., press = true)`, dando a vantagem a quem aparou. Estado na simulação (`contact_streak`, `contact_idle_ticks`, `contact_parrier`, no snapshot e no F3) e `FighterState.lock_press` durante a pressão |
| Desengajamento | `BladeLockState` aceita o forte depois de `disengage_after` (`BladeLockResolver.can_disengage`); `BladeLockResolver.disengage` cobra o Vigor do golpe, encerra a disputa ou a pressão sem vencedor (recarga compartilhada), prende o rival em `HIT` por `disengage_release` (o buffer guarda guarda ou parry) e começa o golpe `DISENGAGE` (`MoveData.Kind.DISENGAGE`: lâmina, não é forte, não encadeia). A IA decide em `AiController._try_disengage` |
| `simulation/rules/match_rules.gd` | capacidades por modo: `rounds_to_win`, `exhaustion`, `wounds`, `blade_lock`, `finishers`, `endless` |

Decisões:

- **Ordem do tick**: buffer de entrada dos dois → estado de cada lutador (com integração física) → corpos e paredes → virar de frente → choque de lâminas → acertos → disputa de lâminas → fim de round. O choque é resolvido antes dos acertos (tem prioridade). Os acertos dos dois lados são coletados antes de aplicados, para a troca simultânea valer.
- **Hit stop** é `freeze_ticks` nos dois participantes: o lutador congelado não avança estado nem posição, mas o buffer continua aceitando comandos.
- **Resolvedores estáticos**: os resolvedores e o `ActionStarter` são funções estáticas que recebem a simulação. Assim não há ciclo de referência entre `MatchSimulation` e ajudantes (`RefCounted` em ciclo vaza memória).
- **Sem alocação por tick**: eventos vêm de um pool (`events` + `event_count`), os arrays de trabalho dos acertos vivem na simulação. Os eventos só valem até o próximo `step`: quem precisa guardar copia os campos.
- **Snapshot** lê as variáveis de script de `FighterState` pela lista de propriedades; o estado de RNG entra no snapshot.
- **Geometria**: hurtbox = retângulo do corpo; hitbox = retângulo à frente da borda do corpo, com `reach` e faixa vertical do golpe; colisão de lâmina = mesmo retângulo com `blade_reach` (mais curto), usado só no choque.
- **Habilidades** (fase 4): `AbilityData` (`data/ability_data.gd`) com cinco tipos, todos sobre os estados existentes:
  - `STRIKE`: um `MoveData` de tipo `ABILITY` (armadura `armor_hits`/`armor_damage_ratio`, `hits_behind`, `counts_as_heavy`);
  - `STANCE`: um golpe de tipo `STANCE` gerado pela habilidade (sem hitbox); um golpe de lâmina de frente durante o active desequilibra o atacante e inicia o golpe de resposta (`RESPONSE`, ou `PERFECT_PARRY` com `perfect_response`);
  - `DASH`: `DODGING` com `DodgeKind.DASH` (distância, invulnerabilidade, atravessar);
  - `CHARGE`: o golpe fica preso no último tick da preparação enquanto Habilidade é segurada; o nível sobe a cada `charge_level_time`, aumenta o dano e no nível máximo quebra a guarda;
  - `LEAP`: pulo com velocidade própria; com `dive_when_falling`, o golpe de mergulho sai sozinho na descida.
- **Traços** são campos de `CharacterData` lidos pelos resolvedores: andar em guarda, imunidade ao empurrão no bloqueio, dreno extra do rápido bloqueado, janelas de parry próprias, ponto doce, bônus de punição, multiplicador de knockback, pulo na parede, esquiva que atravessa, número de aéreos por pulo, finta e vida fixa (chefe).
- **Distâncias** de knockback, empurrão no bloqueio e separação são dados em u; a simulação converte em velocidade inicial que a desaceleração de chão consome (`CombatConfig.slide_speed_for`).

### O Fluxo (fase 5)

| Arquivo | Papel |
| --- | --- |
| `data/powers/power_data.gd` (`PowerData`) | um recurso por poder: caminho, `kind`, custo (fixo e por segundo), nível mínimo, recarga própria, tempos, alcance, dano, valores por tier, tabela de interação, marca de custo alto |
| `data/powers/interaction_table.gd`, `interaction_band.gd`, `data/powers/tables/` | resultado pela diferença de Fluxo (escala, resistido, fura a guarda) |
| `data/powers/catalog.tres` (`PowerCatalog`) | ordem do catálogo, técnicas, poderes permitidos por personagem (caminho e nível mínimo), conjunto base e troca de duplicados do editor |
| `data/techniques/*.tres` | técnicas de lâmina como `MoveData` de tipo `TECHNIQUE` |
| `data/balance/flow_config.gd` | medidor, ganhos, recarga compartilhada, janela do acorde, tiers, multiplicadores no ar, valores dos status |
| `simulation/powers/` | `PowerStarter` (espaço pela direção, custo, recusa), `PowerEffects` (efeito de cada `kind` na ativação, no canal e na soltura), `PowerImpact` + `PowerHit` (resolução: resistido → Absorção → Barreira → guarda → acerto), `ProjectileSystem`/`Projectile`, `HazardSystem`/`Hazard` (marcas no chão com atraso), `FlowStatuses` (regeneração, recargas e status por tick) |
| `simulation/states/power_state.gd`, `held_state.gd` | estados `CASTING`/`CHANNELING` de quem lança e `HELD` de quem está congelado ou estrangulado |

Decisões:

- **Espaços**: quatro por lutador (`neutral`, `forward`, `back`, quarto). O quarto sai do acorde Poder + Habilidade dentro de `chord_window`; o `ActionStarter` segura o toque de Poder por essa janela antes de decidir.
- **Projéteis e marcas** vivem em pools fixos na simulação (16 projéteis, 48 marcas) e entram no snapshot. Marcas da mesma onda formam um grupo que acerta no máximo uma vez.
- **Técnicas** reaproveitam o `AttackState`: `multi_hits`, `stagger_on_guard`, bônus e lançamento contra quem está no ar, arremesso da lâmina (`blade_out` bloqueia ações de lâmina até ela voltar), golpe aéreo que mantém a recovery depois de aterrissar. O choque entre técnicas é resolvido no `ClashResolver` (evento `TECHNIQUE_CLASH`).
- **Conjunto personalizado**: `DuelSelection.power_sets` → `DuelSetup.power_sets` → `FighterState.equip_powers()` antes de `start_match()`. Conjunto vazio significa o base do personagem.
- **Regras**: `MatchRules.powers` liga tudo; `free_powers` (Galeria) mantém o medidor cheio. `MatchSimulation.restage()` recoloca os lutadores e limpa projéteis e marcas sem mudar o round (início de round e Galeria).

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

Implementados até a fase 4:

- Elenco completo em `data/characters/<id>/`: os onze do elenco comum, o chefe (`awakened_shadow`, não selecionável) e os três secretos (`sovereign`, `elder`, `foretold`); a variante Eclipse do Predestinado é um personagem à parte (`foretold_eclipse`) apontado por `CharacterData.variant`.
- Aparência no próprio `CharacterData`: `art` (peças pintadas), `family` (`data/families/*.tres`), `weapon` (`WeaponData`), `costumes` (`CostumeData`), `blade_colors` com as chaves dos nomes, guarda e empunhadura.

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
- Implementação (fase 6): `InputBindings.preset_keys(preset)`, `apply_keyboard(keys)`, `keyboard_map()` e `rebind(keys, action, key)` (troca de lugar); `Settings` guarda `key_preset` e `custom_keys` (seção `input` do arquivo) e aplica em `apply()`. Telas `keys` e `controls` no `SceneRouter`. Gamepad (fase 8): `InputBindings.default_buttons()`, `apply_buttons(map)` (troca só os `InputEventJoypadButton` das ações de combate dos dois jogadores, cada um no seu `device`), `button_map()`, `rebind_button()` (mesma troca de lugar das teclas, `_swap`) e `is_reserved_button()`; `ControlHints.button_names()` nomeia botões e eixos pelas chaves `PAD_*` e `PAD_AXIS_*` da tabela de tradução.
- **Vibração**: `EffectRecipe.rumble_*` (golpe forte, choque, quebra de guarda, K.O., disputa, parry perfeito, choque entre técnicas); o `EffectsDirector` emite `rumbled` e o `DuelRumble` vibra o gamepad (`device` = slot do jogador) só dos lutadores humanos envolvidos, se `Settings.vibration`; desliga no replay.

Implementação:

- As ações têm prefixo de jogador: `p1_move_left`, `p1_light_attack`, `p2_block`... Ferramentas: `debug_overlay` (F3), `training_dummy_behavior` (F5), `training_record` (F6), `training_playback` (F7). Menus usam as ações `ui_*` da Godot.
- InputMap montado em tempo de execução por `Settings` a partir da tabela de `core/input_bindings.gd` (única fonte de teclas e botões do projeto). Motivo: os bindings de gamepad precisam do `device` por jogador, e o remapeamento da fase 6 vai sobrescrever a mesma tabela com o que estiver salvo. O `project.godot` não guarda ações de jogo.
- Padrão atual: J1 usa o preset de um jogador do teclado (GAME_DESIGN, seção 3) e o gamepad 0; J2 usa o gamepad 1. No modo **2 Jogadores** (`TwoPlayerMode`, `DuelSetup.two_players`), o `DuelScreen` aplica `InputBindings.apply_two_player_keyboard()` (J1 `W A S D`, `F G H`, `T`, `R`, Shift esquerdo; J2 setas, `J K L`, `I`, `O`, Shift direito ou `0` do teclado numérico; pausa `Esc` e `P`, com `InputEventKey.location` separando os dois Shift) e volta ao preset salvo em `_exit_tree` (`Settings.apply()`).
- `PlayerController` junta os toques recebidos por evento entre dois ticks (nenhum toque se perde em câmera lenta) com o estado segurado lido do `Input`.
- `AiController` (`controllers/ai/`): pensa a cada `reaction_time` com variação, por prioridade (defender → punir → empurrar → recuperar → atacar → posicionar), agenda o toque de parry pela fase do golpe visível do oponente, continua a sequência só quando o golpe conectou, pressiona na disputa depois do tempo de reação, e usa `AiHabitMemory` (memória de hábitos com janela em segundos) no Difícil e no Chefe. Perfis em `AiProfileData`, dificuldades em `AiDifficultyData`.
- `DummyController`: parado, em guarda, atacando ou reproduzindo uma gravação (`IntentRecording` relativa à frente do lutador, então a gravação espelha no boneco).
- `ReplayController`: reproduz uma `IntentRecording` absoluta.
- Esquiva com giro na IA: `AiController._try_spin_dodge` (forte na preparação, colado, `AiDifficultyData.spin_dodge_chance` cheia encurralado e reduzida por `spin_dodge_open_ratio` no meio da arena).
- `AiPowers` (`controllers/ai/ai_powers.gd`): funções puras que a IA consulta — espaço pronto (medidor, nível, recargas), poder desejável pela situação (zona, distância, auto-reforço, cura, fuga apanhando), defesa (Absorção/Barreira contra o poder que vem), ameaça de marca no chão e de projétil. O `AiController` agenda o toque com direção (`_press_direction`) e segura o canal (`_channel_ticks`). `offensive_slot` testa o quarto espaço primeiro e, com `save_for_fourth`, pula os poderes que gastariam a reserva do quarto (`spends_fourth_reserve`); o Truque Mental espera o oponente se comprometer com uma direção. Chances em `AiDifficultyData` (`power_chance`, `power_defense_chance`) e preferências em `AiProfileData` (`power_bias`, `technique_bias`).
- `GalleryCaster` e `GalleryTarget` (Galeria de poderes): o lançador repete o poder ou a técnica escolhida; o alvo fica parado, em guarda, com Barreira, com Absorção, no ar ou atacando com Raio.

## Apresentação

- **`DuelScreen`**: monta arena, `FighterView` ×2, `CameraRig`, `Hud`, `EffectsDirector`; um executor de tick chama a simulação e despacha os eventos do tick para quem escuta (sinais).
- **`FighterView`**: lê o `FighterState` e escolhe a animação e o ponto dela pela **fase e progresso do golpe** (a animação segue a simulação, nunca o contrário). Trajes trocam materiais e peças, não a lógica.
- **`BladeView`**: camadas da lâmina, luz, rastro, ignição, apagar, tremulação.
- **`EffectsDirector`**: receitas de efeito por evento, com pools de partículas e luzes; respeita "efeitos reduzidos".
- **`CameraRig`**: enquadramento dos dois lutadores, punch-in, tremor, mini-cinemáticas de poder, letterbox.
- **`Hud`**: barras, marcas, rounds, mensagens; lê estado e eventos.
- **`StatsTracker`**, objetivos do tutorial e desafios: escutam eventos.
- Debug **F3**: hitboxes, hurtboxes, colisão de lâmina, estado, fase, Vigor, Fluxo, intents, decisões da IA, FPS, tick.

### Pipeline de arte (fase 3)

- **Pintura**: `tools/art/paint_fighters.py` (Python 3 com numpy e Pillow, ferramenta offline; o jogo não depende dela) pinta cada personagem descrito em `tools/art/fighter_specs.py` direto na grade de pixels do mundo (0,5 px por u, 1 pixel = 2 u): pinta as formas numa escala fina (8× a grade) e reduz para a grade com borda dura (cobertura ≥ 50%), quatro tons fixos (`TONES`) e contorno de 1 px (`RIM_TONE`) na borda externa. Até a fase 5 eram peças de alta resolução (4 px por u, tag `phase-5-hd`). Cada peça gera dois PNG em `assets/characters/<id>/`:
  - `<peça>.png`, **mapa de material**: R = tom (0,5 é a cor do traje), G = slot de paleta / 7, B = emissão, A = cobertura;
  - `<peça>_n.png`, **mapa de normal** (convenção OpenGL, Y para cima), gerado do relevo pintado.
- **Slots de paleta**: 0 capa/túnica, 1 corpo, 2 acabamento, 3 pele, 4 cabelo, 5 metal, 6 couro, 7 olhos (emissivo). Os trajes (`CostumeData`) escolhem as 8 cores e mostram ou escondem peças (`hood`, `mask`, `pad`, `collar`, `neckerchief`, `cape`...). Trocar de traje não muda nenhuma textura: o shader `presentation/fighters/fighter_material.gdshader` recolore o mapa de material.
- **`art.tres`** (`FighterArt`, gerado junto): texturas, mapas de normal, pivôs das peças, proporções do rig (`dims`) e os tecidos (`cloths`: âncora, comprimento, larguras, rigidez).
- Peças pintadas à mão podem substituir as procedurais mantendo o mesmo formato (nomes, pivôs, canais).
- **Rig** (`FighterRig`): `Skeleton2D` com um `Bone2D` por segmento (pélvis, tronco, cabeça, braços, pernas), `Sprite2D` com `CanvasTexture` (difusa + normal) em cada osso, IK de dois ossos para braços e pernas (`TwoBoneIk`), `ClothStrip` com física própria (verlet) para capas, túnicas, cachecol e faixas, e `HiltView` para o cabo.
- **Pose** (`PoseSolver` → `RigPose`): calculada a cada quadro a partir do `FighterState` (estado, fase e progresso do golpe) e da família de movimento (`MotionFamily` em `data/families/`). Ângulos de preparação e golpe vêm do `MoveData`; guarda e empunhadura vêm do `CharacterData`. A pose é suavizada (exponencial), mais rígida durante o golpe para não atrasar o que a simulação mostra.
  - **Espaço dos braços (fase 8)**: os alvos autorados são relativos à pélvis no referencial do tronco; o solver os rotaciona pelo `torso_angle`. `RigPose` entregue ao rig contém posições locais finais, com o ângulo da arma independente do tronco. `ArmGeometry` compartilha a posição dos ombros e limita os alvos pelos comprimentos reais de `FighterArt`, com folga configurada em `MotionFamily`. Nas empunhaduras ligadas, projeta a mão principal na interseção dos alcances dos dois braços e reconstrói a mão de trás ao longo do cabo. O vínculo e o alcance são reaplicados no rig depois da suavização, antes de desenhar mãos, cabo e lâminas; o teste de sincronia usa a mesma geometria. A continuidade de sequências converte a pose anterior de volta ao referencial do tronco. Preferências de cotovelo por braço e preparação ficam na família; nenhuma mudança na simulação.
    - `arm_fold_margin` também impede que a mão entre na região inalcançável junto ao ombro (diferença entre os comprimentos dos ossos), evitando encurtar o antebraço. O antebraço e a mão de trás mudam de profundidade ao alcançar a frente ou o cabo; a lista de camadas do reflexo é invalidada nessa troca. Testes em `test_arm_pose.gd` cobrem cada tick de cada fase dos golpes, todos os estados e poderes, poses misturadas, cotovelos na guarda compacta e os pontos usados pelas mãos desenhadas.
  - **Golpes** (segunda etapa da pixel art): a mão percorre um **arco** (curva de Bézier com o controle empurrado para fora do peito, `MotionFamily.arc_bulge`), não uma reta. A preparação desacelera no fim (antecipação) e leva o peso para trás (`windup_shift`, `windup_lean`); o ativo é quase linear, com o quadril avançando (`lunge`) e o passo do pé da frente; a recuperação faz o follow-through e assenta com easing. O forte usa as mesmas curvas com escala maior. Cada golpe da sequência começa do ângulo e da mão em que o anterior terminou (o solver guarda o ponto de partida ao trocar de golpe).
  - **Pressão de lâminas**: a mesma pose da disputa, mais baixa (`PRESS_FACE_HEIGHT`), com o cruzamento trocando de inclinação a cada pressão e os pés andando meio passo pela vantagem.
  - **Disputa**: a mão fica à altura do peito e a lâmina aponta para um ponto de cruzamento entre os rostos (metade da distância real entre os lutadores); o ponto desliza para o lado de quem perde e cada pressão dá um empurrão curto da mão e do tronco.
  - **Atingido e choque**: o tranco decai exponencialmente (tronco e cabeça para trás, passo de trás); no choque (`CLASH`), a lâmina ricocheteia para cima e para trás até a guarda. Pulo com pose de subida, ápice e queda pela velocidade vertical.
  - **Técnicas**: `MoveData.technique_style` (dado do golpe) escolhe a pose própria (Giro, Avanço, Arremesso, Estocada, Corte ascendente, Rajada, Investida da Haste `LUNGE`, Investida descendente `PLUNGE`); `ARC` usa o arco genérico. O estilo vale para qualquer golpe, não só técnicas: a habilidade da Haste e do Soberano usa `LUNGE`. A Varredura foi removida na fase 7.5 (técnicas substituídas pelo Corte ascendente na Brasa, Giro no Eco e Avanço com corte no Predestinado Eclipse; `stagger_on_guard` saiu junto). O Giro preenche `RigPose.turn`, que o `FighterView` aplica como escala horizontal do rig; a lâmina usa o vetor transformado sem normalizar antes de medir, para encurtar em escorço. `RigPose.open_hand` troca a textura da mão livre por `hand_open`. O teste de sincronia cobre as técnicas, menos Arremesso (projétil) e Giro (acerta dos dois lados).
  - **Empunhadura por família** (fase 7.5): `MotionFamily.back_hand_spacing` (mão de trás no cabo; o Guardião segura no pomo), `free_hand` (mão livre nas empunhaduras de uma mão), `off_guard_hand`/`off_guard_angle` (segunda lâmina da Vespa em guarda), `wrist_lag` (cadeia ombro → cotovelo → punho: o corpo avança cedo, `SHOULDER_LEAD`, e o ângulo da lâmina chega por último), `recover_share` (rapidez da volta à guarda) e `one_hand_follow` (solta a mão de trás no follow-through do forte). A Haste usa as duas mãos na haste em qualquer família. A Vespa alterna as lâminas pelos passos da sequência (`_place_second_blade`); o teste de sincronia aceita a segunda lâmina nas armas duplas.
  - **Tipos de corte** (fase 7.5): `MoveData.cut` (`DESCENDING`, `RISING`, `HORIZONTAL`, `THRUST`, `SPIN`) escolhe os pontos de preparação e de impacto da mão (`CUT_WINDUP`, `CUT_STRIKE`, escalados pela família); `HORIZONTAL` e `SPIN` torcem o corpo com `RigPose.turn` (`_cut_turn`). `tests/data/test_cuts.gd` exige um tipo por passo, sem repetir na sequência, e forte descendente ou giro (ascendente só no Golpeador).
  - **Guarda direcional** (fase 7.5): `PoseSolver.threat_line(move)` lê a linha do golpe do oponente (tipo de corte, estilo de técnica ou ângulo da preparação) e `_block` escolhe a pose alta, média, baixa ou de estocada; `block_line` guarda a última. Faíscas no contato: `EffectsDirector._blade_contact` usa `FighterView.blade_segment()` dos dois lutadores (pontos mais próximos entre as lâminas, até `EffectsConfig.blade_contact_snap`) em bloqueio, parry e choque; longe disso, vale a posição do evento.
  - **Avanço com corte** (fase 7.5): `_dash_slash` pinta a arrancada na preparação (lâmina recolhida, `PoseSolver.afterimage` liga as imagens residuais do `FighterView`) e o corte no ativo; a simulação faz a arrancada na preparação (`MoveData.dash_in_startup`, `AttackState`).
  - **Investida descendente** (fase 7.5): `_plunge` (preparação encolhida com a lâmina erguida, mergulho inclinado com `RigPose.spin`, pouso ajoelhado com pausa). No `LAND` de quem está na Investida (`EffectsDirector.is_plunging`), o `EffectsDirector` solta a receita `plunge_impact` e o `DebrisLayer` a poeira, ambos na ponta da lâmina (`plunge_point`).
  - **Arremesso com duas lâminas** (fase 7.5): `PowerView._draw_dual_throw` desenha as duas lâminas da arma dupla a partir do único projétil `BLADE` (a de trás defasada por `dual_throw_delay`, arcos espelhados por `dual_throw_arc`, giros opostos). Com `FighterState.blade_out`, o solver estende as mãos abertas para receber a lâmina (as duas na Vespa).
  - **Acrobacias** (fase 7.5): `PoseSolver.vault_progress` (salto de transposição; o `FighterView._check_vault` dispara ao cruzar o oponente no pulo e espelha o desenho a partir da metade, `vault_turned`) e `tumble_left` (`start_tumble` nos eventos de separação longa: mortal para trás nas famílias ágeis, derrapada com a mão no chão nas outras). Testes em `tests/presentation/test_acrobatics.gd`.
  - O solver só guarda estado de apresentação (tempo, fase do passo, ponto de partida do golpe, pulso da disputa, recuo do choque), avançado por `PoseSolver.advance(delta)`.
- **Arma** (`WeaponData`, `WeaponPose`): lâmina simples, dupla (duas mãos), lança (haste longa) ou bastão com duas lâminas; o mesmo cálculo serve à apresentação e ao teste de sincronia.
- **Camadas e luz**: o mundo (arena e corpos) fica no canvas principal, escurecido por um `CanvasModulate` com a cor ambiente da arena; cada lâmina tem uma `PointLight2D` que ilumina os corpos pelos mapas de normal. Lâminas, olhos do Eclipse, imagens residuais e faíscas ficam numa `CanvasLayer` acima (`follow_viewport_enabled`), com cor total. Entre as duas, a `CanvasLayer` de dessaturação do parry perfeito (shader de tela): assim só as lâminas mantêm a cor.
- **Reflexo**: em arenas com `reflective_floor`, cada lâmina é desenhada de novo, espelhada e achatada sobre o chão, como mancha de luz (decisão da verificação técnica: sem `BackBufferCopy`, barato no Compatibility).
- **Validação lâmina × hitbox**: `tests/presentation/test_blade_sync.gd` percorre todos os golpes de todos os personagens com arte e exige que a lâmina desenhada cruze a hitbox real em algum tick do active.

### Arenas (fase 6)

- `SceneryLayer` (`arenas/common/scenery_layer.gd`): pintor de cenário genérico por tipo de camada, desenhado uma vez em `_draw` (as nuvens redesenham com `drift`); medidas em múltiplos de 2 u. `lit_by_blades = false` tira as camadas distantes da luz das lâminas.
- Cenas e `ArenaData` gerados por `tools/art/make_arenas.py` (paletas do content/ARENAS.md). Cada cena tem o nó `SkyAnchor` logo depois do céu, para o céu da Tempestade.
- `DuelMode.ARENAS` lista as dez arenas na ordem do rodízio mais a Plataforma de Treino; Arcade e Sobrevivência usam as `ROTATION_SIZE` primeiras.
- `ArenaData.wind` é repassado ao `FighterRig` e aos `ClothStrip` (rajada com tremulação).
- `FighterReflection`: redesenha os sprites e tecidos do rig espelhados no chão, com o material de paleta do próprio rig, escurecidos (`ArenaData.fighter_reflection`, `reflection_shade`); z logo acima do cenário. Pegadas, ondulações, poeira de sal e vapor ficam no `DebrisLayer` (marcas em pool fixo, partículas com tom por instância).
- `ArenaThumbnail` (`presentation/arena_thumbnail.gd`): a cena da arena num `SubViewport` de 300×170 pixels na grade do mundo, ampliada 2×, na etapa de arena da seleção.

### Áudio (fase 3)

- `tools/audio/synth_audio.py` sintetiza todos os sons, a música e a ambiência (WAV em `assets/audio/`). Loops (zumbido, atrito da disputa, música, ambiência) são importados com `loop_mode` Forward.
- Barramentos em `default_bus_layout.tres`: Music, Effects, Blades, Interface, Ambience. Music, Effects e Ambience têm um passa-baixas desligado que o `AudioDirector` liga para abafar o mundo (parry perfeito, K.O.); Blades nunca é abafado.
- `AudioDirector` (autoload): pool de `AudioStreamPlayer2D` (estéreo pela posição na tela), sons de interface, música em camadas sincronizadas (`AudioStreamSynchronized`: base, percussão e tensão, abrindo conforme a vida mais baixa), ambiência da arena, abafar e abaixar a música.
- `DuelAudio` (apresentação): reage aos eventos de combate, mantém o zumbido de cada lâmina (tom por `WeaponData.hum_pitch`, mais alto e agudo no active), o atrito contínuo da disputa, passos e a batida de vida baixa do jogador.
- `SoundBank` (`data/audio/sound_bank.tres`) liga ids a arquivos; `MusicData` agrupa as camadas e o tom (`pitch`, aplicado ao player de música); `ArenaData` aponta música (variações em `data/audio/arena_music/`) e ambiência. `DuelScreen.duel_music(setup)` escolhe o `CharacterData.theme` do adversário (depois o do jogador) antes da música da arena; o `DuelAudio.intensity_floor` sobe no despertar do chefe.

Implementação provisória (fases 1 e 2, arte de formas simples, substituída na fase 3):

- `presentation/tick_runner.gd` (`TickRunner`): executor de passo fixo com acumulador, no máximo 5 ticks por quadro, câmera lenta (K.O. e parry perfeito, valores em `CombatConfig`), gravação das intenções do round e snapshot no início de cada round. Emite `ticked` e `combat_event`; a interpolação de posição usa `alpha`.
- `presentation/fighters/`: `FighterView` desenha a silhueta provisória em código a partir de `FighterPose` (pose por estado, fase e progresso do golpe; ângulos de preparação e golpe vêm de `MoveData`), `BladeView` desenha a lâmina em três camadas aditivas com rastro e `PointLight2D`, `SeveredPiece` é a peça da finalização (física própria da apresentação).
- `presentation/effects/`: `EffectsDirector` (faíscas e anéis em pool, desenhados num único nó aditivo; emite impulsos para câmera e flash), `ScreenEffects` (flash, letterbox, rótulo do replay).
- `presentation/camera/camera_rig.gd`, `presentation/hud/` (`Hud`, `HudBar`, `RoundMarks`, `TrainingPanel`), `presentation/debug/debug_overlay.gd`, `presentation/stats_tracker.gd`.
- `presentation/duel_environment.tres`: `WorldEnvironment` com fundo Canvas e glow.
- **Replay do golpe final**: a cada round o executor guarda o snapshot do início e as intenções. Depois do K.O. decisivo, `DuelScreen` cria uma nova simulação, restaura o snapshot, re-simula até 3,5 s antes do K.O. e passa a mostrar essa simulação a 45% com `ReplayController`. Nenhuma lógica é reaproveitada da partida original: o replay é a própria simulação de novo.
- **Verificação técnica do renderer** (fase 0): no Compatibility, o glow do `WorldEnvironment` com fundo Canvas funciona em LDR (limiar abaixo de 1); com intensidade alta aparecem blocos de baixa resolução, por isso o glow fica sutil e a maior parte do brilho vem das camadas aditivas da lâmina. `PointLight2D` ilumina corpos e cenário. HDR 2D não é usado. Mapas de normal e reflexos (BackBufferCopy) ficam para o protótipo de arte da fase 3.

### Grade de pixels (migração para pixel art)

- `PixelStage` (`presentation/camera/pixel_stage.gd`): o mundo do duelo (arena, lutadores, camada de brilho, dessaturação, `WorldEnvironment`) vive num `SubViewport` com filtro nearest e transformações presas a pixels. Uma `Camera2D` interna com zoom fixo `1 / units_per_pixel` (`EffectsConfig.units_per_pixel` = 2 u por pixel) segue o `CameraRig`, que continua no viewport principal calculando o enquadramento (e servindo de ouvinte do áudio 2D).
- A cada quadro o tamanho do `SubViewport` é a tela dividida pela escala de pixel (`zoom do CameraRig × units_per_pixel`), então o zoom muda o tamanho de todos os pixels por igual. A câmera interna anda em pixels inteiros; a sobra fracionária desloca a imagem final, para a câmera deslizar suave sem os pixels tremerem.
- A imagem é ampliada por `pixel_upscale.gdshader` (sharp bilinear: cada pixel é um bloco sólido, com transição de 1 pixel de tela entre blocos), o que mantém os pixels do mesmo tamanho mesmo em escalas não inteiras. HUD, telas e textos ficam fora da grade, em alta resolução.
- `FighterPreview` (seleção) e `MenuEmblem` (menu) desenham num `SubViewport` próprio na mesma grade e o mostram ampliado 4× com o mesmo `pixel_upscale.gdshader` do duelo: com `canvas_items`, a escala real na janela padrão (1600×900) é 3,33 px por pixel, e o filtro nearest puro deixaria colunas de pixel com larguras diferentes.

### Poderes na apresentação (fase 5)

- `PowerView` (`presentation/effects/power_view.gd`, camada aditiva do brilho): desenha a partir do estado — brilho de preparação, canais (domo, raios, fio do Dreno, escudo da Tempestade), status (Cura, Foco, Ira e armadura, Santuário rachando, Truque Mental, gelo, estrangulamento, Arsenal em órbita), projéteis e marcas — e rajadas curtas por evento (ondas de choque, anéis, flash, raio caindo), em pool fixo. A cor é a do tier de quem lança (`UiPalette.flow_tiers`); o resistido usa o tier do alvo. Escurece o `CanvasModulate` da arena durante a Tempestade, com clarão a cada raio.
  - **Repulsão (fase 8)**: `Burst.SHOCKWAVE` guarda origem, destino, sentido e tier no pool. O evento ativo agenda a origem; no próximo processamento do efeito, depois de o `FighterView` aplicar a pose, usa a palma realmente desenhada. A soltura da Repulsão usa a suavização rápida dos golpes. O destino horizontal é fixado na borda do corpo + `PowerData.reach`; o tier só altera altura, espessura e ecos. A Suprema cria duas ondas a partir do corpo. `shockwave_point` gera o arco e as faixas afinadas na grade de 2 u; o fade usa `EffectsConfig.fade_steps`. `reduced` chega do `DuelScreen`: remove ecos, riscos extras e flashes, atenua a onda e reduz a poeira no `DebrisLayer`. Testes em `test_repulse_wave.gd` verificam origem depois da pose, simetria, alcance, grade, tiers, preparação e efeitos reduzidos.
- `CutMarks` (`presentation/fighters/cut_marks.gd`, no rig): tampa em brasa e fumaça do coto, talho do ferimento e brasas, recalculados a cada quadro pelas posições dos ossos. `FighterRig.sever(limb, front)` esconde as peças do lado cortado; a queda varia pelo `FighterState.finisher_limb`.
- `PoseSolver` tem poses de lançar (mão estendida, invocação para o alto, golpe no chão, sobre si) e de estrangulado; o congelado mantém a última pose. A lâmina some enquanto está arremessada.
- `EffectsDirector`: receitas `power_hit`, `power_blocked`, `hazard`, `technique_clash` em `EffectsConfig`; faíscas de poder na cor do tier.
- `DebrisLayer` (`presentation/effects/debris_layer.gd`, no mundo, z acima dos lutadores, mistura normal): pool de poeira e fragmentos com gravidade e quique, e o que é sólido nos poderes, lido do estado (pedras do Arremesso subindo na preparação e em voo, meteoro e pedaços da Telecinese em Massa, cuja posição de queda sai do tempo restante de cada marca). Reage a `POWER_ACTIVE`, `SHOVE`, `PROJECTILE_ENDED` e `HAZARD_TRIGGERED`.
- `StormSky` (`presentation/effects/storm_sky.gd`): nuvens e relâmpagos distantes da Tempestade, pendurados no nó `SkyAnchor` da cena da arena (logo depois do vazio, antes das colunas, para ficar atrás do cenário); sem âncora, entra no mundo com z −5. Cada relâmpago emite `flashed`, que o `PowerView` usa para clarear o `CanvasModulate`.
- **Cinemática da Telecinese em Massa**: o `DuelScreen` liga letterbox, recuo e `CameraRig.sky_shot` (sobe, segura, desce) no `POWER_ACTIVE`, nunca no `POWER_STARTED`; a preparação interrompida não mostra nada além do aviso. Testado em `tests/presentation/test_power_presentation.gd`. Desde a fase 7.5 a simulação congela no evento ativo por `PowerData.cinematic_freeze` (`MatchSimulation.cinematic_ticks`: o `step` só conta o tick e volta; entra no snapshot e aparece no F3); a subida e o meteoro rachando cabem no congelamento, a descida acompanha os pedaços caindo sobre as marcas.
- Números dos efeitos de poder em `PowerVfxConfig` (`data/balance/power_vfx_config.tres`); cores de poeira, pedra e nuvem no `UiPalette`.
- `Hud`: barra de Fluxo (`FlowBar`) na cor do lado, com as marcas de custo alto e o piscar do poder recusado; `show_flow_only()` na Galeria.
- `DuelAudio`: um som por ativação, acerto, marca e impacto; loops de canal (Barreira, Raio, Dreno) num player por lutador; quebras (gelo, Santuário, armadura da Ira) detectadas pela mudança de estado. Sons em `assets/audio/powers/`, gerados por `tools/audio/synth_audio.py`.

**Validação lâmina × animação**: a colisão de lâmina vem da trilha em `MoveData`. Uma ferramenta de editor (ou teste) compara a trilha com a posição real da lâmina na animação, para o que se vê bater com o que acerta.

## Telas e fluxo

- **`SceneRouter`** (autoload): troca de telas por id (`change`, `push`, `pop`), com transições (fade, letterbox). Telas não se importam entre si.
- A pausa é uma tela empilhada sobre o duelo congelado.
- Cada modo é um objeto de fluxo (`modes/`) que monta os parâmetros do duelo (lutadores, variantes, conjuntos, arena, dificuldade, capacidades, rounds, seed) e decide o que acontece no resultado.

Seleção (fase 4): `screens/select/character_select.gd` percorre os passos do modo (`DuelMode.steps()`: Duelar = jogador, adversário, arena; Treino = jogador, boneco) e grava as escolhas em `DuelMode.selection` (`DuelSelection`: personagem, traje e cor de lâmina por lado, arena). `build_setup()` aplica a seleção; Revanche e Reiniciar reaproveitam a mesma seleção. Ações de menu próprias: `menu_costume` (C, botão Y), `menu_variant` (V, botão X) e `menu_powers` (P, LB), que abre o editor de poderes no lugar da coluna central.

Arcade e Sobrevivência (fase 6): `ArcadeMode` e `SurvivalMode` guardam o progresso no próprio objeto do modo, que passa de duelo em duelo (`choose(&"next")`/`&"retry"` chama `start()` de novo). Ganchos em `DuelMode`: `finish(winner, sim)` (chamado pelo `DuelScreen` antes do resultado), `result_title()`, `result_note()`, `result_options()`. Números em `ModesConfig` (`data/balance/modes_config.tres`). Vida inicial por lutador em `MatchRules.start_health` (aplicada em `restage`). O chefe desperta pela IA: `AiController.awakening` troca a dificuldade abaixo de `awaken_below` da vida; o `DuelScreen` percebe `awakened` e mostra "A SOMBRA DESPERTA" com letterbox pulsando. Faixa do modo no topo da HUD (`Hud.set_banner`).

Desbloqueios (fase 6): `Unlocks` (`core/unlocks.gd`, funções estáticas) decide o que está liberado e grava chaves no `SaveService` (`color:<id>:<índice>`, `costume:<id>:<traje>`, `secrets:all`, `wardrobe:all`). O `DuelScreen` chama `Unlocks.after_duel_against_ai` quando o jogador vence a IA e junta `mode.unlock_messages()` (o Arcade chama `Unlocks.after_arcade`); os avisos vão ao resultado. `StatsTracker` conta também `aerial_hits`, `feints` e `responses` (fora da tabela). A abertura (`screens/opening/`) é a cena inicial e grava os segredos.

Tutorial, Treinos guiados, Desafio de parry e Desafios (fase 6):
- Lições são dados: `LessonData` (`data/lessons/*.tres`) com `LessonStep` (texto com marcadores de tecla como `{light_attack}`, objetivo, quantidade, comportamento do boneco). `DummyController` ganhou `HEAVY` (fortes em intervalos aleatórios, `TrainingConfig.heavy_interval_*`) e `MIRROR` (repete o tipo de ataque do jogador, para provocar a disputa).
- Objetivos (`presentation/objectives/`): `DuelObjective` (base: `on_tick`, `on_event`, `instruction`, `progress_line`, sinal `finished`), `LessonTracker` (avança os passos pelos eventos e troca o comportamento do boneco) e `ParryTracker` (45 s, parry 1, perfeito 2). O modo cria o objetivo em `create_objective(dummy)`; o `DuelScreen` alimenta-o e escreve a instrução na faixa do topo e o progresso acima do rodapé (`Hud.set_progress`); ao terminar, mostra o resultado.
- Modos: `LessonMode` (Tutorial e Treinos guiados; o Tutorial oferece o Desafio de parry no fim), `ParryChallengeMode` (recorde no `SaveService`), `ChallengeMode` com `ChallengeData` (`data/challenges/*.tres`: lutadores, arena, dificuldade, Poderes, vida inicial; recorde de menor tempo). O gancho `finish(winner, sim, seconds)` recebe a duração da luta.
- Menu: Aprender › Tutorial, Treinos guiados (subgrupo), Treino, Desafio de parry, Controles; Extras › Desafios (subgrupo), Galeria de poderes. Subgrupos têm `parent` e Voltar sobe um nível.

História (fase 7):
- Dados: `content/STORY.md` é a fonte; `tools/story/make_story.py` gera `data/story/encounters/*.tres` (`EncounterData` com `DialogueLine` antes e depois, filtradas pelo caminho), `data/story/endings/*.tres` (`EndingData`), `data/story/campaign.tres` (`CampaignData`: rotas, finais, opções de criação, poderes por caminho, pontos por dificuldade) e as falas em `strings.csv`. O gerador só substitui as linhas que são dele (`STORY_<encontro>_*` e `ENDING_*`); os textos de interface `STORY_*` ficam intactos.
- Estado: `StoryCampaign` (`core/story_campaign.gd`) é a campanha em andamento, gravada como dicionário em `SaveService.campaign`. Regras puras e testadas: próximo encontro, pontos por vitória e marcos, poderes aprendidos, espaços abertos, troca de poderes sem repetir, final normal ou secreto (vida acima de `secret_health_ratio` no último encontro). `protagonist()` monta um `CharacterData` duplicado do personagem-base do estilo com nome, atributos, cor, visual e poderes equipados; o recurso original não muda.
- Fluxo: Jogar › História → `story_hub` (ou `story_new` sem campanha) → `dialogue` (antes) → `StoryMode` (um round, Poderes ligados, dificuldade da campanha com o desvio do encontro, chefe com `awakening`) → resultado (`continue` ou `retry`/`story`) → `dialogue` (depois) → `ending` quando a campanha termina, senão o hub. Telas em `screens/story/`: hub, criação, atributos, poderes, diálogo, final e galeria.
- Desbloqueios: os encontros e finais gravam `character:<id>`, `ending:any`, `ending:secret`, `seen:encounter:<id>` e `seen:ending:<id>`. `Unlocks.is_costume_unlocked` libera os trajes Sentinela/História com `ending:any` e os do final secreto com `ending:secret`; a variante do Predestinado (Eclipse) na seleção exige `character:foretold_eclipse` ou o segredo Equilíbrio (`Unlocks.is_variant_unlocked`). A Galeria da História (Extras) lê as chaves `seen:*`.

Galeria de poderes (fase 5): `GalleryMode` monta um duelo sem rounds (`endless`, `free_powers`) com cópias do Guardião e da Sombra (as técnicas são trocadas na cópia, nunca no recurso original). O `DuelScreen` cria o `GalleryPanel` (`presentation/hud/gallery_panel.gd`), que fornece os dois controladores, recoloca a cena a cada demonstração (`restage`) e desenha o painel do topo. Poderes de alcance direto (`PowerData.targeted_reach`: Repulsão, Puxão pelo tier, Truque Mental, Repulsão Suprema, Congelar, Estrangular, Dreno, Raio) e técnicas corpo a corpo (alcance + avanço) aproximam os lutadores para `TrainingConfig.gallery_reach_ratio` desse alcance; projéteis e marcas ficam na distância do round. A próxima demonstração só começa `gallery_pause` depois de a atual terminar de fato (`GalleryPanel.demonstrating`: congelamento da cinemática, lançador lançando, atacando ou sem a lâmina, chuva, alvo preso, marcas ou projéteis ativos), com `gallery_max_time` como limite; antes, a Telecinese em Massa reiniciava antes de os pedaços caírem. Antes, a distância do round (394 u entre as bordas) deixava Dreno, Congelar, Truque Mental, Estrangular, a Repulsão e as técnicas sem alcance (`tests/presentation/test_gallery.gd`). Ações: `gallery_target` (T), `gallery_repeat` (R), `gallery_swap` (X); ← → trocam o poder, ↑ ↓ o tier, Enter lança de novo.

Implementação: `SceneRouter.change(id, params)` troca a tela com fade, **sem travar**: a cena é carregada numa thread (`ResourceLoader.load_threaded_request`) enquanto a tela escurece; se a tela tiver `required_resources(params)` (a seleção declara os personagens do elenco), esses recursos também carregam na thread e ficam segurados até o `open`; a tela nova só clareia depois de dois quadros desenhados sob o preto (compilação de shaders e envio de texturas). Antes, entrar na seleção ou no duelo parava a tela por 1,1–1,7 s; agora o pior quadro fica em ~120 ms, escondido pelo fade. `push`/`pop` empilham telas sobre a atual e pausam a árvore. Telas recebem os parâmetros em `open(params)`. Ids: `opening`, `menu`, `select`, `duel`, `pause`, `result`, `options`, `keys`, `controls`, `story_hub`, `story_new`, `story_attributes`, `story_powers`, `story_gallery`, `dialogue`, `ending`. O menu recebe `{"group", "focus"}` e guarda em variáveis estáticas o grupo e a opção de onde o jogador saiu; as Opções alteram o `Settings`, que aplica idioma, volumes por barramento (Master, Music; Effects, Blades, Ambience e Interface juntos) e vídeo em `Settings.apply()`. Modos: `DuelMode` (base: `build_setup()`, `result_options()`, `restart()`, `choose()`), `VersusMode` (Guardião contra Sombra na IA, dificuldade das configurações) e `TrainingMode` (boneco, regras `endless`, sem rounds). O menu tem a lista da fase 5 (Duelar, Treino, Galeria de poderes, Dificuldade, Sair) até o menu completo da fase 6, já com o visual final: `MenuEmblem` (`screens/menu/menu_emblem.gd`) desenha as lâminas cruzadas num `SubViewport` de pixel art (4 px de tela por pixel, fundo opaco para o brilho aditivo somar) atrás do título; o `MainMenu` reserva o espaço do emblema na coluna e passa o ponto de cruzamento a cada quadro. Cores no `UiPalette` (`menu_blade_a`, `menu_blade_b`, `menu_hilt`, `menu_horizon`).

## Serviços (autoloads)

- **`Settings`**: opções, idioma, bindings (arquivo `ConfigFile` em `user://`).
- **`SaveService`**: progresso (desbloqueios, recordes, campanha), com versão de formato e migração. Implementado na fase 6 (`core/save_service.gd`, `user://progress.cfg`, `FORMAT_VERSION`): Arcade concluído por personagem, recorde da Sobrevivência e do Desafio de parry, melhor tempo por desafio e chaves de desbloqueio (`unlock`, `is_unlocked`). Um arquivo de versão mais nova é ignorado, nunca sobrescrito pela leitura.
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
- O executor registra um `Logger` (Godot 4.5+): qualquer erro de script durante um teste faz o teste falhar, mesmo que nenhuma asserção tenha falhado. Um arquivo de teste que não compila (ou que depende de um script quebrado) conta como falha, e `tests/data/test_scripts_compile.gd` compila todo script do jogo (fora o addon), para uma quebra de compilação nunca passar despercebida.
- `tests/data/test_translations.gd` garante que todo texto de personagem e toda chave usada pelo código existe em português e em inglês.
- Matriz de equilíbrio: `godot --headless --path . --script res://tools/simulate.gd -- --matrix all --duels 10 --difficulty hard` imprime a taxa de vitória de cada personagem contra cada outro (lados alternados) e o total.
- `tools/headless_duel.gd` (`HeadlessDuel`) roda um duelo IA × IA sem tela; serve ao simulador e aos testes de IA.

## Exportação Web (GitHub Pages)

- Preset **Web** em `export_presets.cfg`, saída em `build/web/` (fora do git). **Sem threads** (`variant/thread_support=false`): o GitHub Pages não permite os cabeçalhos COOP/COEP que o `SharedArrayBuffer` exige; o PWA fica desligado.
- **Exclusões**: `addons/godot_mcp_toolkit/*`, `.mcp.json`, `tests/*`, `tools/*`, `.preview/*`, `build/*`. O plugin de exportação do próprio addon (`core/export_strip.gd`) anula o autoload `MCPRuntimeServer` durante a exportação e o restaura depois; o autoload também se desliga sozinho fora do editor. Nada do jogo referencia o addon, os testes ou as ferramentas. No pacote fica só o texto da configuração `editor_plugins/enabled`, ignorado em runtime.
- **Carregamento**: sem threads, `load_threaded_request` carrega na thread principal; o `SceneRouter` detecta a feature `nothreads` e só pede a cena depois que a tela escurece, para a espera ficar sob o fade.
- **Áudio**: `audio/general/default_playback_type.web=0` (Stream). O modo Sample, padrão da Web, não toca a música em camadas (`AudioStreamSynchronized`) nem aplica os filtros de abafar dos barramentos. Em build sem threads o mixer roda na thread principal: pode chiar se o quadro pesar.
- **Gráficos**: tudo roda no Compatibility (WebGL 2): `pixel_upscale.gdshader` usa `fwidth` (GLSL ES 3.0), o material dos lutadores usa um array de 8 cores, a dessaturação lê a tela (`hint_screen_texture`), as lâminas usam `PointLight2D` com mapas de normal e o duelo usa o glow do `WorldEnvironment`. As luzes são o maior custo de GPU.
- Tamanho: `index.wasm` ~39 MB (motor), `index.pck` ~2,7 MB (jogo).
- **Perfil gráfico da Web** (`EffectsConfig`, grupo Web): sem o glow do `WorldEnvironment` (`web_glow = false`) e luzes das lâminas com alcance menor (`web_light_scale` 1,6 em vez de 2,8). Medido no Chrome (puppeteer, contagem de `requestAnimationFrame`, GT 730): Galeria de poderes de 14–21 para 45–58 FPS; duelo a 1280×720 de 14–34 para ~48 FPS. O GDScript da apresentação gasta menos de 1 ms por quadro no desktop (simulação e IA 0,14 ms, os dois lutadores 0,37 ms), então o custo na Web é de GPU/WebGL. No desktop nada muda.
- **Replay sem pico**: a re-simulação do replay do golpe final avança `replay_ticks_per_frame` (240) ticks por quadro em vez de tudo de uma vez.
- `ControlHints` não converte tecla física para o layout na Web (o `DisplayServer` da Web não suporta e registrava erro a cada dica).
- **Recursos em texto na exportação** (`editor/export/convert_text_resources_to_binary=false`): com a conversão para binário ligada (padrão da Godot), a build exportada da 4.7.2 perdia as propriedades `PackedStringArray`/`PackedColorArray` dos recursos (`FighterArt.default_parts` vazio, `UiPalette.flow_tiers` nulo): sumiam capas, cabelos, capuzes, ombreiras e as cores de tier. Os `.tres` vão em texto; o pacote fica do mesmo tamanho. Para conferir uma build, rode o pacote com `godot --main-pack build/check/game.pck` (ver README).

## Desempenho

- 60 FPS estáveis. Nada de alocação por tick na simulação; pools na apresentação.
- Medir com o profiler da Godot em cada fase, nas arenas mais pesadas (reflexo, chuva, Tempestade) e com dois lutadores detalhados.
- Verificação do renderer concluída na fase 3: glow em LDR, `PointLight2D` com mapas de normal e reflexo desenhado (não por cópia de tela) funcionam no Compatibility.
- Arte e áudio são gerados offline; o jogo só carrega PNG e WAV.
- **Medição na grade de pixels** (segunda etapa da migração, duelo IA × IA de 20 s com poderes, Guardião × Sombra e Soberano × Ancião): sem renderização (headless), ~130 FPS e 7,6 ms por quadro, então a CPU (simulação, IA, poses, tecidos, efeitos) cabe com folga em 60 FPS. Com renderização, numa GeForce GT 730 com o editor aberto, entre 28 e 55 FPS, com variação grande entre execuções iguais; ~250 chamadas de desenho por quadro. O custo de GPU vem sobretudo das duas `PointLight2D` das lâminas, que no Compatibility redesenham cada item que alcançam: as camadas distantes da arena (`lit_by_blades = false` em `refinery_layer.gd`) e o céu da Tempestade ficam fora da máscara de luz. Falta medir numa GPU de referência, com o editor fechado.
