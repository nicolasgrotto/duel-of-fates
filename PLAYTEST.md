# PLAYTEST — Roteiro de validação

Roteiro para o autor validar, jogando, o que entrou na fase 7.5 (revisão de combate e animação) e no começo da fase 8. Cada item diz **como testar**, **o que deve acontecer** e **onde ajustar** se não estiver bom. Anote o número do item e o que sentiu; o agente seguinte corrige a partir disso.

Legenda: ✅ ficou bom · ⚠️ funciona mas a sensação ou o número precisa de ajuste · ❌ não funciona.

## Caçada a chefes — task 09

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 09.1 | Jogar → Caçada a chefes; percorra os três itens em PT e EN, a 720p e 1080p; confirme e pule a fala | cartão com condição, três fases/poder principal, kit, recompensa e recorde; Voltar não encosta no rodapé; diálogo inicia o duelo | `screens/hunts/`, tema `Hunt*Label`, `strings.csv` |
| 09.2 | A última lição: aparar três fortes perfeitamente e vencer; repetir matando com só dois parries; use Repulsão no Instinto | sucesso só no primeiro caso; Viajante liberado uma vez; fases em 65% e 30%, sem retroceder nem curar; poderes encerram o Instinto | `last_lesson.tres`, `HuntTracker`, perfis das fases |
| 09.3 | O olho da tempestade: observe Raio, marcas da Tempestade e encerramento; vença antes e depois de 90 s | guarda não protege a Tempestade; corrida, esquiva e Barreira dão respostas; tempo inclui tick letal, exclui pausa/intro/K.O./replay; cor do Guardião só no sucesso | `storm_eye.tres`, `HuntCondition.seconds` |
| 09.4 | O peso do vazio: deixe uma Singularidade lançar e terminar a massa com os dois vivos, depois vença; repita matando durante o campo | primeiro caso libera a cor da Sombra; segundo mostra condição não cumprida; estado da condição visível; troca de fase espera campo/massa terminar | `weight_of_void.tres`, `HuntTracker._singularity_pending` |
| 09.5 | Reinicie pela pausa; perca; tente de novo; vença com replay ligado; Continue; reveja o epílogo na lista; reabra o jogo | tentativa nova sem progresso anterior; derrota sem recompensa; replay reproduz fases sem duplicar prêmio; epílogo retorna ao mesmo item; conclusão e melhor tempo persistem | `HuntMode`, `TickRunner.objective`, `SaveService.hunt_best` |
| 09.6 | Compare anúncios com efeitos completos/reduzidos e F3; confira intro/K.O./replay de um duelo comum | fase e condição no F3; pulso de letterbox visível só com efeitos completos; barras existentes agora ocupam a largura da tela, sem mudar combate | `DuelScreen`, `ScreenEffects`, `ModesConfig.boss_*` |

Validação automatizada da task 09: 401 testes sem falhas, incluindo seis duelos coreografados com vitória e condição cumprida/perdida; limiares, recargas, sobrevivência, replay, recompensas idempotentes e migração/persistência. `build/task09_flow_smoke.log` registra 17 verificações do fluxo completo com replay e recarga do save. `build/task09_transition_check.log` mede largura/altura real das barras e a ausência do pulso com efeitos reduzidos; capturas `transition_normal_1280.png` e `transition_reduced_1280.png`. Folhas `phases_1280_sheet.png`, `phases_1920_sheet.png`, `ui_*_sheet.png` e `results_*_sheet.png` em `build/task09_renders/` foram inspecionadas. 1080p renderizado diretamente em SubViewport de 1920×1080, pois a janela física é limitada pelo desktop; sem ampliar imagens de 720p. Capturas usam `capture_progress.cfg`, todos os processos de validação usam APPDATA isolado em `build/task09_userdata`. Ponte MCP sem editor autenticado; cenas executadas diretamente na Godot 4.7.2 com renderização. Controle físico, dificuldade e sensação com jogador humano ainda precisam da avaliação do autor.

## Treino de infiltração — task 10

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 10.1 | Aprender → Treino de infiltração, em PT e EN; 720p e 1080p | mapa superior, boneco e emissor legíveis; objetivo, vida/Vigor e dicas em duas linhas; Voltar do menu não sobrepõe rodapé | `screens/infiltration/`, tema `InfiltrationLabel`, `strings.csv` |
| 10.2 | Ande em todas as direções; corra; use furtivo; deslize pelas caixas e pelos cantos; aproxime-se do boneco | diagonal sem bônus de velocidade, aceleração suave, furtivo vence corrida, corpos e grade sólidos, câmera acompanha respeitando bordas | `InfiltrationConfig`, `InfiltrationGeometry`, `training_map.tres` |
| 10.3 | Aproxime-se do boneco, mire nele e golpeie; tente pelos lados, fora do alcance e através da caixa; gire a mira durante o corte | preparação/ativo/recuperação claros; acerto somente quando a fatia do arco passa pelo alvo, uma vez por golpe; direção travada; parede bloqueia; boneco reaparece após 3 s | `_resolve_swing`, `swing_*`, `InfiltrationView` |
| 10.4 | Fique na faixa de tiro e segure guarda antes do disparo; depois mire de costas; repita com Vigor vazio | frente desfaz sem dano e drena Vigor, sem blockstun; costas recebem dano; guarda vazia continua funcionando; tranco não cancela preparação/ativo de golpe | `guard_degrees`, `BoltData`, `_resolve_player_bolt` |
| 10.5 | Toque guarda na chegada, primeiro com antecipação de ~0,1 s, depois no último instante; use a mira diagonal perto do emissor | comum devolve pela linha; perfeito mira o centro do emissor a 125% da velocidade e mostra anel curto; devolver uma rajada não fecha a janela; novo parry respeita recarga | `CombatConfig.parry_*`, `standard_bolt.tres` |
| 10.6 | Use teclado remapeado, mouse e controle; stick esquerdo anda, direito mira; pressione F3 | ações específicas do treino refletem o J1, mouse também golpeia/guarda, mira independente; F3 mostra posição/velocidade, colisão, mira/arco, guarda/parry e FPS | `InfiltrationBindings`, `InfiltrationPlayerController` |
| 10.7 | Pause durante um tiro; segure ataque na pausa e continue; reinicie; deixe a vida zerar; volte a Aprender e abra Duelar | pausa sem avançar o estado; ataque pendente não dispara ao voltar; reinício limpa tiros/vida/alvos; morto só pode reiniciar/sair; teclas do duelo intactas; nenhum progresso é gravado | pausa local, descarte de comandos, `capture`/`restore`, remoção de aliases |
| 10.8 | Repita a devolução com efeitos reduzidos; ouça tiro, defesa e passos andando/correndo/furtivo | projétil e guarda sempre legíveis; menos faíscas, anel do perfeito mantido; passos discretos em furtivo; zumbido pausa e termina ao sair | pool de `InfiltrationView`, banco original e `InfiltrationConfig` |

Task 10 validada com **426 testes sem falhas**, 25 novos (determinismo/hash/eventos, snapshots, colisão varrida/cantos/corpos, arco por fatia, guarda frente/costas, parry comum/perfeito/rajada/recarga, dano, pools, morte/reaparecimento e controles). Fluxo real via roteador/InputMap: **16 verificações sem falhas** em `build/task10_flow_smoke.log`. **36 capturas** de mapa, movimento, corte, desvio, devolução, F3, pausa, morte, reinício, EN e efeitos reduzidos em `build/task10_renders/`; quatro folhas `core_1280_sheet.png`, `core_1920_sheet.png`, `ui_1280_sheet.png`, `ui_1920_sheet.png` inspecionadas. 1080p usa SubViewport nativo, sem ampliar capturas de 720p. Atlas/sprites regenerados e comparados por SHA-256, idênticos. Medição curta na GT 730 a 1280×720: 59,8 FPS em 300 quadros após aquecimento, pior quadro 18,1 ms, oito draw calls; núcleo ~40,2 µs por tick em 10.000 passos (`build/task10_profile.log`). Isso é uma amostra do treino, não validação de todos os mapas futuros. Processos usam APPDATA em `build/task10_userdata`, capturas começam em `capture_progress.cfg`; ponte MCP sem editor autenticado, cenas rodadas diretamente na Godot 4.7.2 com renderização. Controle físico, conforto da mira e áudio ouvido precisam da avaliação do autor. Patrulhas/visão/ruído/alarmes são a task 11; missões e poderes continuam para a 12.

## Patrulhas e alarmes — task 11

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 11.1 | Aprender → Treino de infiltração; explore o setor sul e a sala à direita, em PT/EN e 720p/1080p | patrulha segue os pontos, sentinela gira sem sair da base, pesado anda mais devagar e tem silhueta mais larga; título/dicas legíveis | `patrol_map.tres`, `enemies/*.tres`, gerador de sprites |
| 11.2 | Aproxime-se fora dos cones; cruze um cone; esconda-se atrás de parede/caixa; compare corrida e furtivo | visão bloqueada pela grade; suspeita sobe até `?`, depois `!`; busca usa último ponto, não acompanha jogador escondido; após perder memória retoma rota | `InfiltrationPerception`, `vision_*`, `suspicion_*`, `alert_memory` |
| 11.3 | Corra perto de inimigo de costas; repita andando/furtivo; golpeie e devolva um disparo contra a parede | alcance de ruído maior na corrida e no combate; som sozinho gera suspeita e investigação, não alerta instantâneo; guarda com Corrida não recebe ruído de corrida | `walk_noise`, `run_noise`, `sneak_noise`, `combat_noise`, `reflected_wall_noise` |
| 11.4 | Aproxime-se de costas de inimigo despercebido e use Abate silencioso (forte/K padrão); repita pela frente, fora do alcance e com alvo suspeito | dica só quando válido; morte instantânea sem ruído e sem reaparecimento; solicitações inválidas recusadas; corte comum continua causando dano/ruído | `takedown_*`, `takedown_target`, `InfiltrationBindings` |
| 11.5 | Provoque alerta; observe corrida ao painel e canalização; inutilize-o com Interagir (Poder/U padrão) antes e durante alarme | só inimigo alertado ativa; sirene/luz/música mudam; inutilizar previne ou interrompe; chamada pendente cancela ao desligar todos; não apaga memória dos guardas | `panel_*`, `interaction_range`, `_step_panels` |
| 11.6 | Deixe o alarme chamar reforços; ocupe um acesso marcado; depois libere-o; enfrente os disparos do pesado com guarda/parry | uma onda em posições fixas, entrada adiada por ocupação inclusive diagonal; sem teleporte junto ao jogador; rajada de três pode ser devolvida e derruba inimigo; sobrevivente lembra o ponto do parry | slots de reserva do mapa, `_spawn_clear`, `BoltData`, `InfiltrationBolt.origin` |
| 11.7 | Pause durante canalização/chamada/tiro; continue, reinicie, saia e reabra três vezes; ligue F3 | estado congelado, áudio suspenso, reinício restaura painéis e reservas; reaberturas mantêm câmera e enquadramento; debug mostra cones/rotas/suspeita/decisão/último ponto; sem escrita de progresso | `InfiltrationScreen`, World2D do viewport, snapshot, `_set_paused` |
| 11.8 | Use efeitos reduzidos, remapeamento e gamepad; ouça passos, aviso, alarme e mudança de música; meça FPS com editor fechado | cones e `?`/`!` continuam legíveis, luz local fica estática, dicas seguem bindings, ações do duelo intactas ao voltar; avaliar conforto e desempenho | `InfiltrationView`, controle do modo, áudio local, configurações de ruído/visão |

Validação da task 11: **457 testes sem falhas**, 31 novos; **24 scripts compilados sem erro pelo MCP**, nove verificações nativas de estado e três reaberturas com câmera ativa. InputMap também acionado pelo MCP. Fluxo roteado via MCP: 17 verificações sem falhas (`build/task11_mcp_flow_checks.json`); fluxo final incluindo câmera: 18 (`build/task11_flow_smoke.log`). Capturas roteirizadas têm **18 verificações sem falhas em cada resolução**, com **32 PNGs 720p/1080p** e seis folhas inspecionadas em `build/task11_renders/`. Sete PNGs nativos de 1600×900 e folha inspecionada em `build/task11_mcp_renders/`; estados em `build/task11_mcp_final_checks.json`. Os percursos usam um checkpoint do mesmo mapa no início da aproximação traseira; o fluxo de menu valida a entrada normal. O MCP revelou dados compactados perdidos em recursos regravados e câmera interna desativada em reaberturas; os dados foram recuperados, a tabela de marcos da História ficou explícita com valores preservados e o viewport do treino recebeu World2D exclusivo. Geradores idempotentes por hash. Matriz do duelo: 936 antes e 936 depois, 13 taxas e contatos idênticos. Amostra de desempenho com editor aberto na GT 730: **55,7 FPS**, pior quadro 33,1 ms; núcleo com IA ~999 µs/tick em 10.000 passos vivos. **60 FPS ainda precisam de validação**, junto da pendência da fase 8. Processos diretos usam APPDATA isolado; todos os scripts de captura, inclusive MCP, definem `capture_progress.cfg` antes de agir. Controle físico, conforto e áudio ouvido ficam para o autor. Distração arremessável/sombras especiais não entraram; missões, extração, menu definitivo e resultados ficam para a task 12.

## 0. Preparação

1. Feche o editor e rode, na pasta do projeto:
   ```
   godot --headless --path . --import
   godot --headless --path . --script res://tools/run_tests.gd
   ```
   **Esperado**: suíte sem falhas (457 testes após a task 11).
2. Abra o jogo pelo editor (F5). Na tela de abertura, digite o segredo **O Equilíbrio** (← ← → → ↑ ↓ ↑ ↓) para liberar os secretos e a variante Eclipse do Predestinado. Isso grava o save real; se não quiser, use um perfil de usuário de teste ou faça backup de `user://progress.cfg`.
3. Teclas padrão do J1: `A`/`D` andar, `W`/`Espaço` pular, `J` rápido, `K` forte, `L` guarda (tocar apara), `Shift` esquiva, `S` esquiva de precisão, `I` habilidade (frente ou trás + `I` = técnicas), `U` poder, `U`+`I` quarto poder, `F3` debug. No Treino: `F5` comportamento do boneco, `F6` gravar, `F7` reproduzir.
4. Deixe o **F3** ligado nos testes de regra: ele mostra estado, fase do golpe, `contacts` (contador da Pressão), `cinematic`, `reserve` (reserva de Defesa) e `disengage ready`.

## 1. Correções

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 1.0a | Tutorial, passo da disputa: fique perto e aperte forte; depois pressione rápido. Repita o Treino guiado da disputa até o fim | o boneco espelha um tick depois; os fortes comprometidos iniciam disputa sem dano; Tutorial avança para Habilidade; treino completa três disputas, uma pressão e um desengajamento | `CombatConfig.clash_window`, `BladeLockConfig` |
| 1.0b | Em 2 Jogadores, fortes próximos separados por 1–4 quadros; depois separados por mais de 4; teste rápidos e técnicas | dentro da janela há choque/disputa; fora dela o mais rápido ainda acerta; duas preparações sem ativo não chocam; nenhum ativo atrasado acerta após o choque | `ClashResolver`, 0,067 s arredondados a quatro ticks |
| 1.0c | Segure guarda contra a sequência do Guardião e os cinco rápidos da Vespa; alterne rápidos e forte | mãos viajam sem voltar à pose inicial entre contatos; antecipação, recuo e faísca próximos do cruzamento | `GuardTracker`, `MotionFamily.block_*`, `release_start`, `contact_swing` |
| 1.0d | Guarda contra Bastião forte, Haste/Investida, Ceifador e forte no salto; repetir à esquerda e à direita | braços alcançáveis, duas mãos no cabo, defesa com o centro do bastão, acompanhamento da altura | `PoseSolver._forecast_guard`, `ArmGeometry`, segmentos do `FighterView` |
| 1.0e | Compare oito famílias paradas/andando em guarda; Treino F5 em guarda; Tutorial bloqueio e parry; ligue F3 | postura defensiva distinta, respiração e transferência de peso; interceptação/velocidade/tempo de contato no debug; nenhuma regra direcional | famílias de movimento e `FighterView.on_event` |

Validação desta rodada: duelos reais capturados a cada três ticks em `build/guard_story_review/guard_*`, com folhas `guard_*_sheet.png` e `guard_families_sheet.png`. Há antecipação e recuo e as mãos permanecem alcançáveis. O teste de contato começa em 12 px e usa limite final de 14 px da grade (28 unidades): a IK e a inclinação no forte aéreo do Ancião deixam uma pequena separação residual no tick inicial; manter esse caso na avaliação da sensação, sem deslocar eventos ou regras para maquiar o desenho. A captura automatizada do Treino seleciona o mesmo comportamento de guarda; o acionamento físico do F5 e a sensação com controle ficam para a rodada do autor.

### 1b. Árvore de poderes da História

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 1b.1 | Hub → Poderes; campanha Aurora nova, Eclipse após capítulo 4, campanha concluída | sete nós em ordem real; inicial na criação; capítulo/título do encontro nos outros; estados por texto e moldura, também em cinza | `StoryPowerTree`, `story_powers`, tema central |
| 1b.2 | Setas/D-pad, confirmar em aprendido, escolher espaço, voltar; hover/clique nos nós e espaços | mesmo cursor; escolha só dos espaços abertos; voltar devolve o foco; repetir poder em outro espaço é recusado; nenhum espaço aberto é esvaziado | `StoryCampaign.equip_power`, navegação da tela |
| 1b.3 | Ganhe os capítulos com marco; abra a árvore; teste uma exigência maior de Fluxo em recurso de teste | espaços vêm dos marcos; próximo nó acompanha o próximo encontro; custo/recarga usam Fluxo da campanha; exigência insuficiente impede equipar | `EncounterData.milestone`, `PowerCatalog.is_allowed` |
| 1b.4 | Confira 720p, 1080p e ultrawide; volte ao hub e reabra a campanha | grafo/detalhes/rodapé legíveis; mesmos ícones no hub; equipamento persiste no formato anterior | âncoras/containers, `PowerData.icon`, `strings.csv` |

Validação automatizada: `tree_render.gd` em `build/guard_story_review/` instancia as três etapas nas três resoluções, verifica sete nós, enquadramento, foco inicial, escolha/retorno, quatro ações de navegação, hover/clique e equipamento persistido em perfil isolado. `tree_*.png`, `hub_middle_*.png`, `tree_states_grayscale.png` e `power_icons_sheet.png` são as evidências. Regeneração dos vinte PNGs comparada por SHA-256; ícones, dados e modelo cobertos pelos testes. Conferência física do controle e preferência de legibilidade dos ícones pequenos do hub ficam para o autor.

### 1a. Introdução dos lutadores

Em Opções, deixe **Introdução dos lutadores · Ligada**. No Duelar, veja cada entrada como jogador e como adversário, sem apertar ataques. Os dois devem caber no enquadramento; o título só aparece depois do assentamento na guarda. Use Revanche para repetir. Ajustes de poses e tempos ficam em `data/intros/<id>.tres`; duração total e título em `CombatConfig`, acessórios e ignição em `EffectsConfig`.

| Personagem | O que conferir na entrada |
| --- | --- |
| Guardião | ignição vertical diante do rosto, descida econômica até a guarda de duas mãos |
| Sombra | espera inclinada, ignição baixa tardia, abertura predatória |
| Bastião | levantamento pesado, teste descendente, recolhimento sobre o ombro |
| Vespa | duas ignições, mãos separadas e giros opostos, guardas distintas |
| Espelho | vertical diante da máscara, parada curta e retorno à vertical |
| Haste | duas mãos sobre a haste durante o levantamento, giro e descida até apontar ao rival |
| Brasa | lâmina invertida junto ao quadril e base baixa, sem giro amplo |
| Forja | peso sustentado com duas mãos e guarda alta sobre o ombro |
| Garça | arco ascendente, volta leve do corpo e lâmina alta atrás do ombro |
| Ceifador | início parado com capa/capuz; mão alcança e baixa o capuz devagar; olhar para o rival; capa temporária se solta e some em degraus; giro começa antes da ignição; primeira ponta acende antes da segunda; final em guarda baixa e larga |
| Eco | falsa guarda alta e giro do punho para a guarda baixa |
| Sombra Desperta | levantamento lento e pesado até a guarda alta atrás da cabeça (primeira luta de chefe no Arcade/Sobrevivência) |
| Soberano | braço avança devagar, ignição tardia com a ponta já no rival |
| Ancião | mãos reunidas junto ao peito, vertical calma e guarda alta |
| Predestinado | giro curto e guarda firme; repetir nas variantes Aurora e Eclipse, com cor e guarda próprias |

1. Observe a passagem do título ao combate em cada personagem: nenhum salto de mãos, arma ou tronco. No Ceifador, repita em Original, Viajante e Sentinela: só as peças temporárias saem; capa/capuz que pertencem ao traje permanecem. Repita espelhado no lado direito e com **Efeitos reduzidos**.
2. Em Revanche, pule uma vez com Confirmar e outra com cada ataque: rápido, forte, habilidade e poder. Teste também os comandos do J2 em 2 Jogadores. Os dois vão juntos à guarda e ao título, sem gastar Vigor, lançar ataque ou começar a luta antes do título. Repetir toques durante o título não deve eliminá-lo.
3. Termine um duelo de dois ou três rounds: só o primeiro mostra as entradas individuais; os demais têm a ignição e o título normais. Veja o replay final inteiro, inclusive depois de ter pulado a entrada.
4. Desligue **Introdução dos lutadores**, saia e abra o jogo novamente. A opção permanece desligada e o primeiro round usa a intro curta. Religue e repita. Confira o texto em português e inglês e navegue até Voltar: a lista rola mantendo seleção e rodapé visíveis.
5. Confira a regra nos inícios de Arcade, História e Sobrevivência. Depois abra Treino, Galeria, Tutorial, todos os Treinos guiados, Desafios e Desafio de parry: não há entrada individual mesmo com a opção ligada.
6. Ligue F3 durante a entrada: `intro`, tempo, duas ignições, `hood` e `cloak` acompanham o que se vê. Ao chegar à luta, acessórios temporários ausentes. O teste automatizado percorre cada tick das mãos e compara a pose assentada com a guarda da própria família.

Validação técnica desta entrega: capturas em GPU a 60 ticks/s, folhas de contato de todos os ticks dos 16 recursos de personagem, trajes do Ceifador, lado direito, pulo e efeitos reduzidos; duelo pelo editor até vitória, replay e resultado. Evidências locais em `build/intro_review/` (fora do git). Os harnesses próprios de `.preview/` são temporários e removidos ao concluir; os arquivos preexistentes dessa pasta são preservados. O playtest usou outro arquivo de progresso, e os testes automatizados usaram uma pasta APPDATA isolada.

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 1.1 | Extras › Galeria de poderes. Com ← → passe por **Dreno, Congelar, Truque Mental, Estrangular, Repulsão, Repulsão Suprema e Puxão**, nos tiers 2 a 4 (↑ ↓) | todos acertam o alvo parado: Dreno puxa o fio, Congelar prende no gelo, Truque Mental mostra os anéis sobre a cabeça, Estrangular ergue o alvo | distância da Galeria: `TrainingConfig.gallery_reach_ratio` (`data/balance/training_config.tres`) |
| 1.2 | Na mesma Galeria, passe pelas técnicas (depois dos poderes) | todas acertam o alvo; a Varredura não aparece mais na lista | — |
| 1.3 | Treino com a **Haste** e com o **Soberano**: `I` sozinho, a ~2 corpos de distância | Investida da Haste: haste recolhida no quadril, passo longo, braço esticado até a ponta; acerta de longe e o Ponto doce aumenta o dano na ponta | `data/characters/lance/lance.tres` e `sovereign.tres` (sub-recurso `*_ability_move`) |
| 1.4 | Contra a Haste no Treino, toque `L` na hora da Investida | é aparada como um forte (parry perfeito desequilibra a Haste) | — |
| 1.5 | Treino com **Brasa** (trás + `I`), **Eco** (trás + `I`) e **Predestinado Eclipse** (frente + `I`, variante com `V` na seleção) | Corte ascendente, Avanço com corte e Avanço com corte, respectivamente; a técnica Giro não existe mais (os nove que a usavam receberam Corte ascendente, Avanço com corte ou Estocada, ver CHARACTERS) | técnicas em cada `data/characters/<id>/<id>.tres` |

## 2. Animação

Use Aprender › Treino com o boneco parado (`F5` alterna o comportamento). Troque de personagem pela seleção.

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 2.1 | Olhe a guarda parada de cada família | Guardião/Ancião/Predestinado: lâmina diagonal à frente do rosto, mão de trás no pomo · Esgrimista: Espelho com lâmina vertical e Soberano com lâmina à frente, ambos com mão livre atrás; Haste com duas mãos no cabo longo · Agressor: Sombra com guarda baixa à frente e Sombra Desperta alta atrás da cabeça · Colosso (Bastião, Forja): lâmina alta sobre o ombro · Dançarina (Garça): lâmina para trás · Golpeador: Brasa com empunhadura invertida · Vespa: uma lâmina alta à frente, a outra baixa e invertida atrás · Ceifador: bastão atravessado | guarda: `guard_angle` e `guard_grip` em cada personagem; mãos: `MotionFamily` em `data/families/*.tres` (`back_hand_spacing`, `free_hand`, `off_guard_hand`, `off_guard_angle`) |
| 2.2 | Teste da silhueta: com o brilho da arena baixo, os personagens continuam distinguíveis pela forma de segurar? | sim | idem |
| 2.3 | Sequência de rápidos (`J` repetido colado no boneco) com cada família | cada passo com um corte diferente (descendente, ascendente, estocada, horizontal com o tronco torcendo, giro como fecho) e o corpo indo na frente do punho | tipo de corte: `cut` de cada golpe; atraso do punho: `MotionFamily.wrist_lag`; volta à guarda: `recover_share` |
| 2.4 | **Vespa**, sequência de 5 rápidos | as duas lâminas alternam: nos passos 2 e 4 a lâmina de trás conduz o corte e a da frente sobe para a guarda; o 5º fecha com giro | `PoseSolver._place_second_blade` (apresentação) |
| 2.5 | Forte (`K`) com Sombra e Garça | Agressor e Dançarina soltam a mão de trás no follow-through (giro com uma mão) | `MotionFamily.one_hand_follow` |
| 2.6 | `F5` até o boneco **atacando**; segure `L` | a guarda muda conforme o golpe: alta (lâmina deitada sobre a cabeça) contra descendente, baixa contra ascendente, inclinada contra estocada; faíscas no ponto onde as lâminas se tocam | `PoseSolver` (`BLOCK_*`); distância máxima para usar o contato: `EffectsConfig.blade_contact_snap` |
| 2.7 | Frente + `I` (Avanço com corte) com Guardião, Sombra e Ceifador, a ~2 corpos do boneco | 1) arrancada baixa com a lâmina recolhida e imagens residuais; 2) corte no fim do avanço (Guardião desce, Sombra sobe, Ceifador gira o bastão na arrancada) e uma pausa curta na pose final | `MotionFamily.dash_cut`, `dash_twirl`; tempos e avanço em `data/techniques/dash_slash.tres` |
| 2.8 | Pule e aperte `I` no alto com Sombra, Garça e Ceifador (Investida descendente) | antecipação encolhida com a lâmina erguida; Sombra e Ceifador descem cortando até o chão, a Garça faz pirueta e estoca; no pouso: faíscas e poeira onde a lâmina toca, joelho dobrado e pausa | `MotionFamily.plunge_cut`, `plunge_pirouette`; faíscas: receita `plunge_impact` em `effects_config.tres`; poeira: `PowerVfxConfig.plunge_dust`, `plunge_chunks` |
| 2.9 | **Vespa**, trás + `I` (Arremesso da lâmina), longe do boneco | as duas lâminas saem com um pequeno intervalo, em arcos espelhados, girando em sentidos opostos, e voltam; as mãos ficam estendidas esperando | `PowerVfxConfig.dual_throw_delay`, `dual_throw_arc` |
| 2.10 | Colado no boneco, pulo duplo para a frente passando por cima dele | cambalhota ao passar e pouso já virado para o boneco | `MotionFamily.vault_time` |
| 2.11 | Leve uma Repulsão (Galeria ou Duelar) com **Vespa, Garça ou Ceifador**, e depois com **Bastião ou Guardião** | as ágeis fazem mortal para trás e pousam em guarda; as outras derrapam com a mão no chão; o tempo de punição é o mesmo | `MotionFamily.acrobatic_recovery`, `tumble_time` |
| 2.12 | Com cada família, ande para os dois lados, faça rápidos, forte, guarda, esquivas e técnicas; observe também atingido e atordoado | mãos acompanham o tronco, cotovelos dobram com folga, cabo fica nas mãos durante as transições; o antebraço de trás aparece sobre a roupa ao segurar o cabo; nenhuma mão solta da arma ao virar | `MotionFamily.arm_reach`, `arm_extension`, `arm_fold_margin`, `front_elbow`, `back_elbow`, `windup_elbow`; `ArmGeometry` |
| 2.13 | Compare as guardas altas de **Bastião, Forja, Garça e Sombra Desperta**, a vertical do **Espelho**, a invertida da **Brasa** e as duas lâminas da **Vespa** | mãos fora do rosto, guardas distintas; Esgrimista e Golpeador equilibram com a mão livre atrás e relaxam essa mão ao andar; a Haste conserva **duas mãos** no cabo longo | `guard_grip`/`guard_angle` dos personagens; `free_hand`, `walk_free_hand`, `off_guard_hand` nas famílias |

## 3. Poderes

Galeria de poderes (↑ ↓ mudam o tier, `T` troca o alvo, `X` troca o lançador, `F` liga a finalização).

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 3.1 | Repulsão nos quatro tiers, lançando dos dois lados | palma recolhe junto ao peito, depois estende com recuo do ombro; um grande arco de ar nasce na palma, cresce em altura, tem borda fina clara, corpo translúcido e ecos fracos; termina no mesmo alcance em todos os tiers | `PoseSolver._repulse`; grupo Repulse and fracture de `PowerVfxConfig` (`repulse_*`) |
| 3.1b | Ligue a Finalização (`F`) e passe por Raio, Repulsão, Repulsão Suprema, Puxão, Corte de Fluxo, Estrangular e pelas técnicas Avanço com corte, Investida descendente, Corte ascendente e Arremesso da lâmina | a linha de detalhes mostra "Finalização · ligada" só nessas entradas; o alvo fica parado e morre na cinemática de cada uma; o round recomeça sozinho e a demonstração repete; nos outros poderes nada muda | `TrainingConfig.gallery_finisher_health`; cinemáticas: grupo Finishers do `EffectsConfig` |
| 3.2 | Puxão | mão estende aberta e puxa em garra; uma bola grande na mão de quem lança encolhe muito rápido; nada atrás do alvo e sem fio | `PowerVfxConfig.pull_orb_radius`, `pull_orb_time`, `pull_orb_core`, `pull_orb_tier_growth` |
| 3.3 | Raio nos tiers 3 e 4 (lançador Sombra) | 2 e 3 feixes abertos em leque, saindo dos dedos, separados no meio do caminho e chegando em alturas diferentes do corpo | grupo Lightning do `PowerVfxConfig` |
| 3.4 | Corte de Fluxo nos tiers 2 e 4 | preparação com a lâmina atrás da cabeça, arco inteiro até a lâmina bater no chão, onde nasce a onda; no tier 4 o segundo corte vem 0,35 s depois, também com o arco completo | `data/powers/flow_cleave.tres` (`apex_repeat_delay`) |
| 3.5 | Telecinese em Massa (Predestinado Aurora, `U`+`I` no Duelar, ou na Galeria no tier 3 ou 4) | câmera sobe (~0,45 s), meteoro é puxado e racha (~0,6 s), câmera desce acompanhando os pedaços (~0,45 s); o duelo fica congelado durante a subida e o meteoro (F3: `cinematic`); nada parece acelerado | congelamento: `data/powers/mass_telekinesis.tres` (`cinematic_freeze`); câmera e meteoro: `PowerVfxConfig.mass_rise`, `mass_hold`, `mass_descend`, `meteor_crack` |
| 3.6 | Repulsão Suprema e depois as duas Repulsões com **efeitos reduzidos** | Suprema solta os arcos `(` e `)` a partir do corpo; com redução, a onda principal continua legível, sem ecos, riscos extras ou flashes e com menos poeira; o alcance e o resultado do golpe não mudam | `repulse_reduced_alpha`, `repulse_reduced_dust`, `repulse_echo_*` em `PowerVfxConfig` |

## 4. Regras novas

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 4.1 | **Esquiva com giro**: colado no boneco, segure para a frente e toque `Shift` | rotação baixa atravessando o boneco, pouso do outro lado já virado; gasta 28 de Vigor; longe do boneco vira o dash comum; contra a parede atrás do boneco vira esquiva comum para a frente | grupo Dodge do `CombatConfig` (`spin_dodge_*`) |
| 4.2 | Faça a esquiva com giro com o boneco atacando (`F5`): no começo e no fim do giro você ainda leva golpes; no meio, não | invulnerável só de 0,04 a 0,14 s; o fim (0,16 s) é punível | idem |
| 4.3 | Aprender › Treinos guiados › **Esquiva em sequência**: o último passo pede duas esquivas com giro | o passo termina depois de duas | `data/lessons/guided_evade.tres` |
| 4.4 | **Pressão de lâminas**: Treinos guiados › **Disputa de lâminas**, 2º passo (boneco que repete o tipo de ataque). Troque rápidos colados; vale também aparar um rápido (toque `L`) | no 3º contato seguido (choque de rápidos ou parry de rápido) em até 0,6 s entre eles abre a pressão: lâminas em X mais baixas, inclinação mudando a cada aperto, corpos andando meio passo; vence quem abrir 3 de vantagem (dura até 1,5 s); quem aparou o 3º entra com 1 de vantagem | grupo Blade press do `BladeLockConfig` |
| 4.5 | Com o F3 ligado, observe `contacts N (ticks)` durante as trocas | o contador sobe a cada choque ou parry de rápido e zera com acerto, forte, técnica, esquiva, empurrão, poder ou 0,6 s sem contato | idem |
| 4.6 | Julgue a frequência: a pressão aparece "de vez em quando" e nunca por sorte? | — | `press_contacts`, `press_contact_window`, `press_entry_gap` |
| 4.7 | **Desengajamento**: provoque uma disputa (forte contra forte do boneco) ou uma pressão e, depois de meio segundo (F3: `disengage ready`), aperte `K` | sem vencedor: a lâmina escapa por baixo e corta por outro ângulo; custa 20 de Vigor; os corpos se afastam pouco; o rival fica preso 0,08 s e pode bloquear, aparar (tocar `L` na hora) ou esquivar | grupo Disengage do `BladeLockConfig`; o golpe: `data/characters/common/disengage.tres` |
| 4.8 | Treinos guiados › Disputa de lâminas, 3º passo | termina com um desengajamento | `data/lessons/guided_lock.tres` |
| 4.9 | **Reserva de Defesa**: Treino com o **Bastião** (Defesa 7), boneco atacando, segure `L` até o Vigor quase acabar | o último bloqueio que faltaria por pouco ainda segura (Vigor vai a zero); o seguinte quebra a guarda. Com a Sombra (Defesa 3) a guarda quebra assim que falta Vigor. F3 mostra `reserve` | `CombatConfig.defense_reserve_per_point` |

## 4b. Finalizações cinematográficas e próteses

Para ver cada uma, jogue Duelar com 1 round (ou o último round) e deixe o adversário quase sem vida. A opção Finalizações precisa estar ligada.

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 4b.1 | Avanço com corte (frente + `I`) que mata | rastro reto, você para atrás do adversário com a lâmina na horizontal; ele fica de pé um instante e a metade de cima desliza pelo corte em brasa e cai | grupo Finishers do `EffectsConfig` |
| 4b.2 | Investida descendente ou Corte ascendente que mata | corte vertical; as metades caem para os lados | idem |
| 4b.3 | Arremesso da lâmina que mata | corte diagonal na parte de cima | idem |
| 4b.4 | Corte de Fluxo que mata | corte na cintura | idem |
| 4b.5 | Raio segurado até matar | esqueleto piscando ~0,6 s, depois corpo carbonizado com fumaça | `xray_time`, `xray_flicker`, `char_time`; cores `xray_*` e `charred_body` do `UiPalette` |
| 4b.6 | Repulsão ou Repulsão Suprema que mata | estouro de brasa, corpo arremessado longe, cai deitado (sem sangue) | `blast_*`, `ember_*` |
| 4b.7 | Puxão com o adversário com 12 de vida ou menos | ele é puxado e cortado ao meio; as metades voam para trás de você | `PowerData.execute_below` (`pull.tres`), `finisher_fling_*` |
| 4b.8 | Estrangular até matar | brasa no pescoço e queda | `neck_embers` |
| 4b.9 | Partida de 2 rounds: vença o 1º com um forte | o adversário volta no 2º round com o braço (ou a perna) metálico | `UiPalette.prosthetic_metal` |
| 4b.10 | Opções › Finalizações desligada | nenhuma cinemática; queda comum | — |
| 4b.11 | Depois do K.O. decisivo, assista ao replay | a cinemática se repete igual | — |
| 4b.12 | **Forte parado** que mata, com Guardião (ou Sombra, Espelho, Brasa, Eco, Garça, Ancião, Predestinado, Soberano, Haste) contra quem usa lâmina simples | **duas lâminas**, etapas bem separadas: dois cortes rápidos (um antebraço cada); o cabo dele cai e quica; você estende a mão aberta, a bola aparece na palma, o cabo treme em anéis claros, sobe e voa girando até a mão, que acende na cor dele; as lâminas se abrem alta e baixa, pausam e fecham em X com dois rastros; a cabeça sai, o corpo fica de pé um instante, cai de joelhos e tomba; no fim a lâmina emprestada apaga e o cabo cai | `data/finishers/twin_blades.tres` (poses e instantes); `ConsequenceConfig.long_cinematic_ko_time`, `long_replay_tail` |
| 4b.12b | O mesmo forte parado contra **Vespa, Ceifador ou Haste** | desarme e execução (não há lâmina simples para pegar) | — |
| 4b.12c | **Forte de avanço** que mata (todos, salvo Vespa e Esgrimista) | **desarme e execução**: os dois antebraços saem, ele cai de joelhos; corte horizontal com rastro no pescoço; a cabeça rola e o corpo tomba para a frente. Ninguém escorrega pelo corpo | `data/finishers/execution.tres`; `ConsequenceConfig.execution_clearance` |
| 4b.13 | Forte da **Vespa** que mata | o mesmo desarme; as duas lâminas abrem para trás e se fecham em X no pescoço, com dois rastros | `data/finishers/scissors.tres` |
| 4b.12d | Forte de avanço da **Garça** que mata | **giro**: corte baixo girando, ela passa por trás dele em piruetas, corta na horizontal de costas, a lâmina sobe, ela fica composta enquanto o corpo cai; nunca parece parar | `data/finishers/whirl.tres` |
| 4b.12e | Duas lâminas com **Soberano, Sombra Desperta, Predestinado, Ancião e Garça** | a mesma coreografia com jeitos diferentes: Soberano lento e ereto; Sombra Desperta rápida e inclinada; Predestinado gira a lâmina pega; Ancião lento e econômico; Garça faz pirueta antes do X | `data/finisher_styles/<personagem>.tres` |
| 4b.12f | Ouça qualquer finalização em etapas | golpes, acertos, puxão, ignição e apagar da lâmina emprestada batem com a animação | deixas `cues` em `data/finishers/<kind>.tres` |
| 4b.13b | Forte parado de **Bastião ou Forja** que mata | **execução por cima**: ele é empurrado e cai de joelhos; você ergue a lâmina acima da cabeça, pausa e desce; o corte vertical abre as metades para os lados | `data/finishers/overhead.tres` |
| 4b.13c | Forte parado do **Ceifador** que mata | **giro duplo**: o primeiro giro do bastão leva os antebraços, o segundo passa pelo pescoço; ele cai de joelhos e tomba | `data/finishers/double_rotation.tres` |
| 4b.14 | Forte de avanço de **Espelho, Haste ou Soberano** que mata | **estocada**: a lâmina atravessa o peito, a ponta sai pelas costas, anel em brasa no peito; você segura, recolhe, e ele cai de joelhos e tomba para a frente | `data/finishers/stab.tres`; `stab_hole_radius` |
| 4b.15 | Último round: mate com o **rápido descendente** (1º da sequência na maioria) no chão | a cabeça sai | `ConsequenceConfig.cut_heights`, `head_line`, `leg_line` |
| 4b.16 | Partida de 2 rounds: vença o 1º com o mesmo rápido descendente | sai o braço, **nunca a cabeça** (ele volta no 2º com a prótese) | idem |
| 4b.17 | Último round: mate com um rápido ascendente o adversário **no ar** | sai a perna (o corte passa baixo nele) | idem |

## 4c. Exibição

Extras › Sequência de exibição (4c.1–4c.5) e Extras › Duelo de exibição (4c.6). Assista sem tocar em nada e depois repita pulando com Confirmar.

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 4c.1 | Duelo **Lâminas** (Guardião × Sombra) | cartão de título durante as entradas; guardas, choque de rápidos, disputa vencida pelo Guardião, esquiva precisa da Sombra com punição, esquiva com giro, parry perfeito com contra-ataque e as duas lâminas no fim | `data/exhibition/exhibition.tres` (ticks dos `cues`) |
| 4c.2 | Duelo **Fluxo** (Ancião × Sombra Desperta) | Raio segurado contra a Barreira, Avanço com corte bloqueado, choque de fortes, Ira, Telecinese em Massa com a câmera no céu e o Puxão que corta ao meio; nenhuma aura fica sobre o corpo depois da morte | idem |
| 4c.3 | Duelo **Dança** (Garça × Vespa) | pulo duplo por cima da Vespa, sequência de cinco da Vespa bloqueada, choque de fortes, esquiva com giro através da Rajada, punição e o giro da Garça no fim | idem |
| 4c.4 | Entre os duelos e no fim | fade do roteador e o próximo cartão; depois do terceiro, volta ao menu | — |
| 4c.5 | Confirmar durante um duelo; Pausa | Confirmar pula para o próximo; Pausa abre o menu de pausa e permite sair | — |
| 4c.7 | Corsária: sequência de três rápidos, forte e forte de avanço (Treino ou Duelo de exibição) | 1º rápido passa a lâmina por cima e para trás e sobe em concha; 2º arma sobre o ombro e corta à frente; 3º estoca; sem vaivém nem giro de 160° num quadro; follow-through visível | `blade_angle_*` em `corsair.tres`; `wrist_lag`, `follow_through` em `data/families/versatile.tres` |
| 4c.8 | Esquiva de precisão bem-sucedida e esquiva automática do Instinto Superior | brilho curto no peito na cor da lâmina, imagens residuais; a pose do Instinto entra rápido, segura e volta suave (~0,4 s); a de precisão segura e volta à guarda sem salto | `EffectsConfig.evade_glow_*`, `PowerVfxConfig.instinct_hold_*`, `PoseSolver.EVADE_*` |
| 4c.6 | Extras › Duelo de exibição: **Reflexo** (Corsária × Espelho) | cartão REFLEXO com rodapé "pular"; pingue-pongue de disparos, Espelho esquivando dos cinco disparos da Rajada com a esquiva de precisão, parries e choques, disputa encerrada pelo desvencilhar, Instinto Superior com três esquivas e contra-ataques, Repulsão, pulo duplo sobre as pedras, giro por trás, esquiva de precisão, Postura de Espera e a execução cruzada; volta aos Extras | `data/exhibition/showcase.tres` (ticks dos `cues`) |

## 5. IA

Duelar contra a IA no **Difícil** (Opções › Dificuldade).

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 5.1 | Encurrale a IA na parede e solte fortes colado | às vezes ela gira para o outro lado (esquiva com giro); no Fácil quase nunca | `AiDifficultyData.spin_dodge_chance`, `spin_dodge_corner`, `spin_dodge_open_ratio` (`data/balance/ai/difficulty_*.tres`) |
| 5.2 | Ganhe a contagem numa disputa contra a IA | no Difícil ela costuma desengajar quando está perdendo; no Fácil quase nunca | `disengage_chance` |
| 5.3 | Contra o Predestinado (Aurora ou Eclipse) no Difícil | ele segura o medidor e usa o quarto poder em vez de gastar em poderes menores | `save_for_fourth` |
| 5.4 | Monte um conjunto Personalizado com o Truque Mental para a IA (seleção, `P`) e jogue andando muito | ela lança o Truque Mental quando você está andando ou recuando com pouco Vigor, não quando você está parado | `controllers/ai/ai_powers.gd` (`_commits_to_a_direction`) |
| 5.5 | Sensação geral: a IA do Difícil está justa? Ela apara rápidos por reação (não deveria)? | — | `data/balance/ai/difficulty_*.tres` |

## 6. Áudio

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 6.1 | Duelar em cada uma das dez arenas | ambiência própria: vapor e ecos (Refino), água e gotas (Santuário), gotejar e cristal (Mina), chuva e cidade (Telhado), quase silêncio e zumbido (Anel), insetos e folhas (Floresta), vento quente e areia (Salinas), vento forte e motores (Convés), nevasca e sinos (Cume), salão vazio com eco (Cidadela). Volume no nível da antiga ambiência, sem estalo no laço | `tools/audio/synth_audio.py` (`arena_ambiences`) e regenerar; volume no barramento Ambience |
| 6.2 | Música em cada arena | três temas: duelo (Refino, Mina, Telhado, Anel, Salinas, Convés), sagrado (Santuário, Floresta, Cume) e chefe (Cidadela), cada arena com um tom diferente | tom: `pitch` em `data/audio/arena_music/*.tres`; temas: `themes()` no sintetizador |
| 6.3 | Duelar contra Soberano, Ancião ou Predestinado; Arcade até a Sombra Desperta | toca o tema de chefe; no despertar da Sombra (abaixo de metade da vida) a percussão e a tensão abrem | `CharacterData.theme`; `ModesConfig.boss_music_floor` |
| 6.4 | Disputa, pressão e desengajamento | o atrito da disputa começa na pressão e para no desengajamento | `presentation/audio/duel_audio.gd` |

## 6b. História: aparência e trajes

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 6b.1 | História › Nova campanha, no passo do caminho | Aurora em azul, Eclipse em vermelho | `UiPalette.aurora`, `eclipse` |
| 6b.2 | Passos traje, cabelo, barba, cor do cabelo e tom de pele com cada estilo (Técnica, Fúria, Voo) | a prévia muda a cada item; as combinações leem bem na grade (ex.: médio ondulado + barba cheia + armadura de placas clara) | arte: `tools/art/fighter_parts.py` (`hair_part`, `beard_part`, `plate`) e `python tools/art/paint_fighters.py guardian shadow heron`; cores: `data/story/campaign_data.gd`; trajes: `data/story/outfits/` |
| 6b.3 | Hub › Aparência | reabre só os passos de aparência e salva ao confirmar o tom de pele | `screens/story/story_new.gd` |
| 6b.4 | Campanha antiga (criada antes desta versão) | carrega com cabelo curto e sem barba | `CampaignData.default_hair` |
| 6b.5 | Predestinado, trajes Caído e Duelo (seleção, `C`) | antebraço da lâmina metálico; Duelo com túnica escura de gola alta | `data/characters/foretold/foretold.tres` (`prosthetic_arm`) |

## 7. Controles e textos

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 7.1 | Opções › **Teclas e botões** com um gamepad conectado: escolha uma ação e aperte um botão | o botão passa para a ação (o que estava nele troca de lugar); Start, Select e Guia são recusados; Restaurar padrão volta teclas e botões; vale para os dois gamepads | `core/input_bindings.gd` |
| 7.2 | Troque o idioma para English e passe pela História (diálogos) | inglês natural, sem trechos em português | falas: `content/STORY.md` e `python tools/story/make_story.py` |

## 8. Build Web

```
godot --headless --path . --export-release "Web" build/web/index.html
python -m http.server 8000 --directory build/web
```

Abra `http://localhost:8000` (Chrome e Firefox). **Esperado**: carrega, áudio sem chiado forte, gamepad funciona, a opção Sair não aparece, progresso fica salvo depois de recarregar a página. O pacote cresceu para ~4,7 MB por causa do áudio novo.

## 9. Pontos conhecidos para julgar

- **Equilíbrio**: na matriz IA × IA do Difícil, Ceifador (77%) e Garça (76%) dominam e Forja (21%) e Haste (27%) sofrem; o Guardião vence a Sombra quase sempre. Isso vem da IA contra IA. Vale jogar com Forja e Haste contra a IA e dizer se o problema aparece para um humano. Detalhes no ROADMAP (Pendências).
- **Pressão de lâminas** quase não acontece entre duas IAs; o que importa é se aparece para quem joga.
- A **Varredura** foi removida; se algum save, desafio ou texto ainda a citar, é bug.

## Como devolver

Para cada item ⚠️ ou ❌, escreva: número, personagem, arena, o que fez, o que esperava e o que aconteceu. Um vídeo curto ou print ajuda muito nos itens de animação.

## Tasks 01–03 — Progressão e Corte Projetado

| Caso | Ação | Resultado esperado | Validação automatizada/local |
| --- | --- | --- | --- |
| 01.1 | Seleção: editar Frente, Trás ou Ar até Corte Projetado, nos dois caminhos | Uma onda, 24 de Vigor, sem custo de Fluxo; lâmina permanece na mão | Testes de simulação e catálogo; 32 capturas em `build/task01_renders/` |
| 01.2 | Bloquear, devolver com parry perfeito e matar no K.O. decisivo | Guarda gasta Vigor; onda troca dono/cor; corte na cintura; Arsenal intercepta | Testes e contact sheet inspecionada |
| 01.3 | Carregar campanha antiga com `flow_cleave` | Id removido é descartado sem erro; espaço preenchido com poder conhecido | Teste de migração |
| 02.1 | Vencer, perder e repetir um duelo da História | +3 na vitória, +1 na derrota, +1 adicional no marco vencido; atributos separados | Testes de campanha e de StoryMode; captura `loss_1280.png` |
| 02.2 | Comprar nós dos dois ramos e tentar equipar suprema abaixo do tier | Compra cobra o saldo e exige o pai; equipamento exige Fluxo 4/7, conforme o recurso | Testes do modelo; três campanhas renderizadas em 720p e 1080p |
| 02.3 | Carregar save com poderes antigos | Poderes conhecidos permanecem comprados, saldo inicial zero, sem reembolso | Teste de migração |
| 02.4 | Jogar encontros 6–8 nos dois caminhos com supremas | Poderes equipados obedecem ao tier; conferir desafio do 7E | Sonda IA × IA, 36 duelos; campanha humana ainda pendente |
| 03.1 | Criar os três estilos e usar Frente, Trás, Ar e Habilidade antes/depois de comprar | Só Frente começa disponível; cada compra libera o próprio comando; espaço vazio não usa a habilidade | 7 testes da árvore de Lâmina; 72 duelos iniciais, 65 vitórias, zero inconclusos |
| 03.2 | Comprar Corte Projetado e escolher cada espaço; restaurar a técnica do estilo | A onda substitui um único espaço, respeita o limite de ataque no ar e salva a escolha | Testes nos dois caminhos e três espaços; capturas do seletor e duelo real em `build/task03_renders/` |
| 03.3 | Carregar save anterior às árvores | Quatro nós do kit continuam disponíveis sem custo; Corte Projetado segue por comprar | Teste de migração nos três estilos |
| 03.4 | Trocar abas, navegar e comprar por teclado, mouse e gamepad | Foco, legendas, saldo e kit corretos nas duas abas; botões de menu preservam teclas | Cena gráfica com eventos sintéticos; teste de bindings idempotentes; dispositivo físico ainda pendente |
| 03.5 | Conferir ícones e estados em 720p/1080p e em cinza | Sem corte de legenda, seleção/equipamento/tier distinguíveis sem cor; onda na cor da lâmina | 22 PNGs e overview/contact sheet inspecionados; glifos em `icons.png` |

## Task 04 — Instinto Superior

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| 04.1 | Ancião ativa contra rápidos, forte, estocada e ascendente da Sombra | Quatro movimentos distintos, sem teleporte; rápido abre contra-ataque por 0,35 s | 9 testes novos; duelo real, 40 PNGs e `build/task04_renders/contact_sheet.png` inspecionados |
| 04.2 | Usar área, empurrão, pedras, agarrão ou poder contra o status | Exceções passam; dano efetivo de poder apaga aura e janela; Santuário que absorve tudo preserva | Testes e Repulsão de Fluxo equivalente na captura |
| 04.3 | Atacar com as duas lâminas, salvar/restaurar e deixar expirar | Choques/disputas preservados, replay idêntico, timers zeram | Suíte completa: 339 passando, zero falhas |
| 04.4 | Equipar na História/Galeria abaixo e acima do Fluxo 7 | Aurora nó 12 custa 4, exige o nó 11; compra possível antes do tier, equipamento só em Fluxo 7+ | Testes de catálogo e árvore; gerador atualizado |
| 04.5 | Jogar com efeitos reduzidos e enfrentar IA | Aura discreta permanece; IA usa poderes ou espera e não insiste em lâminas | Capturas reduzidas e teste de 180 ticks; avaliação humana da sensação pendente |

## Task 05 — Singularidade Devastadora

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| 05.1 | Soberano invoca contra Guardião parado | Criação, subida, aviso de 0,65 s, placas, atração aérea, formação e arremesso; piso visível | 100 PNGs em `build/task05_renders/`, a cada 0,25 s; quatro contact sheets inspecionadas |
| 05.2 | Correr entre avisos e esquivar cruzando a trajetória final | Marca fixa fica para trás; esquiva invulnerável e sair da trajetória evitam; não pular | Capturas 1_* e 3_*: Guardião termina com 108/108 de vida, efeitos completos/reduzidos; teste de simulação de corrida, trajetória e esquiva |
| 05.3 | Defender com guarda, Barreira, Absorção, Arsenal, Santuário ou Instinto | Massa atravessa as primeiras quatro; Santuário absorve vida; Instinto não evita | Testes específicos das seis interações |
| 05.4 | Acertar durante criação, matar o lançador, salvar/restaurar durante marcas | Criação interrompida; morte cancela campo/marcas; replay idêntico | Testes, incluindo cópia independente das recargas no snapshot |
| 05.5 | Pedir ataque e outro poder durante campo; mover e defender | Ataques recusados; deslocamento/defesa/esquiva possíveis; lançador vulnerável | Teste do bloqueio de ações e interrupção |
| 05.6 | Galeria: tier abaixo de III, status, Singularidade com Finalização ligada | Gate Fluxo 7, espera pelas fases; alvo sobrevive às extrações e morre em BLAST na massa final | Oito capturas em `build/task05_gallery/`, testes dinâmicos de todas as finalizações; nó 12 Eclipse custa 4 e depende do 11 |
| 05.7 | IA no Difícil com as duas supremas equipadas | Reserva medidor, lança a média distância, sai das marcas, esquiva da massa sem salto/guarda | 14 testes novos; 72 duelos adicionais, 36 lançamentos, nenhum inconcluso |
| 05.8 | Experimentar saídas perto das bordas, evitando correr junto da massa | Sempre escolher passagem antes de a placa subir; invulnerabilidade exige momento correto | Sonda de 32 sementes/distâncias: parado atingido em 32/32; controlador heurístico de corrida/esquiva sem dano em 19/32. As 13 falhas reforçam a necessidade de validar legibilidade e tolerância com jogador humano; não é garantia de fuga automática |

Suíte final das tasks 04–05: **353 testes passando, zero falhas** (`build/task05_tests_final.log`). Matriz padrão de 660 duelos mantém exatamente vitórias e contatos anteriores. Renderização executada na Godot 4.7.2; continuam pendentes avaliação humana de sensação, áudio e controle físico.

## Task 06 — Disparos e desvio

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| 06.1 | Treino com Poderes, F5 até "atirando"; fique parado | Disparo curto e claro sai da mão do boneco a cada 1,2 s; acerta com 4 de dano e um tranco curto, sem empurrão | `build/batch10/renders/bolts/hit_*` |
| 06.2 | Segure a guarda de frente | O disparo se desfaz na lâmina com faíscas claras; 4 de Vigor; a lâmina vai na linha do disparo | `guard_*` |
| 06.3 | Toque a guarda um pouco antes (parry) | Volta pela mesma linha, na cor da sua lâmina, e acerta o boneco | `parry_*`; teste `test_parry_sends_the_bolt_back_along_its_line` |
| 06.4 | Toque no último instante (parry perfeito) | Anel pequeno; o disparo volta mais rápido, mirado no peito do boneco | `perfect_*`; teste do parry perfeito |
| 06.5 | Comece um forte quando o disparo estiver chegando | Leva o dano e o forte continua | teste `test_bolt_never_interrupts_an_attack` |
| 06.6 | Com uma gravação feita (F6), passe por todos os comportamentos com F5 | Ciclo parado → em guarda → atacando → atirando → reproduzindo, sem erro | correção do ciclo |
| 06.7 | Julgar velocidade (900 u/s) e dano (4) | Dá para reagir de meia distância; disparo incomoda sem decidir a luta | ajuste em `data/bolts/standard_bolt.tres` |

## Tasks 07 e 08 — Família Versáteis (Corsária e Lince)

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| 07.1 | Duelar com a Corsária: três rápidos de perto | O segundo corte também dispara; o blaster sobe e volta ao quadril | `build/batch10/renders/versatile/corsair_kit_*`; teste do passo 2 |
| 07.2 | Frente + Habilidade de longe; Trás + Habilidade com o rival encostado | Dois disparos seguidos; recuo de ~110 u atirando para a frente | testes de Disparo duplo e Recuo com disparo |
| 07.3 | Corsária: Frente + Habilidade | Cinco disparos (gastam Vigor, não Fluxo) e um avanço com corte que sai sozinho; finalização atravessando no K.O. decisivo | teste da Rajada |
| 08.1 | Lince: segurar a guarda e apertar Frente + Habilidade | O tiro sai da guarda, o emissor do cabo brilha | `lynx_kit_*`; teste do tiro de guarda |
| 08.2 | Seleção: editor de técnicas com o Guardião e com a Corsária | Técnicas de disparo só aparecem para a Corsária | teste do editor |
| 08.3 | Comparar os dois em duelos | A Corsária atira muito; o Lince quase só de perto | teste de disparos por duelo; matriz 55,6% / 54,2% |
| 08.4 | Julgar silhuetas, introduções e o blaster pequeno | Silhuetas distintas (casaco curto e rabo de cavalo × sobretudo longo); blaster legível no tiro | `corsair_intro_*`, `lynx_intro_*` |

## Ajustes depois das tasks 07/08

| Caso | Ação | Resultado esperado |
| --- | --- | --- |
| A.1 | Forte da Corsária no K.O. decisivo | Execução Cruzada: antebraços, joelhos, disparo no peito, queda para trás, giro e lâmina apagada |
| A.2 | Forte do Lince no K.O. decisivo | Sentença Precisa: corte diagonal, passa para trás, vítima se vira, disparo do cabo, queda para a frente, lâmina apagada |
| A.3 | Disputa contra (ou com) o Soberano | Ele segura a lâmina do rival com a palma e anéis de Fluxo; vencendo, empurra com uma onda |
| A.4 | Galeria: ir até a Rajada Desestabilizadora | "Carregando" no fade; a Corsária assume e lança |
| A.5 | Seleção: editor de técnicas do Guardião | Técnicas de disparo não aparecem |

## Ajuste — Esquiva de precisão contra disparos e novo Congelar

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| E.1 | Treino contra o boneco atirador (ou Corsária/Lince): baixo no instante em que o disparo chega | Esquiva bem-sucedida, livre na hora, disparo segue reto sem acertar | `test_precision_evade_slips_a_bolt_and_frees_the_defender` |
| E.2 | Contra uma rajada, esquivar cada disparo | Sequência sobe a cada sucesso; cada esquiva seguinte inclina diferente da primeira; errar o tempo leva o disparo | testes de rajada e de esquiva atrasada; capturas `build/freeze_evade/evade_*.png` |
| E.3 | Lançar Congelar (Galeria ou Ancião) e quebrar com um golpe | Sem casca ou círculo em volta do alvo; ondulação da palma ao alvo, corpo travado tremendo, fios de ar, partículas paradas, faíscas nas mãos/cabeça; partículas se espalham na quebra | capturas `build/freeze_evade/freeze_*.png` |
| E.4 | Repetir E.3 com efeitos reduzidos | Só tremor e fios | — |
| E.5 | Esquivar um disparo no último instante, colado no contato | Dano anulado **e** inclinação + imagens residuais visíveis | `test_evade_on_the_contact_tick_*`, `test_evade_success_holds_*`; capturas `build/freeze_evade/late_evade_*.png` |

## Ajuste — Tempestade Tier III e menu Duelar

Validado pelo autor em 2026-11-01: D.1–D.4 ✅.

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| D.1 | Galeria ou História com Fluxo 7–9: lançar a Tempestade | Cada raio abre fissuras para os dois lados; pular evita; força parece justa para o Tier III | teste `test_storm_bolts_open_fissures_from_tier_three` |
| D.2 | Jogar › Duelar; percorrer 1 Jogador, 2 Jogadores, CPU vs CPU e Voltar | Submenu com nome DUELAR; Voltar retorna a Jogar com Duelar em foco; seleção volta ao submenu | smoke gráfico 720p |
| D.4 | Jogar › Batalhas e Jogar › Modos especiais; entrar e sair da Caçada e da Infiltração | Jogar só com quatro entradas e espaçamento padrão; voltar das telas próprias cai no submenu certo com o modo em foco | smoke gráfico 720p |
| D.3 | CPU vs CPU: escolher dois lutadores e arena, assistir, pausar, Revanche | IA luta dos dois lados; pausa sem lista de golpes; FIM DO DUELO com vencedor; nada desbloqueia | smoke até o resultado; avaliar ritmo assistindo |

## Task 12 — Missões de Infiltração

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| 12.1 | Jogar › Infiltração; percorrer quatro briefings com teclado/gamepad/mouse | Tutorial, sabotagem, arquivo e resgate; objetivos, controles atuais, recordes e bônus legíveis em PT/EN; não há entrada temporária em Aprender | rotas pelo MCP e capturas 720p/1080p; avaliar controle físico |
| 12.2 | Primeiro acesso: interagir com painel e voltar à saída | Objetivo marca 1/1; saída só conclui depois da interação | duas rotas automatizadas; resultado Furtivo mesmo após combate sem alarme |
| 12.3 | Rede silenciosa: desligar os dois painéis, evitando ou enfrentando guardas | Ambos são obrigatórios; alarme chama reforços e não derrota sozinho | rotas furtiva/agressiva; abordagem Direto conserva histórico após sirene parar |
| 12.4 | Arquivo frio: tentar sair antes de copiar; copiar e extrair | Sair cedo não encerra; terminal exige alcance e linha livre; painel opcional | testes de objetivo e parede; duas rotas completas |
| 12.5 | Caminho de volta: recrutar, correr, voltar e aguardar escolta | Prisioneiro navega sem teleporte, para perto do jogador e precisa chegar vivo à saída; HUD mostra estado e vida | duas rotas; limites de deslocamento, paredes e snapshot; avaliar sensação humana |
| 12.6 | Receber disparo letal ou deixar prisioneiro ser atingido; tentar de novo | Motivo correto de derrota; nenhuma gravação; retry restaura toda a tentativa | testes de dano, derrota simultânea à extração e capturas dos dois resultados |
| 12.7 | Vencer sem alarme/abates/no tempo, repetir mais devagar com outro bônus e reabrir | Menor tempo preservado; bônus acumulados; sem moeda, grind ou atributos | testes de save novo/antigo, resultado selado e recarga gráfica |
| 12.8 | Pausar, voltar, reiniciar, usar Próxima e sair da última missão | Relógio e mundo congelam na pausa; controle pendente é descartado; retorno conserva seleção; última volta à lista | 47 verificações por resolução, InputMap pelo MCP; julgar áudio ouvido |

Evidências em `build/task12_renders/` (82 capturas e dez folhas), `build/task12_mcp_renders/`, `task12_tests_final.log`, `task12_mcp_compile_checks.json` e `task12_assets_check.log`. Capturas usam `capture_progress.cfg`; os testes diretos isolam APPDATA em `build/task12_userdata`. A aprovação humana de controle/áudio e a meta de 60 FPS estáveis permanecem pendentes.

## Task 13 — Treino de voo

| Caso | Ação | Resultado esperado | Validação local |
| --- | --- | --- | --- |
| 13.1 | Abrir `screens/space/space_training.tscn` e F6; testar teclado e gamepad | Nave em vista superior, controles remapeados do J1, sem nova entrada de menu | 28 verificações gráficas de fluxo e InputMap pelo MCP; controle físico pendente |
| 13.2 | Propulsionar, soltar, girar e dar ré | Inércia decresce, giro muda a direção de empuxo, ré mais fraca; sem atravessar corpos/bordas e sem dano de contato | testes de matemática, limites e colisões; capturas em duas resoluções |
| 13.3 | Segurar primária e destruir um drone | Três acertos, uma explosão curta e reaparecimento após 3 s, adiado com ponto ocupado | testes de dano, cadência, pool, alcance e percurso relativo; capturas/MCP |
| 13.4 | Cruzar tiros com impulso, observar início e fim | Janela de 0,05 a 0,20 s invulnerável; preparação/cauda vulneráveis, sem atirar/girar e com recarga | testes dos limites inclusivos, dano e bloqueio de ações; imagens completas/reduzidas |
| 13.5 | Esperar um disparo e o escudo recuperar | Drone avisa; escudo absorve antes do casco, excedente atravessa; regeneração após 2 s sem acerto | testes e capturas de aviso, escudo e casco; julgar áudio ouvido |
| 13.6 | Tocar secundária, pausar com arma segurada, reiniciar e sair | Aviso de indisponível; pausa congela tudo e exige soltar; retry limpa estado; volta a Modos especiais sem alterar outros bindings | três reaberturas com câmera ativa; saves preservados |
| 13.7 | F3 e efeitos reduzidos; conferir PT/EN a 720p/1080p | Velocidade e círculos físicos visíveis; janela/aviso permanecem claros sem ecos; HUD e pausa sem corte | 38 capturas e duas folhas em `build/task13_renders/`, cinco capturas nativas MCP |
| 13.8 | Pilotar continuamente na máquina de referência | Voo e áudio confortáveis, nave, tiros e aviso legíveis; sem travamento | amostra GT 730 com editor aberto: 59,9 FPS, pior quadro 18,1 ms, 19 draw calls; validação humana e 60 FPS sustentados pendentes |

### Task 14 — missões de naves, capitais, chefe e oficina

Automação concluída; avaliação humana de controle, dificuldade e áudio pendente. Entrar por Jogar › Modos especiais › Combate de naves. Os controles são os bindings atuais do J1; K é a secundária no padrão.

| ID | Ação | Resultado esperado | Evidência automática |
| --- | --- | --- | --- |
| 14.1 | Abrir seleção, ler os cinco briefings e voltar | Cinco missões disponíveis, retorno a Modos especiais com Combate de naves em foco | fluxo roteado 720p, capturas nas duas resoluções |
| 14.2 | Jogar Corredor aberto | Cunha de três caças, depois dois interceptadores; intenção e entrada determinísticas | piloto base vence, formação ocupada adia slot, captura do esquadrão |
| 14.3 | Jogar Rastro de cinza e cruzar destroços | Leque legível, míssil sólido guiado, primária pode interceptar; impulso evita dano só na janela interna; detrito bloqueia corpo e tiro | colisões varridas, guia limitada, alvo fixo e esquiva testados; capturas de míssil inimigo/detrito |
| 14.4 | Defender a capital em Última escolta | Casco aliado pode receber tiros; chegar a zero encerra a tentativa | vitória normal e derrota por aliado, prioridades e congelamento testados |
| 14.5 | Atacar Cortar a rede | Gerador retira escudo/recarga; motor reduz giro; torres independentes continuam até serem destruídas | seções independentes e vitória por comandos; captura após gerador |
| 14.6 | Jogar Ferro de maré inteiro | Superior → inferior → centro; proteção cruzada e abertura segmentada; três padrões com preparação | três fases uma vez, limites inclusivos/exclusivos e tiros antigos preservados; vitória também no MCP |
| 14.7 | Comprar Arma, Escudo e Propulsão, repetir vitória e redistribuir | Um ponto por primeira vitória, custo/limites claros; repetição não duplica ponto; redistribuição gratuita | stats isolados, saldo, limites, persistência e migração testados; oficina PT/EN |
| 14.8 | Pausar segurando tiro, reiniciar e sair | Tick/tempo congelados, soltar antes de novo tiro, nova tentativa limpa; aliases removidos ao sair | entrada pelo MCP, pausa no tick 22 e retomada/reinício nas capturas |
| 14.9 | Ler HUD, resultado, oficina e F3 em PT/EN, 720p/1080p | Objetivos, tempo, avaliação, casco aliado e recarga de míssil sem corte; núcleo e preparação legíveis | folhas em `build/task14_renders/`; 38 scripts válidos pelo MCP |
| 14.10 | Rodar por vários minutos na máquina de referência e ouvir os avisos | Controle confortável, sons distinguíveis, 60 FPS sustentados | amostra com editor aberto: 59,9 FPS, pior quadro 18,18 ms, 24 draw calls; simulação 466,76 µs/tick; ainda requer avaliação humana e medição sustentada |

Suíte: 536 testes, zero falhas; 42 novos, incluindo reutilização dos mesmos objetos de nave/evento/projétil/intenção e contagem de objetos estável por 3.000 ticks após aquecimento. Evidências em `build/task13_tests_final.log`, `task13_bindings_final.log`, `task13_mcp_compile_checks.json`, `task13_assets_check.log`, `task13_flow_smoke.log` e `task13_profile.log`. Nenhuma gravação no save do autor; capturas usam `capture_progress.cfg` e processos diretos isolam APPDATA em `build/task13_userdata`.

## 15. Revisão de Infiltração e Combate de naves

Infiltração:

- 15.1 Abrir qualquer missão: o mapa aparece, WASD move e o personagem não fica preso.
- 15.2 Com a mão direita no mouse, usar E (interagir), F (abate), C (furtivo), Shift (correr), Q (guarda) e Espaço (golpe) sem tirar a mão esquerda do lugar.
- 15.3 Segurar a guarda e girar o mouse: o cabo fica na mão direita, a lâmina cruza à frente do corpo e nada gira pelo centro. A transição é rápida, sem salto.
- 15.4 Em Personagem, trocar personagem, traje (← →) e cor da lâmina (V), confirmar e conferir em missão. Vespa com duas lâminas, Ceifador com lâmina dupla, Haste com cabo longo.
- 15.5 Jogar as cinco missões: a primeira deve ser curta e as demais levar de 3 a 6 minutos. A dica de objetivo deve levar pelo caminho certo, não através de paredes.
- 15.6 Conferir se dá para concluir sem alarme e sem abates: o teste automático só comprova a conclusão sem alarme em duas missões, e abatendo guardas que o notam.

Naves:

- 15.7 Encostar em caças, na capital aliada e em seções: o escudo cai, o casco não, e o impulso na janela certa evita o custo. Encostar em detritos não custa nada.
- 15.8 Perder o escudo jogando normalmente deve ser comum, e perder a missão, possível. Se ficar difícil ou fácil demais, ajustar valores em `tools/space/make_missions.py`.
- 15.9 No Hangar, voar com Trama, Agulha, Bigorna e Lança: cada uma deve ter sensação própria, e os pontos fracos devem pesar.
- 15.10 Na Última escolta, parar de ajudar deve fazer a capital aliada cair.
- 15.11 Jogar as seis missões: 3 a 5 minutos cada, e o chefe deve morrer sem esperar mais escoltas.

Menus:

- 15.12 Em 720p e 1080p, em PT e EN: imagem e texto sem sobrepor, nos menus e nos resultados dos dois modos.
- 15.13 Duelo e História: abrir Guardião, Sombra, Garça, Vespa, Ancião e Sombra Desperta com trajes e cores, que tinham sido afetados pela perda de dados.

