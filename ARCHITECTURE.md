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

### Núcleo de Infiltração (task 10)

Módulo separado, sem adaptar `MatchSimulation` nem `FighterState` ao plano superior. `simulation/infiltration/` contém `InfiltrationSimulation`, estado de atores, projéteis/eventos em pools e geometria de grade/setor/percurso. `InfiltrationIntent` contém movimento e mira `Vector2` e bits de `Intent.Command`; somente o controlador os produz. Passo fixo usa `Ticks.DELTA`, sem física de nós nem `delta` real. `capture`/`restore` e hash de estado incluem vida, Vigor, janelas, golpe, temporizadores de alvos, tiros e tick. Nenhum objeto novo por tick.

`data/infiltration/` contém mapa de linhas de tiles e `InfiltrationTargetData` (boneco ou emissor, posição, direção, vida, BoltData e cadência). `data/balance/infiltration_config.tres` centraliza movimento, alcance/setor, tempos, medidores, pools e apresentação. O Resource de mapa é fonte única de colisão/desenho; limites fora da grade são sólidos. Emissores não são IA de patrulha: disparam numa direção fixa para prática, e alvos destruídos reaparecem por dado. A task 11 acrescenta os inimigos descritos abaixo; missões entram na task 12.

`controllers/infiltration/` tem o controlador de jogador; `core/infiltration_bindings.gd` instala ações no namespace `infiltration_*` copiando os bindings atuais do J1, acrescenta eixos verticais e de mira e os botões do mouse, e remove apenas essas ações ao sair. InputMap do duelo fica intacto. Mira da tela é só dado de entrada (posição do cursor projetada no mundo); regras continuam no núcleo. Intenções podem ser produzidas por testes sem Input.

`presentation/infiltration/` desenha a grade pelo atlas, sprites superiores, lâmina, tiros, faíscas em pool e debug; só lê estado/eventos. Usa `PixelStage` e uma `Camera2D` própria seguindo o jogador, sem alterar o rig do duelo. `screens/infiltration/` monta o treino, executa acumulador fixo limitado, HUD e pausa local; navegação externa só pelo `SceneRouter` (rota `infiltration_training`). Não grava campanha, recordes ou desbloqueios. A pausa descarta comandos pendentes para não disparar ao voltar.

A fatia ativa do corte é calculada pelo tick em `InfiltrationSimulation._resolve_swing`; alvo alcançado guarda `last_swing_id`, sem lista alocada por golpe. Colisão de corpos faz clipping por eixo e disparos usam segmentos contra AABBs expandidos, dando prioridade à primeira parede. Setor de guarda lê a direção de chegada do disparo, inclusive quando o emissor está encostado. Parry usa `CombatConfig.parry_window`, `perfect_parry_window` e `parry_lockout`; a devolução preserva o emissor original. Mapa é desenhado por `InfiltrationMapView` estático, e `InfiltrationView` atualiza apenas atores/tiros/efeitos. O gerador de arte é idempotente por hash, e não depende de amostras externas.

Compartilhados com o duelo: `Ticks`, bits de comandos de `Intent`, InputMap/bindings do J1, números de parry do `CombatConfig` e `BoltData` padrão, tema/`UiPalette`, atlas na mesma grade, `AudioDirector`/banco original e `SceneRouter`. `SaveService` permanece disponível para capturas isoladas e futura progressão, sem escrita no treino. Resolvedores do duelo e seu `TickRunner` não são modificados. O gerador `tools/art/make_infiltration_tiles.py` lê a paleta central, produz atlas/sprites determinísticos e tem os outputs registrados em ASSETS.

### Patrulhas, percepção e alarmes (task 11)

Arquétipos `InfiltrationEnemyData` estendem os dados de alvo; `InfiltrationEnemyPlacement` separa posição/rota/reserva do arquétipo. A simulação mantém uma lista unificada de dados e corpos (alvos de treino seguidos dos inimigos), incluindo slots de reforços pré-alocados, inativos até entrada. IDs de projétil/evento continuam índice + 1; snapshots restauram o BoltData pela lista unificada. O disparo preserva também a origem da devolução: dano avisa o inimigo desse ponto, sem revelar a posição atual escondida do jogador. Entrada de reforço testa AABBs, incluindo sobreposição diagonal.

`InfiltrationPerception` resolve visão/memória/audição no tick. A tela cria `InfiltrationEnemyController` fora da simulação, com intenções e navegador pré-alocados. Antes de cada tick, `produce_all` lê o mesmo estado anterior para todos os inimigos e produz suas intenções (movimento, mira, tiro e pedido de painel), sem modificar atores. `InfiltrationSimulation.step(player_intent, enemy_intents)` só aplica entradas; sem entrada inimiga, os corpos ficam parados. A simulação valida consciência e linha de visão ao aceitar tiro/alarme, inclusive intenções antigas ou inválidas. `InfiltrationNavigation`, pertencente ao controlador, faz busca em largura determinística com buffers de grade reutilizados; nenhuma física de nós. A simulação aplica movimento, avança rota e resolve pedidos, dano e temporizadores. Estado de consciência, último ponto, rota, decisão, painel e reforços faz parte do snapshot. Painéis têm dados no mapa e estado próprio. Eventos de ruído são resolvidos na simulação, não pelo áudio. A tela e a vista só apresentam esses estados/eventos; controles reutilizam forte para abate e Poder para interação sem alterar ações do duelo.

### Missões de Infiltração (task 12)

`InfiltrationMissionData` em `data/infiltration/` descreve mapa, terminais, prisioneiros, extração, bônus e textos; quatro recursos em `missions/`. `InfiltrationMissionState` mantém objetivos, recrutamento, histórico de alarme/abates e resultado selado, com snapshot/restauração. `InfiltrationSimulation` recebe missão opcional e intenções de escolta, resolve disparos contra prisioneiros e avança objetivos após o combate. Treino sem missão conserva seu comportamento. `InfiltrationEscortController` lê o estado anterior, reutiliza navegação e produz só intenções; nenhum nó participa das regras.

`InfiltrationMode` reúne o catálogo e sela a gravação após sucesso. `SaveService.infiltration_best` guarda ticks mínimos e máscara acumulada de bônus, com migração por ausência. Rotas `infiltration` (lista/briefing), `infiltration_mission` (tela superior compartilhada) e `infiltration_result` (objetivos e continuação) passam somente dados/modo pelo SceneRouter. Retry cria simulação e controladores novos. Resultado não avança ticks e não regrava. A rota técnica do treino continua disponível para verificações, sem entrada no menu.

### Duelo

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
| Finalizações cinematográficas | `Finisher.Kind` (`data/finisher.gd`) em `MoveData.cinematic_finisher` e `PowerData.finisher` (mais `execute_below` no Puxão). `MatchSimulation.kill(victim, killer, move, power, thrown)` decide pelo `Consequences.finisher_for` (só no K.O. decisivo, com `rules.finishers`), grava `FighterState.finisher_kind`, `CombatEvent.finisher` no `DEATH` e `cinematic_ko` (alonga a fase `KO`). O poder que matou vem do `PowerHit` ou do Estrangular; a lâmina arremessada e a onda do Corte Projetado vêm do `ProjectileSystem` como `thrown`. Durante as fases `KO` e `OVER`, `ProjectileSystem.drift` continua o voo dos projéteis sem colisões, para a lâmina que matou voltar à mão; o replay do golpe final só termina depois de `replay_tail` e com a lâmina de volta (`DuelScreen._replay_done`, limite `CombatConfig.replay_blade_return_limit`), senão a lâmina ficava girando parada atrás do resultado. A apresentação (`FinisherDirector`, `BodySplit`) é o bloco B do plano |
| `simulation/rules/match_rules.gd` | capacidades por modo: `rounds_to_win`, `exhaustion`, `wounds`, `blade_lock`, `finishers`, `endless` |

Decisões:

- **Ordem do tick**: buffer de entrada dos dois → estado de cada lutador (com integração física) → corpos e paredes → virar de frente → choque de lâminas → acertos → disputa de lâminas → fim de round. O choque é resolvido antes dos acertos (tem prioridade). Os acertos dos dois lados são coletados antes de aplicados, para a troca simultânea valer.
- **Janela de choque**: `ClashResolver._in_clash_window` aceita ativo ou os últimos `CombatConfig.clash_window` (0,067 s = 4 ticks) da preparação, exigindo ao menos um ativo. Mantém orientação, geometria e golpe não consumido. O choque leve marca ambos conectados/consumidos e passa os dois à recuperação; choque pesado, técnicas e disputa saem do estado de ataque e `AttackState.exit` limpa o golpe. Nenhuma regra de lição: o `MIRROR` continua percebendo o ataque um tick depois. O simulador imprime contagens inteiras de acertos, choques, disputas e pressões, inclusive na matriz.
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
- **Árvores da História**: `core/story_power_tree.gd` resolve os recursos e estados de Poderes e Lâmina sem depender da UI. Compra por pontos, requisitos, migração e equipamento estão descritos em “Pontos e árvores da História” e “Árvore de Lâmina”, ao fim deste documento. `screens/story/story_powers.gd` desenha os dois grafos e compartilha detalhe/seletor; tema, paleta e localização são centrais.
- **`BladeView`**: camadas da lâmina, luz, rastro, ignição, apagar, tremulação.
- **`EffectsDirector`**: receitas de efeito por evento, com pools de partículas e luzes; respeita "efeitos reduzidos".
- **`CameraRig`**: enquadramento dos dois lutadores, punch-in, tremor, mini-cinemáticas de poder, letterbox.
- **`Hud`**: barras, marcas, rounds, mensagens; lê estado e eventos.
- **`StatsTracker`**, objetivos do tutorial e desafios: escutam eventos.
- Debug **F3**: hitboxes, hurtboxes, colisão de lâmina, estado, fase, Vigor, Fluxo, intents, decisões da IA, FPS, tick.

### Introdução dos lutadores

`CharacterData.intro` aponta para `IntroData` (`data/intros/`), que estende `PoseTrack` (`data/pose_track.gd`: chaves, mistura final e entrada suave opcional); `PoseKey` (`data/pose_key.gd`) descreve empunhadura, ângulo, giro, tronco, cabeça e mão livre. São dados de apresentação, sem colisão ou efeitos na simulação. O protagonista herda a entrada do estilo escolhido; as variantes do Predestinado compartilham a entrada e assentam na própria guarda.

`MatchRules.fighter_intros` fica desligada por padrão. Duelar, Arcade, História, Sobrevivência e 2 Jogadores copiam `Settings.fighter_intros` ao montar a partida; os modos de aprendizado e demonstração não a habilitam. Só o primeiro round usa `CombatConfig.match_intro` (3,6 s); o título ocupa `match_intro_title` (1 s) ao final. Os demais usam `round_intro` (1,6 s). O solver mistura a última chave com a guarda da família durante `blend_time`, antes do título. A câmera mantém os dois lutadores enquadrados.

Pular é entrada determinística: `Intent.skip_intro` ocupa o bit 18 no empacotamento, preservando os oito bits dos comandos existentes. `PlayerController` converte `ui_accept` nesse pedido apenas durante INTRO. A simulação também aceita toques de rápido, forte, habilidade e poder de qualquer lado; avança o mesmo relógio compartilhado até o título e ignora comandos de combate durante todo tick iniciado em INTRO, inclusive o tick de FIGHT_STARTED. Não pula o título, não guarda ataque no buffer e não altera o relógio novamente se já chegou ao título. Snapshot guarda esse relógio; gravação e replay carregam o pedido empacotado, sem atalho externo à simulação.

`FighterView` lê o relógio de INTRO para pose, duas ignições e acessórios; `DuelAudio` acompanha cada início de ignição usando o som existente. O capuz temporário desce em etapas; a capa temporária se solta e desaparece em degraus antes do título. Trajes que já têm essas peças as preservam. Ao pular ou sair de INTRO, os acessórios temporários são removidos e a guarda é aplicada imediatamente. F3 informa tempo da introdução, ignições e acessórios. A opção usa `game/fighter_intros` em `settings.cfg`, ligada por padrão inclusive em saves antigos.

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
  - **Técnicas**: `MoveData.technique_style` (dado do golpe) escolhe a pose própria (Avanço, Arremesso, Estocada, Corte ascendente, Rajada, Investida da Haste `LUNGE`, Investida descendente `PLUNGE`); `ARC` usa o arco genérico. O estilo vale para qualquer golpe, não só técnicas: a habilidade da Haste e do Soberano usa `LUNGE`. A Varredura foi removida na fase 7.5 (técnicas substituídas pelo Corte ascendente na Brasa, Giro no Eco e Avanço com corte no Predestinado Eclipse; `stagger_on_guard` saiu junto). O Giro preenche `RigPose.turn`, que o `FighterView` aplica como escala horizontal do rig; a lâmina usa o vetor transformado sem normalizar antes de medir, para encurtar em escorço. `RigPose.open_hand` troca a textura da mão livre por `hand_open`. O teste de sincronia cobre as técnicas, menos Arremesso (projétil) e Giro (acerta dos dois lados).
  - **Empunhadura por família** (fase 7.5): `MotionFamily.back_hand_spacing` (mão de trás no cabo; o Guardião segura no pomo), `free_hand` (mão livre nas empunhaduras de uma mão), `off_guard_hand`/`off_guard_angle` (segunda lâmina da Vespa em guarda), `wrist_lag` (cadeia ombro → cotovelo → punho: o corpo avança cedo, `SHOULDER_LEAD`, e o ângulo da lâmina chega por último), `recover_share` (rapidez da volta à guarda) e `one_hand_follow` (solta a mão de trás no follow-through do forte). A Haste usa as duas mãos na haste em qualquer família. A Vespa alterna as lâminas pelos passos da sequência (`_place_second_blade`); o teste de sincronia aceita a segunda lâmina nas armas duplas.
  - **Tipos de corte** (fase 7.5): `MoveData.cut` (`DESCENDING`, `RISING`, `HORIZONTAL`, `THRUST`, `SPIN`) escolhe os pontos de preparação e de impacto da mão (`CUT_WINDUP`, `CUT_STRIKE`, escalados pela família); `HORIZONTAL` e `SPIN` torcem o corpo com `RigPose.turn` (`_cut_turn`). `tests/data/test_cuts.gd` exige um tipo por passo, sem repetir na sequência, e forte descendente ou giro (ascendente só no Golpeador).
  - **Guarda responsiva**: `PoseSolver` possui um `GuardTracker` reutilizado. Entradas: postura/envelope/frequência/recuo da `MotionFamily`, estado e altura relativa do rival, geometria prevista do `MoveData`, segmento desenhado observado pelo `FighterView.rival` (referência somente de apresentação ligada pelo `DuelScreen`) e impulsos dos eventos de bloqueio/parry. Saídas: empunhadura, ângulo, inclinação e dados F3. O segmento entra no espaço local dos pés e é convertido ao corpo, com escala e espelhamento; a previsão cede gradualmente ao segmento vivo. Uma mola amortecida preserva posição e velocidade entre golpes; durante BLOCKING o view aplica sua saída diretamente, seguida pela IK comum. Sem rival utilizável, `threat_line` usa as poses de fallback nos dados da família. Nenhuma escrita na simulação. Vespa escolhe a lâmina da mão que ataca e cruza a segunda contra fortes; bastão/haste em guarda oferecem o segmento do cabo. Faíscas continuam em `EffectsDirector._blade_contact`, usando os segmentos reais, com fallback à posição do evento quando distantes.
  - **Marcação visual do contato**: `MotionFamily.release_start` e `contact_swing` remapeiam continuamente o final da preparação e o arco ativo, para a lâmina já estar avançada quando a simulação emite o bloqueio. Não alteram o relógio, a fase real ou o início do rastro; Arremesso mantém a marcação própria. A apresentação não modifica o `FighterState`.
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
- **Finalizações cinematográficas** (fase 8): o `FighterView` cria um `FinisherPlayer` (`presentation/fighters/finisher_player.gd`) no `DEATH` com `event.finisher`. Nos cortes, ele cria uma segunda `FighterRig` na mesma pose e liga em cada uma o plano de corte do `fighter_material.gdshader` (`clip_enabled`, `clip_point`, `clip_normal` no espaço do mundo, recalculados a cada quadro pela transformação de cada metade); move as metades antes do `apply`, para os tecidos acompanharem; desenha a borda em brasa, a fumaça e as brasas. Raio usa os parâmetros `xray` e `charred` do shader e `FighterRig.skeleton_lines()`; a Repulsão arremessa o rig inteiro. Quem corta recebe `PoseSolver.finish_hold_left` e, no Avanço com corte, um `SlashStreak` (`presentation/effects/slash_streak.gd`). Desligado pela opção Finalizações (`show_finishers`).
- **Finalizações em etapas** (`Finisher.STAGED`: execução, tesoura, estocada, duas lâminas, execução por cima, giro duplo, giro). Cinco camadas separadas:
  - **Regra (simulação)**: qual finalização (`MoveData.cinematic_finisher`, troca das duas lâminas por execução sem lâmina simples na vítima), posição no instante da morte (`MatchSimulation._hold_in_front`, `_pass_behind` no giro com a virada para a vítima), duração do K.O. (`cinematic_seconds`, `long_cinematic`) e do replay (`long_replay_tail`). Nada da apresentação entra aqui.
  - **Coreografia** (`FinisherMotion`, `data/finishers/<kind>.tres`, estende `PoseTrack`): poses-chave de quem corta (`PoseKey`, com `accent` para o estilo), passagem por trás (`travel_from`, `travel_to`) e a lâmina emprestada (`pull_at`, `catch_at`, `release_at`).
  - **Reação da vítima** (`FinisherReaction`, sub-recurso): antebraços, cabo que cai, ajoelhar, cabeça, corte vertical, queda e empurrão.
  - **Efeitos** (`FinisherEffects`, sub-recurso): instantes dos rastros, rastro nas duas lâminas, anel da estocada. Cores e contagens continuam em `EffectsConfig` e `UiPalette`.
  - **Áudio** (`FinisherCue`, lista no `FinisherMotion`): instante e som do banco; o `FighterView` de quem corta emite `finisher_cue` e o `DuelAudio` toca.
  O estilo do personagem (`CharacterData.finisher_style`, `FinisherStyle` em `data/finisher_styles/`) muda ritmo, tronco, passo, alcance e acentos; `FinisherMotion.for_kind(kind, style)` devolve uma cópia estilizada (em cache) com todos os instantes das cinco camadas esticados juntos, então quem corta e a vítima ficam no mesmo passo e o recurso base não muda. Na apresentação, o `PoseSolver` toca entrada e finalização pela mesma rotina (`_stage`, `_stage_off_hand`, entrada suave por `lead_in`). O `FighterView` de quem corta toca a coreografia (`start_motion`), desenha os `SlashStreak`, emite as deixas, faz a passagem por trás (deslocamento visual que some até `travel_to`, desenho atrás da vítima e a virada escondida no meio da pirueta) e, nas duas lâminas, puxa o `LooseHilt` do `FighterView` rival (`rival`, ligado pelo `DuelScreen`) e acende a lâmina emprestada (segunda lâmina do `BladeView` com `second_color`, cabo emprestado no `HiltView`). O `FinisherPlayer` da vítima dispara a reação pelo próprio relógio (`_fire`), com o estilo de quem matou. Os relógios usam o mesmo `delta` da apresentação, então ficam juntos também no replay. `FighterRig.sever` acumula cortes até `restore()`. F3 mostra a finalização, o tempo de quem corta, a lâmina emprestada e o ajoelhar (`FighterView.finisher_debug_line`).
- **Próteses**: o `FighterView` guarda os membros perdidos em K.O.s anteriores e, no `reset_round`, chama `FighterRig.set_prosthetic(limb, front)`, que troca o material das peças pelo `prosthetic_material` (o mesmo shader com `prosthetic = true`). `set_flash`, `set_clip`, `set_charred` e `set_xray` atualizam os dois materiais.
- `CutMarks` (`presentation/fighters/cut_marks.gd`, no rig): tampa em brasa e fumaça do coto, talho do ferimento e brasas, recalculados a cada quadro pelas posições dos ossos. `FighterRig.sever(limb, front)` esconde as peças do lado cortado; a queda varia pelo `FighterState.finisher_limb`. O membro dos rápidos vem de `Consequences.struck_zone`: altura de passagem do corte (`ConsequenceConfig.cut_heights`, pelo `MoveData.cut`) somada à altura de quem ataca e comparada com os pés da vítima (`head_line`, `leg_line`); a cabeça vira braço fora do K.O. decisivo.
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

### Caçada a chefes (task 09)

`data/hunts/` reúne `HuntData`, `HuntPhase` e `HuntCondition` e as três missões. Narrativa em `content/HUNTS.md`. `HuntMode` monta cópias do elenco com kit fixo e cria `HuntTracker` (`modes/objectives/`, lógica sem nós): lê eventos e vida por tick, aplica conjuntos por `equip_powers`, níveis por `set_flow_level` e medidor da fase limitado por `FlowConfig.maximum`. Perfis inteiros por fase são overrides locais, nunca alteram recursos de personagem. `HuntController` estende a IA e só produz intenções, lendo o índice de fase do tracker e priorizando o poder de abertura até seu evento ativo. O tracker não referencia controladores. A troca espera invocação/canal, chuva, marcas e massa da Singularidade terminarem. Não há ciclo de referências nem alocação por tick na progressão.

`TickRunner.objective` alimenta o objetivo com todos os eventos e depois `on_tick`, no passo fixo, antes dos sinais de apresentação. Os objetivos de lição mantêm a mesma ordem. `DuelObjective.announced` comunica a transição ao HUD sem inserir regras na tela; o anúncio é apresentado no `ticked`, depois do evento `FIGHT_STARTED`, que encerra o título do round. `DuelMode.create_ai` permite o controlador especializado. `create_replay_objective` cria um tracker independente, reexecutado desde o snapshot inicial tanto no avanço rápido quanto no replay; o tracker original e o resultado ficam intactos. Não se alteram as regras do combate comum.

Na conferência da transição foi corrigido o layout das barras existentes do `ScreenEffects`: `set_anchors_preset` preservava um retângulo de largura zero; `set_anchors_and_offsets_preset` faz as barras ocuparem o viewport. A correção também recupera o letterbox já previsto para intro, K.O., despertar e replay. Cores e durações permanecem nos recursos existentes.

Rota `hunts` (`screens/hunts/`) apresenta lista, briefing, recordes e epílogos desbloqueados. Variações `HuntBodyLabel`, `HuntSubtitleLabel` e `HuntHintLabel` no tema central mantêm 28 px no cartão. A rota `dialogue` aceita um `HuntMode` e usa os mesmos `DialogueLine`, cenário e lutadores; o modo decide a continuação pelo roteador. `SaveService.hunt_best` registra conclusão e menor tempo; chaves de desbloqueio existentes concedem cosméticos uma única vez. Campos ausentes em saves da versão 1 começam vazios. O modo sela o resultado uma vez por tentativa e só salva após vitória com condição cumprida.

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
- Aparência do protagonista (fase 8): `CampaignData.outfits` (trajes em `data/story/outfits/*.tres`), `hair_styles`, `beard_styles`, `hair_colors`, `skin_tones`; `StoryCampaign.hair`, `beard`, `hair_color`, `skin` (com padrão para saves antigos) e `appearance()`, que duplica o traje, troca os slots de cabelo e pele, esconde o cabelo e a barba da base e mostra as peças escolhidas. O `FighterRig` cria sprites para todas as peças `hair_*` e `beard_*` da arte e para `plate`, opcionais como as outras. `CostumeData.prosthetic_arm` liga o antebraço protético num traje (Predestinado Caído e Duelo).
- Estado: `StoryCampaign` (`core/story_campaign.gd`) é a campanha em andamento, gravada como dicionário em `SaveService.campaign`. Regras puras e testadas: próximo encontro, pontos por vitória e marcos, poderes comprados, espaços abertos, troca de poderes sem repetir, final normal ou secreto (vida acima de `secret_health_ratio` no último encontro). `protagonist()` monta um `CharacterData` duplicado do personagem-base do estilo com nome, atributos, cor, visual, poderes equipados e kit de lâmina comprado; o recurso original não muda.
- Fluxo: Jogar › História → `story_hub` (ou `story_new` sem campanha) → `dialogue` (antes) → `StoryMode` (um round, Poderes ligados, dificuldade da campanha com o desvio do encontro, chefe com `awakening`) → resultado (`continue` ou `retry`/`story`) → `dialogue` (depois) → `ending` quando a campanha termina, senão o hub. Telas em `screens/story/`: hub, criação, atributos, poderes, diálogo, final e galeria.
- Desbloqueios: os encontros e finais gravam `character:<id>`, `ending:any`, `ending:secret`, `seen:encounter:<id>` e `seen:ending:<id>`. `Unlocks.is_costume_unlocked` libera os trajes Sentinela/História com `ending:any` e os do final secreto com `ending:secret`; a variante do Predestinado (Eclipse) na seleção exige `character:foretold_eclipse` ou o segredo Equilíbrio (`Unlocks.is_variant_unlocked`). A Galeria da História (Extras) lê as chaves `seen:*`.

Exibição (Extras): `ExhibitionMode` (`modes/exhibition_mode.gd`) lê `data/exhibition/exhibition.tres` (`ExhibitionData` com `ExhibitionBout`s) e monta um `DuelSetup` por duelo: personagens, trajes, arena, poderes de cada lado (`power_sets`), vida inicial (`MatchRules.start_health`), `free_powers`, um round, entradas, e os dois controladores `ControllerKind.CHOREOGRAPHY`. O `ChoreographyController` (`controllers/choreography_controller.gd`) só produz intenções: a cada tick depois do `FIGHT`, aplica os `ExhibitionCue` do seu lado (`at` em ticks desde o início da luta, `command` em bits de `Intent.Command`, `move` relativo à frente, `hold` em ticks). Como a simulação é determinística, o duelo sai igual sempre; `tests/modes/test_exhibition.gd` roda cada duelo sem tela e exige os momentos e a finalização de cada um, então uma mudança de equilíbrio que quebre a coreografia aparece no teste (ajustar os ticks em `exhibition.tres`). O `DuelScreen` com `setup.bout` esconde o HUD, mantém o letterbox, mostra o `ExhibitionCard` (`presentation/hud/exhibition_card.gd`: título, lutadores e dica do rodapé, tempos no próprio `ExhibitionBout`) e, no fim da partida ou ao confirmar, chama `DuelMode.after_match()`: o modo da exibição abre o próximo duelo pelo `SceneRouter` (o fade é a transição) ou volta ao menu. Os outros modos devolvem `false` e seguem o fluxo normal (replay e resultado).

Galeria de poderes (fase 5): `GalleryMode` monta um duelo sem rounds (`endless`, `free_powers`) com cópias do Guardião e da Sombra (as técnicas são trocadas na cópia, nunca no recurso original). O `DuelScreen` cria o `GalleryPanel` (`presentation/hud/gallery_panel.gd`), que fornece os dois controladores, recoloca a cena a cada demonstração (`restage`) e desenha o painel do topo. Poderes de alcance direto (`PowerData.targeted_reach`: Repulsão, Puxão pelo tier, Truque Mental, Repulsão Suprema, Congelar, Estrangular, Dreno, Raio) e técnicas corpo a corpo (alcance + avanço) aproximam os lutadores para `TrainingConfig.gallery_reach_ratio` desse alcance; projéteis e marcas ficam na distância do round. A próxima demonstração só começa `gallery_pause` depois de a atual terminar de fato (`GalleryPanel.demonstrating`: congelamento da cinemática, lançador lançando, atacando ou sem a lâmina, chuva, alvo preso, marcas ou projéteis ativos), com `gallery_max_time` como limite; antes, a Telecinese em Massa reiniciava antes de os pedaços caírem. Antes, a distância do round (394 u entre as bordas) deixava Dreno, Congelar, Truque Mental, Estrangular, a Repulsão e as técnicas sem alcance (`tests/presentation/test_gallery.gd`). Ações: `gallery_target` (T), `gallery_repeat` (R), `gallery_swap` (X), `gallery_finisher` (F); ← → trocam o poder, ↑ ↓ o tier, Enter lança de novo. Demonstração de finalização: com `gallery_finisher` ligado e a entrada com finalização (`GalleryPanel.has_finisher`: `PowerData.finisher` ou `MoveData.cinematic_finisher`), o `_stage` liga `MatchRules.endless_finishers`, põe o alvo em `TrainingConfig.gallery_finisher_health` e o deixa parado (`GalleryTarget.finishing`). Na simulação, essa regra tira o piso de vida e a recarga do modo sem fim, libera a execução do Puxão e faz `is_deciding` valer sempre; com `endless`, o K.O. não soma vitória e `_after_ko` sempre recomeça o round (sem `MATCH_ENDED`). O painel detecta o round novo e repete a demonstração se a repetição estiver ligada.

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

### Corte Projetado e seleção de técnicas

`MoveData.TechniqueStyle.WAVE` lança um projétil CLEAVE no primeiro tick ativo; velocidade, tamanho e alcance ficam no MoveData. O projétil referencia o golpe, resolve dano de Lâmina, guarda e finalização pelo caminho físico, sem desarmar o lutador. O parry perfeito troca o dono e a cor; o Arsenal intercepta. O valor 12 do enum PowerData.Kind fica reservado como `UNUSED_FLOW_CLEAVE` para preservar os inteiros dos recursos. Saves descartam ids de poderes desconhecidos. A seleção edita também os três espaços de técnicas; duplica CharacterData apenas para o duelo, sem alterar o elenco ou salvar conjuntos personalizados.

`MoveData.follow_up` encadeia um segundo golpe: `AttackState._try_chain` o inicia quando há Especial no buffer durante o golpe, com `chain_index + 1` (a pose do segundo corte lê esse índice para girar a lâmina de volta). O segundo corte é `data/techniques/projected_cut_follow.tres`, sem `follow_up`, então são no máximo dois. `MoveData.projectile_tier_scales` dá a escala do projétil por tier de Fluxo de quem lança (`projectile_scale(tier)`); `PowerView` escala a onda pela razão entre `Projectile.size` e `projectile_size`. A IA decide no início da técnica se fará o segundo corte (`technique_bias`, Vigor para os dois). A Galeria demonstra os dois.


### Pontos e árvores da História

`data/story/story_tree_node.gd` é um Resource tipado por preload (`CampaignData.TreeNodeData`), sem classe global nova. `CampaignData.aurora_tree` / `eclipse_tree` guardam poder, custo, índice do pai e ramo. O gerador `tools/story/make_story.py` lê a tabela de progressão em STORY.md para gerar esses nós. Encontros deixam de carregar poderes como recompensa. `StoryCampaign.learned` significa comprado, preservando saves; `skill_points` é separado de `free_points`. `buy` valida a identidade do nó, caminho, pai e saldo; o tier só limita equipamento. `award_points` concede por duelo, inclusive derrota/repetição; `StoryMode.finish` garante uma concessão por partida e salva em ambos os resultados. Marcos ainda abrem os espaços de poder ao vencer. `StoryPowerTree` calcula estados e equipamento sem nós de UI; `story_powers` só apresenta e pede operações à campanha. Saves antigos começam com saldo zero e conservam poderes conhecidos; equipamento é normalizado pelo catálogo, tier e espaços abertos. Instinto Superior e Singularidade Devastadora serão acrescentados pelas tasks 04/05 quando seus recursos existirem.


### Árvore de Lâmina

O mesmo `story_tree_node.gd` identifica poderes, referências de técnica/habilidade e resoluções de espaço do estilo. `CampaignData.blade_tree` contém cinco nós e custos, independentes do estilo. `style_character()` só duplica a base quando falta um espaço, aplicando os complementos de técnica guardados no CampaignData; MoveData/AbilityData são referências aos recursos existentes. `StoryCampaign.blade_bought` e `projected_cut_slot` persistem compras e substituição; ausência da chave na migração concede os quatro nós antigos. `protagonist()` remove os espaços não comprados e a habilidade; `directional_ability_fallback = false` impede que o comando de um espaço vazio use a habilidade. O elenco mantém o comportamento padrão. Toda técnica usada no ar conta no limite de ataques por pulo, mesmo quando seu MoveData também permite uso no chão. `StoryPowerTree` recebe a aba e resolve nomes, ícones, recursos, estado, compra e equipamento para as duas árvores. A tela mantém um grafo por aba e compartilha o detalhe/seletor. `MoveData.icon` e `AbilityData.icon` são preenchidos pelo gerador de glifos nos recursos que os usam, sem catálogo paralelo.

`InputBindings.MENU_NAVIGATION_BUTTONS` completa as ações ui_* com confirmar/voltar/D-pad para todos os gamepads, preservando as teclas e evitando eventos duplicados ao reaplicar os padrões. Nenhuma tela lê botões físicos.

### Instinto Superior (task 04)

PowerData.Kind.HIGHER_INSTINCT é acrescentado ao fim do enum. FighterState guarda timer, referência ao poder, janela de resposta e variante/tempo da esquiva; o snapshot automático já inclui esses campos. HitResolver consome acertos corpo a corpo elegíveis antes de guarda/armadura, emite EVADE_SUCCESS com power e motion e reaproveita o fluxo da esquiva. ActionStarter usa a janela para iniciar o counter existente. MatchSimulation.apply_damage recebe a origem de poder para encerrar o Instinto somente após dano efetivo (PowerHit e Estrangular); projéteis de lâmina continuam físicos. PoseSolver/PowerView só leem o estado; o DuelScreen pulsa letterbox no POWER_ACTIVE. AiPowers escolhe a suprema sob pressão; AiController observa o status rival nos seus pensamentos e troca a ofensiva física por poder/espera. Nó 12 da Aurora gerado de STORY.md, sem mudar conjuntos base do elenco.

### Singularidade Devastadora (task 05)

simulation/powers/singularity_field.gd reúne início, fases, ondas determinísticas, atração e arremesso. É um script estático sem estado global, pré-carregado pelos módulos consumidores; os campos escalares e referências ficam no FighterState e entram no snapshot automático. Hazard.Kind.EXTRACTION reaproveita o pool e seus snapshots; Projectile.Kind.SINGULARITY acrescenta vy ao pool e ao snapshot para uma trajetória reta em dois eixos, com mira fixada na formação. MatchSimulation zera vy ao reutilizar qualquer projétil. A simulação aplica atração antes da integração e avança o campo uma vez por tick de luta; morte cancela marcas pendentes. PowerImpact.allow_finisher impede execução/BLAST nas extrações. ActionStarter e PowerStarter estendem a restrição da chuva ao campo. PowerView e DebrisLayer só leem fases e eventos, com placas extraídas num pool visual fixo; câmera e áudio reagem aos eventos existentes. A IA escolhe a suprema a média distância contra alvo no chão e prioriza sair lateralmente das marcas/caminho, sem salto ou guarda, antes de planejar ataques. Catálogo/Galeria e nó 12 Eclipse gerados dos dados, sem alteração dos conjuntos base.

FighterState.capture e restore duplicam arrays de poderes e PackedInt32Array de recargas, mantendo referências aos Resources. Isso evita que o avanço da simulação altere retroativamente um snapshot, descoberto no teste da Singularidade com recarga longa. A cópia só ocorre ao salvar/restaurar, nunca por tick.

A IA com save_for_fourth também reserva medidor para a Singularidade equipada em qualquer espaço e prioriza o lançamento pronto, sem mudar conjuntos base. GalleryPanel.demonstrating aguarda os dois novos status; no modo finalização, a Galeria calcula vida suficiente para sobreviver às ondas de extração, deixando a massa final demonstrar BLAST.

### Disparos e desvio (task 06)

Dados: `BoltData` (`data/bolt_data.gd`, recursos em `data/bolts/`) descreve um disparo sem depender do modo: velocidade, alcance, dano, tamanho, tranco, custo na guarda, saída (altura e distância à frente), rajada (`count`, `interval`) e o ganho de velocidade no parry perfeito. O duelo usa só o eixo horizontal mais `vy`; o modo de cima (Infiltração) vai usar os mesmos números com direção 2D, lendo `muzzle_forward` como distância à frente e ignorando `muzzle_height`.

Um golpe dispara quando `MoveData.bolt` existe: `AttackState` chama `BoltResolver.fire` no primeiro tick ativo e continua a rajada (`FighterState.bolts_left` e `bolt_ticks`, limpos com o golpe) no active e na recovery. Golpe com `reach` 0 é só tiro e não tem hitbox de lâmina. `TechniqueStyle.SHOT` é a pose de tiro (mão livre à frente, coice curto); a família Versáteis troca isso pela arma na task 07.

`Projectile.Kind.BOLT` guarda `bolt` e `shooter` (índice de quem atirou de fato, para a cor). `ProjectileSystem` move o disparo em x e y, o Arsenal intercepta antes, e `BoltResolver.resolve` decide: invulnerável ou na esquiva de precisão passa; Barreira desfaz; guarda de frente desfaz (Vigor, sem quebra) ou, com a janela de parry aberta, devolve pela linha ou, no parry perfeito, mira o peito de quem atirou; senão acerta (dano, tranco só em `BoltResolver.flinches`, morte sem finalização). Eventos novos no fim do enum: `BOLT_HIT`, `BOLT_BLOCKED` (com `power` quando foi a Barreira), `BOLT_REFLECTED` (`amount` 1 no perfeito). Disparos não geram Fluxo.

Apresentação: `PowerView._draw_bolt` (traço preso à grade, borda `UiPalette.bolt` ou na cor da lâmina de quem devolveu), receitas `bolt_*` no `EffectsConfig`, faíscas e anel no `EffectsDirector`, brilho e recuo da guarda no `FighterView`, sons `bolt_*` no `DuelAudio`. O `FighterView` procura o disparo que chega em até `bolt_guard_lead` segundos e o entrega ao `GuardTracker` como um segmento, então a guarda mira na linha do disparo como faz com uma lâmina. F3 mostra a caixa de cada disparo e `bolts out / burst left`.

Treino: `DummyController.Behavior.SHOOT` aperta frente + Habilidade no intervalo `TrainingConfig.dummy_shot_interval`. O golpe do boneco é `data/training/dummy_shot.tres` (só para treino, fora do catálogo). Ao escolher "atirando", o `TrainingPanel` troca a técnica de frente do boneco por esse golpe e devolve a original ao sair; para isso o `TrainingMode` duplica o personagem do boneco. O ciclo do F5 agora é uma lista explícita (parado, em guarda, atacando, atirando, reproduzindo); antes, com uma gravação feita, o ciclo chegava a comportamentos sem nome e quebrava. "Atirando" só aparece com Poderes ligados, porque técnicas dependem deles.

### Família Versáteis (tasks 07 e 08)

Corsária (`data/characters/corsair/`) e Lince (`data/characters/lynx/`) usam a família `data/families/versatile.tres` e as regras de disparo da task 06. Ganchos novos, todos por dados:

- `MoveData.bolt` em golpes comuns (o passo 2 da Corsária corta e dispara); técnicas de disparo em `data/techniques/` (`double_shot`, `retreat_shot`, `snap_shot`) com disparos em `data/bolts/`. Impulso negativo (`lunge` < 0) agora recua durante o ativo (Recuo com disparo).
- `MoveData.from_guard`: `BlockState` inicia direto a técnica que tiver o campo (Tiro de guarda).
- `MoveData.follow_up_auto`: o `follow_up` começa sozinho no primeiro tick da recovery (Rajada Desestabilizadora: rajada → avanço).
- As supremas da família (`BLADE_SEQUENCE`) foram removidas a pedido do autor; a Rajada virou técnica (`data/techniques/unsettling_barrage.tres`, com disparo e avanço como sub-recursos).
- `BoltData.pitch` afina o som do tiro.
- `WeaponData.sidearm` (`NONE`, `BLASTER`, `HILT_EMITTER`): só apresentação. `SidearmView` desenha o blaster na mão livre, na camada da mão de trás, apontado para baixo em repouso e erguido por `RigPose.sidearm_raise`; `HiltView` desenha o emissor no cabo, que brilha (`EffectsConfig.emitter_flash`) quando o lutador dispara. A pose `SHOT` estica o braço da arma e baixa a lâmina (Corsária) ou leva o cabo à frente com a lâmina para cima (Lince); golpes de lâmina com disparo erguem o blaster durante o ativo.
- `MoveData.required_sidearm` + `MoveData.usable_by(character)`: `PowerCatalog.cycle_technique` só oferece técnicas que o personagem pode usar. A Galeria pede outro lançador com o sinal `GalleryPanel.caster_required`; a `DuelScreen` reabre um `GalleryMode` com `caster_id` e `entry_index`.
- Estatística `bolt_hits` (`StatsTracker`) para os desafios de cor; IA usa técnicas de disparo a até 60% do alcance do disparo e o recuo com disparo quando o rival está perto (`technique_bias` alto na Corsária, baixo no Lince).

### Finalizações dos Versáteis e disputa do Soberano

- `Finisher.Kind.CROSSED_EXECUTION` e `PRECISE_SENTENCE` (longas, em etapas) em `data/finishers/`. Campos novos, todos por dados: `FinisherEffects.shots` (instante do disparo: `FighterView._finisher_shot` traça da arma ao peito da vítima) e `hole_at` (o furo da estocada abre no instante do tiro); `FinisherReaction.fall_backward` e `turn_at` (a vítima espelha para encarar quem a finaliza; a queda usa o lado visível); `FinisherMotion.extinguish_at` (quem finaliza apaga a lâmina); `PoseKey.sidearm` ergue o blaster nas etapas. `Finisher.passes_behind` põe o Lince atrás da vítima como no giro da Garça.
- `CharacterData.lock_style` (`BLADE`, `FLOW_HOLD`): só apresentação. Com `FLOW_HOLD` (Soberano), `PoseSolver._blade_lock` recolhe a lâmina e põe a palma no ponto da disputa; no choque, a palma empurra. `PowerView._draw_flow_hold` desenha anéis, fio e partículas na cor do tier; ao vencer a disputa, anel e onda de Repulsão (`PowerView`) e o som da Repulsão (`DuelAudio`). As faíscas da disputa (`EffectsDirector`) passam à cor do tier.
- `SceneRouter` mostra "Carregando" no fade de toda troca de cena, desenhado antes do trabalho pesado; `DuelMode.required_resources()` (a Galeria pede o personagem que lança) carrega em segundo plano.

Na revisão da task 11 pelo MCP, recursos regravados pelo editor tinham perdido arrays compactados, inclusive grade/rotas do treino, e `campaign.tres` tinha `milestone_points = null`. Os dados limpos anteriores foram recuperados com backup em `build/task11_resource_recovery/`. A tabela de pontos de marcos fica explícita no recurso da campanha, com os mesmos valores do script (3/3, 3/2, 2/2); isso permite compilação no editor sem depender do valor padrão de um array aninhado em instância placeholder. Não há mudança nos pontos concedidos em runtime.

O SubViewport do treino de Infiltração recebe `World2D` exclusivo antes de entrar na árvore. Isso conserva sua câmera interna ao abrir outra instância ou liberar a anterior: o mundo compartilhado fazia a câmera perder a ativação em reaberturas pelo editor. A câmera de referência do enquadramento fica no viewport principal e só fornece posição/zoom ao PixelStage. A correção fica no modo, sem alterar o PixelStage compartilhado do duelo.
