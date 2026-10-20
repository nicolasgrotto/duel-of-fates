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

Nenhum número de balanceamento no código. Os valores iniciais estão nos documentos de `content/` e em GAME_DESIGN.

## Controladores e entrada

- Ações do InputMap com nomes neutros: `move_left`, `move_right`, `jump`, `light_attack`, `heavy_attack`, `block`, `dodge`, `evade`, `special`, `power`, `pause` e as de menu. Conjuntos por jogador (P1/P2) e por dispositivo.
- **`Intent`**: o que o lutador pede neste tick (direção, botões apertados/segurados/soltos). É a única entrada da simulação.
- **`PlayerController`**: lê o InputMap do seu jogador e monta o `Intent` (com o buffer de 0,15 s e a janela do acorde do quarto poder).
- **`AiController`**: pensa em intervalos, lê o estado visível e produz `Intent`. Perfis e dificuldades vêm de dados. Nunca toca no estado.
- **`DummyController`** (Treino, Tutorial) e **`ReplayController`** (reproduz intents gravados).
- Remapeamento salvo em `user://`; telas mostram os bindings atuais com ícones do dispositivo em uso.

## Apresentação

- **`DuelScreen`**: monta arena, `FighterView` ×2, `CameraRig`, `Hud`, `EffectsDirector`; um executor de tick chama a simulação e despacha os eventos do tick para quem escuta (sinais).
- **`FighterView`**: lê o `FighterState` e escolhe a animação e o ponto dela pela **fase e progresso do golpe** (a animação segue a simulação, nunca o contrário). Trajes trocam materiais e peças, não a lógica.
- **`BladeView`**: camadas da lâmina, luz, rastro, ignição, apagar, tremulação.
- **`EffectsDirector`**: receitas de efeito por evento, com pools de partículas e luzes; respeita "efeitos reduzidos".
- **`CameraRig`**: enquadramento dos dois lutadores, punch-in, tremor, mini-cinemáticas de poder, letterbox.
- **`Hud`**: barras, marcas, rounds, mensagens; lê estado e eventos.
- **`StatsTracker`**, objetivos do tutorial e desafios: escutam eventos.
- Debug **F3**: hitboxes, hurtboxes, colisão de lâmina, estado, fase, Vigor, Fluxo, intents, decisões da IA, FPS, tick.

**Validação lâmina × animação**: a colisão de lâmina vem da trilha em `MoveData`. Uma ferramenta de editor (ou teste) compara a trilha com a posição real da lâmina na animação, para o que se vê bater com o que acerta.

## Telas e fluxo

- **`SceneRouter`** (autoload): troca de telas por id (`change`, `push`, `pop`), com transições (fade, letterbox). Telas não se importam entre si.
- A pausa é uma tela empilhada sobre o duelo congelado.
- Cada modo é um objeto de fluxo (`modes/`) que monta os parâmetros do duelo (lutadores, variantes, conjuntos, arena, dificuldade, capacidades, rounds, seed) e decide o que acontece no resultado.

## Serviços (autoloads)

- **`Settings`**: opções, idioma, bindings (arquivo `ConfigFile` em `user://`).
- **`SaveService`**: progresso (desbloqueios, recordes, campanha), com versão de formato e migração.
- **`SceneRouter`**: navegação.
- **`AudioDirector`**: música dinâmica em camadas, barramentos, zumbido das lâminas.
- **Localização**: tabelas da Godot (`TranslationServer`, `tr()`), uma chave por texto, marcadores com `format()`.

## Testes

- Testes da simulação headless: regras de combate, janelas de parry, disputa, consequências, interação de poderes, IA (com seed), determinismo (mesma seed e intents = mesmo estado final), progressão da História, saves.
- Testes de dados: todo personagem tem golpes válidos, todo texto existe nos dois idiomas, todo asset tem linha em ASSETS.md.
- Testes automatizados aprovados pelo autor. Executor: mínimo e próprio, em `tools/run_tests.gd`, rodado com `godot --headless --script`. Um addon de testes (gdUnit4 ou GUT) só entra se o executor próprio não bastar, com autorização.
- **Simulador**: `godot --headless --script tools/simulate.gd -- --duels 300 --difficulty normal` roda duelos IA × IA e relata vitórias, golpes até o K.O. e duração; uma matriz todos-contra-todos acompanha o equilíbrio do elenco.

## Desempenho

- 60 FPS estáveis. Nada de alocação por tick na simulação; pools na apresentação.
- Medir com o profiler da Godot em cada fase, nas arenas mais pesadas (reflexo, chuva, Tempestade) e com dois lutadores detalhados.
- **Decisão**: verificar no início do projeto o suporte do renderer escolhido a glow/HDR 2D, luzes 2D com mapas de normal e o custo de reflexos, antes de fechar a técnica de arte.
