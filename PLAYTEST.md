# PLAYTEST — Roteiro de validação

Roteiro para o autor validar, jogando, o que entrou na fase 7.5 (revisão de combate e animação) e no começo da fase 8. Cada item diz **como testar**, **o que deve acontecer** e **onde ajustar** se não estiver bom. Anote o número do item e o que sentiu; o agente seguinte corrige a partir disso.

Legenda: ✅ ficou bom · ⚠️ funciona mas a sensação ou o número precisa de ajuste · ❌ não funciona.

## 0. Preparação

1. Feche o editor e rode, na pasta do projeto:
   ```
   godot --headless --path . --import
   godot --headless --path . --script res://tools/run_tests.gd
   ```
   **Esperado**: suíte sem falhas (262 testes após as introduções).
2. Abra o jogo pelo editor (F5). Na tela de abertura, digite o segredo **O Equilíbrio** (← ← → → ↑ ↓ ↑ ↓) para liberar os secretos e a variante Eclipse do Predestinado. Isso grava o save real; se não quiser, use um perfil de usuário de teste ou faça backup de `user://progress.cfg`.
3. Teclas padrão do J1: `A`/`D` andar, `W`/`Espaço` pular, `J` rápido, `K` forte, `L` guarda (tocar apara), `Shift` esquiva, `S` esquiva de precisão, `I` habilidade (frente ou trás + `I` = técnicas), `U` poder, `U`+`I` quarto poder, `F3` debug. No Treino: `F5` comportamento do boneco, `F6` gravar, `F7` reproduzir.
4. Deixe o **F3** ligado nos testes de regra: ele mostra estado, fase do golpe, `contacts` (contador da Pressão), `cinematic`, `reserve` (reserva de Defesa) e `disengage ready`.

## 1. Correções

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 1.0a | Tutorial, passo da disputa: fique perto e aperte forte; depois pressione rápido. Repita o Treino guiado da disputa até o fim | o boneco espelha um tick depois; os fortes comprometidos iniciam disputa sem dano; Tutorial avança para Habilidade; treino completa três disputas, uma pressão e um desengajamento | `CombatConfig.clash_window`, `BladeLockConfig` |
| 1.0b | Em 2 Jogadores, fortes próximos separados por 1–4 quadros; depois separados por mais de 4; teste rápidos e técnicas | dentro da janela há choque/disputa; fora dela o mais rápido ainda acerta; duas preparações sem ativo não chocam; nenhum ativo atrasado acerta após o choque | `ClashResolver`, 0,067 s arredondados a quatro ticks |

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
