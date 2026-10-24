# PLAYTEST — Roteiro de validação

Roteiro para o autor validar, jogando, o que entrou na fase 7.5 (revisão de combate e animação) e no começo da fase 8. Cada item diz **como testar**, **o que deve acontecer** e **onde ajustar** se não estiver bom. Anote o número do item e o que sentiu; o agente seguinte corrige a partir disso.

Legenda: ✅ ficou bom · ⚠️ funciona mas a sensação ou o número precisa de ajuste · ❌ não funciona.

## 0. Preparação

1. Feche o editor e rode, na pasta do projeto:
   ```
   godot --headless --path . --import
   godot --headless --path . --script res://tools/run_tests.gd
   ```
   **Esperado**: `Tests: 213 passed, 0 failed`.
2. Abra o jogo pelo editor (F5). Na tela de abertura, digite o segredo **O Equilíbrio** (← ← → → ↑ ↓ ↑ ↓) para liberar os secretos e a variante Eclipse do Predestinado. Isso grava o save real; se não quiser, use um perfil de usuário de teste ou faça backup de `user://progress.cfg`.
3. Teclas padrão do J1: `A`/`D` andar, `W`/`Espaço` pular, `J` rápido, `K` forte, `L` guarda (tocar apara), `Shift` esquiva, `S` esquiva de precisão, `I` habilidade (frente ou trás + `I` = técnicas), `U` poder, `U`+`I` quarto poder, `F3` debug. No Treino: `F5` comportamento do boneco, `F6` gravar, `F7` reproduzir.
4. Deixe o **F3** ligado nos testes de regra: ele mostra estado, fase do golpe, `contacts` (contador da Pressão), `cinematic`, `reserve` (reserva de Defesa) e `disengage ready`.

## 1. Correções

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 1.1 | Extras › Galeria de poderes. Com ← → passe por **Dreno, Congelar, Truque Mental, Estrangular, Repulsão, Repulsão Suprema e Puxão**, nos tiers 2 a 4 (↑ ↓) | todos acertam o alvo parado: Dreno puxa o fio, Congelar prende no gelo, Truque Mental mostra os anéis sobre a cabeça, Estrangular ergue o alvo | distância da Galeria: `TrainingConfig.gallery_reach_ratio` (`data/balance/training_config.tres`) |
| 1.2 | Na mesma Galeria, passe pelas técnicas (depois dos poderes) | todas acertam o alvo; a Varredura não aparece mais na lista | — |
| 1.3 | Treino com a **Haste** e com o **Soberano**: `I` sozinho, a ~2 corpos de distância | Investida da Haste: haste recolhida no quadril, passo longo, braço esticado até a ponta; acerta de longe e o Ponto doce aumenta o dano na ponta | `data/characters/lance/lance.tres` e `sovereign.tres` (sub-recurso `*_ability_move`) |
| 1.4 | Contra a Haste no Treino, toque `L` na hora da Investida | é aparada como um forte (parry perfeito desequilibra a Haste) | — |
| 1.5 | Treino com **Brasa** (trás + `I`), **Eco** (trás + `I`) e **Predestinado Eclipse** (frente + `I`, variante com `V` na seleção) | Corte ascendente, Giro e Avanço com corte, respectivamente | técnicas em cada `data/characters/<id>/<id>.tres` |

## 2. Animação

Use Aprender › Treino com o boneco parado (`F5` alterna o comportamento). Troque de personagem pela seleção.

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 2.1 | Olhe a guarda parada de cada família | Guardião/Ancião/Predestinado: lâmina diagonal à frente do rosto, mão de trás no pomo · Esgrimista (Espelho, Haste, Soberano): braço da frente estendido, mão livre atrás na altura do ombro; o Espelho mantém a lâmina vertical · Agressor: Sombra com guarda baixa à frente · Colosso (Bastião, Forja): lâmina alta sobre o ombro · Dançarina (Garça): lâmina para trás · Vespa: uma lâmina alta à frente, a outra baixa e invertida atrás | guarda: `guard_angle` e `guard_grip` em cada personagem; mãos: `MotionFamily` em `data/families/*.tres` (`back_hand_spacing`, `free_hand`, `off_guard_hand`, `off_guard_angle`) |
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

Galeria de poderes (↑ ↓ mudam o tier, `T` troca o alvo, `X` troca o lançador).

| # | Como testar | Esperado | Onde ajustar |
| --- | --- | --- | --- |
| 3.1 | Repulsão | palma recolhe junto ao peito, depois o braço estende de uma vez com recuo do ombro; as ondas saem da palma | `PoseSolver._repulse`; origem das ondas: `PowerVfxConfig.repulse_palm_offset` |
| 3.2 | Puxão | mão estende aberta e fecha em garra puxando; fio de energia da mão até o alvo, encurtando enquanto ele é puxado; só um contorno curto no alvo; **sem bola atrás do alvo** | `PowerVfxConfig.pull_tether_time`, `pull_outline_time` |
| 3.3 | Raio nos tiers 3 e 4 (lançador Sombra) | 2 e 3 feixes abertos em leque, saindo dos dedos, separados no meio do caminho e chegando em alturas diferentes do corpo | grupo Lightning do `PowerVfxConfig` |
| 3.4 | Corte de Fluxo nos tiers 2 e 4 | preparação com a lâmina atrás da cabeça, arco inteiro até a lâmina bater no chão, onde nasce a onda; no tier 4 o segundo corte vem 0,35 s depois, também com o arco completo | `data/powers/flow_cleave.tres` (`apex_repeat_delay`) |
| 3.5 | Telecinese em Massa (Predestinado Aurora, `U`+`I` no Duelar, ou na Galeria no tier 3 ou 4) | câmera sobe (~0,45 s), meteoro é puxado e racha (~0,6 s), câmera desce acompanhando os pedaços (~0,45 s); o duelo fica congelado durante a subida e o meteoro (F3: `cinematic`); nada parece acelerado | congelamento: `data/powers/mass_telekinesis.tres` (`cinematic_freeze`); câmera e meteoro: `PowerVfxConfig.mass_rise`, `mass_hold`, `mass_descend`, `meteor_crack` |

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
