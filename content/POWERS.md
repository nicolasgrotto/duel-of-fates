# POWERS — O Fluxo e as técnicas de lâmina

Segue [GAME_DESIGN.md](../GAME_DESIGN.md). Efeitos visuais em [design/VFX.md](../design/VFX.md). Números são valores iniciais de calibração.

O **Fluxo** é a energia que atravessa as arenas e alguns duelistas. Dois caminhos o usam de formas opostas: a **Aurora** (proteção, cura, controle) e o **Eclipse** (dor, domínio, destruição). Parte dos poderes pertence aos dois, o **Fluxo comum**.

Os poderes são uma camada opcional do duelo (opção **Poderes**, ligada por padrão). Sem eles, o jogo é o duelo de lâmina puro.

## 1. Nível, tier e medidor

- **Nível do Fluxo**: o atributo Fluxo do lutador (1–7 no elenco; 8, 9 e 10 nos secretos). Define a potência, o ganho do medidor, a resistência aos poderes alheios e a cor da energia.
- **Tiers** (forma e cor da energia, nunca da lâmina):

| Tier (PT / EN) | Níveis | Cor | Quem |
| --- | --- | --- | --- |
| Tênue / Faint | 1–2 | azul-claro `#9cc4ff` | Bastião, Forja |
| Firme / Steady | 3–7 | azul `#5d8dff` | o resto do elenco |
| Profundo / Deep | 8–9 | roxo `#b26bff` | Ancião, Soberano |
| Ápice / Apex | 10 | vermelho `#ff2b45` | só o Predestinado |

  Tiers mais altos mudam a **forma**: mais feixes no Raio, ondas maiores, mais pedras, Barreira maior, mais objetos no Arsenal. Nunca escondem o alcance real do poder.
- **Medidor de Fluxo** (0–100): começa cada round em 20, enche devagar com o tempo e mais rápido ao acertar (+7), ser atingido (+9), bloquear (+4) e aparar (+10). Separado do Vigor.
- **Recarga compartilhada**: depois de qualquer poder, 1,2 s sem lançar outro (o Arremesso tem recarga própria por tamanho).
- Poder recusado (falta de medidor, recarga, nível mínimo) pisca o medidor e toca o som de ação recusada.

## 2. Comandos

Nenhum botão novo.

- **Poder** sozinho, **Frente + Poder** e **Trás + Poder** escolhem entre até três poderes (os espaços do conjunto). Espaço vazio cai no neutro.
- Poderes canalizados (Raio, Barreira, Absorção, Estrangular, Dreno) duram **enquanto o botão é segurado**, até o limite de tempo ou de medidor.
- **Habilidade** sozinha é a habilidade do personagem; **Frente + Habilidade** e **Trás + Habilidade** são técnicas de lâmina; **Habilidade no ar** pode ser uma técnica aérea.
- **Quarto poder** (só o Predestinado): Poder + Habilidade juntos, numa janela de 0,1 s em qualquer ordem. Nesses personagens, os comandos isolados aguardam a janela do acorde.

## 3. Interação pela diferença de Fluxo

Diferença = nível de quem lança − nível do alvo. **Nunca há sorteio**: falhar é sempre por limiar. Cada poder tem sua tabela de faixas em dados (escala do efeito, se a guarda vale, quanto dano e recuo passam pela guarda, custo de Vigor na guarda, escala de duração e desequilíbrio). A tabela básica:

| Diferença | Resultado |
| --- | --- |
| −1 ou mais | efeito normal |
| −2 | efeito reduzido (metade) |
| −3 ou menos | **resistido**: o poder bate numa barreira invisível e não tem efeito |

A Repulsão usa uma tabela própria, simétrica:

| Diferença | Sem guarda | Com guarda |
| --- | --- | --- |
| +3 ou mais | normal | **imbloqueável**: empurra, causa dano e desequilibra |
| +2 | normal | segura, mas metade do dano passa, o defensor desliza o dobro e gasta 1,5× o Vigor |
| +1 | normal | segura com um quarto do dano e 75% do deslize |
| 0 | normal | segura sem dano, com metade do deslize |
| −1 | normal | segura sem dano, 35% do deslize e 0,75× o Vigor |
| −2 | metade do dano e do desequilíbrio, **não empurra** o mais forte | não desliza, gasta metade do Vigor |
| −3 ou menos | resistida | resistida |

## 4. Regras gerais

- Quem lança fica **vulnerável na preparação**: um golpe interrompe o poder.
- Esquiva e esquiva de precisão com invulnerabilidade **fazem o poder passar** (exceção: Fratura). O dash aéreo não tem invulnerabilidade.
- **No ar** não há guarda contra poderes, e o alcance vertical cobre o pulo duplo. Quem está no ar sofre mais: a Repulsão empurra 30% mais e desequilibra 20% mais, o Puxão desequilibra 20% mais, o Raio prende 60% mais a cada pulso.
- Repulsão, Puxão e Raio não têm projétil: o efeito é decidido no instante ativo ou a cada pulso. Arremesso, Arremesso da lâmina, Corte de Fluxo e objetos do Arsenal são projéteis.
- **Dano efetivo** de qualquer categoria, inclusive periódico, interrompe a Cura; dano absorvido não interrompe.
- **Poderes de custo alto** ganham uma marca fina no medidor, no ponto do custo, que acende numa cor própria quando dá para lançar (ver UI_UX).
- Cada poder tem uma pose própria: lançar (lâmina para trás, corpo à frente), canalizar (tremor leve), invocar (mão livre erguida ao céu), golpear o chão, segurar à distância.

## 5. Catálogo

### Fluxo comum (os dois caminhos)

| Poder (PT / EN) | Custo | Resumo |
| --- | --- | --- |
| **Repulsão** / Repulse | 40 | Onda de choque à frente (alcance 320 u) que empurra para longe. Força pelo tier: 950 / 1150 / 1400 / 1650 u/s. Com Fluxo bem maior, atravessa a guarda. |
| **Puxão** / Pull | 40 | Puxa o oponente para perto e o desequilibra. Alcance pelo tier: 330 / 380 / 430 / 480 u. Na guarda, sem dano e puxa pela metade. |
| **Arremesso** / Throw | 30–48 | Arranca pedras do chão e as lança em linha reta (alcance 700 u). Tamanho pela faixa de Fluxo (tabela abaixo). Some ao bater na parede. |
| **Truque Mental** / Mind Twist | 30 | Inverte **só a direção** do alvo (andar e a escolha frente/trás de poderes e técnicas) por 0,8 s, reduzido pela tabela. Alcance 320 u. Ataque, guarda, esquiva e pulo não mudam. Vale igual para jogador e IA. |
| **Repulsão Suprema** / Supreme Push | 60 | Onda em volta do corpo todo (240 u). Pode ser lançada **enquanto o lutador apanha**: como fuga, 4 de dano; livre, como ataque, 14. Guarda e resultado pela tabela da Repulsão. Recarga própria de 6 s. Custo alto. |
| **Fratura** / Fracture | 70 | Golpeia o chão: uma rachadura corre à frente até a parede, cada trecho fica rachado ~0,25 s e explode. Só acerta quem está no chão: **a única saída é pular**. Guarda, Absorção, Barreira e até a esquiva invulnerável não seguram. Custo alto. |

**Arremesso por faixa de Fluxo**

| Fluxo | Tamanho | Dano | Velocidade | Custo | Recarga |
| --- | --- | --- | --- | --- | --- |
| 1–3 | pequeno | 6 | 760 | 30 | 1,0 s |
| 4–5 | médio | 8 | 700 | 34 | 1,1 s |
| 6–8 | grande | 11 | 620 | 40 | 1,3 s |
| 9 | muito grande | 14 | 560 | 44 | 1,4 s |
| 10 | máximo | 17 | 520 | 48 | 1,5 s |

Valem a tabela de interação, a guarda de frente (um quarto do dano passa), a Barreira (absorve) e a invulnerabilidade da esquiva (passa através). Quantidade de pedras pelo tier: 1, 2, 3, 4.

### Aurora

| Poder (PT / EN) | Custo | Resumo |
| --- | --- | --- |
| **Barreira** / Barrier | 10 + 38/s | Segurado: domo grande em volta do corpo que segura lâminas e poderes, até 1,5 s. Contra a Repulsão, segura mas recua. Cada pulso de Raio segurado drena 5 de medidor; cada raio da Tempestade, 30. Cai quando o medidor acaba. |
| **Cura** / Heal | 40 | Devolve vida ao longo de 2 s, até 14 × potência e nunca mais que 35% da vida perdida. Fecha ferimentos se completar. Ser atingido interrompe. Pode ser lançada com vida cheia. |
| **Foco** / Focus | 35 | Por 4 s × potência, atacar, bloquear e esquivar custam metade do Vigor; habilita o Foco automático (GAME_DESIGN). |
| **Absorção** / Absorption | 10 + 20/s | Segurada até 1,5 s: absorve **qualquer poder** que chega, pulso a pulso no caso do Raio (como a troca de raios entre dois mestres), reduzindo ou anulando pela diferença de Fluxo e convertendo parte da energia em medidor. Não segura lâmina e não absorve a Tempestade. |
| **Santuário** / Sanctuary | 65 | Escudo colado ao corpo que absorve 20 × potência de dano enquanto o lutador age normalmente, por até 6 s. Racha conforme absorve e se quebra no limite. Custo alto. |
| **Telecinese em Massa** / Mass Telekinesis | 80 (Fluxo 6+) | Mini-cinemática na invocação (~0,8 s, interrompível, sem pausar o duelo): a câmera recua, um asteroide aparece no céu, é puxado e racha. Os pedaços caem sobre marcas no chão (5, 6 ou 7 impactos pelo tier, 7 de dano cada, com empurrão). Quem lança pode se mover, mas não atacar, durante a chuva. Sem céu à vista, fragmentos conjurados. Custo alto. |
| **Corte de Fluxo** / Flow Cleave | 20 | Um corte de cima para baixo solta uma onda em meia-lua que viaja em linha reta (520 u). Pode ser esquivada, bloqueada e **devolvida por um parry perfeito** (o projétil volta contra quem lançou). No Ápice, dois cortes em sequência, descendo e subindo, com uma onda em cada. |

### Eclipse

| Poder (PT / EN) | Custo | Resumo |
| --- | --- | --- |
| **Raio** / Lightning | 15 + 55/s | Segurado até 1 s: raios da mão até o alvo (480 u) que ferem e prendem a cada pulso. Na guarda, um quarto do dano passa. Feixes pelo tier: 1, 1 com ramo, 2, 3. |
| **Estrangular** / Choke | 45 + 10/s | Segurado até 1,8 s (240 u): ergue a vítima no ar, que não age e perde 3 de vida por segundo. Quem estrangula fica parado, sem atacar. Ao soltar, os dois voltam ao neutro **sem vantagem de punição**. +3 ou mais fura a guarda; −2 dura e drena metade; −3 falha. |
| **Congelar** / Freeze | 40 | Prende o alvo por 1,1 s sem dano (340 u); o primeiro golpe quebra o gelo. −1 dura 75%, −2 dura 40%, −3 falha; +3 fura a guarda. |
| **Tempestade** / Storm | 70 (Fluxo 6+) | Em fases: **Invocação** (~0,5 s, o braço sobe e um raio vai ao céu, a arena escurece; a **única janela de interrupção**); **escudo de raios** em volta de quem lança, que fica parado e imune a lâmina e poder; **tempestade** (~5 s) com ondas de 2, 3 ou 4 raios ao mesmo tempo pelo tier, dois sempre perto do oponente e os outros espalhados de forma determinística, cada um marcado no chão 0,5 s antes, 5 de dano e no máximo um acerto por onda; **encerramento** (~0,8 s), vulnerável. A guarda não bloqueia, a Absorção não absorve, a esquiva invulnerável passa, a Barreira segura pagando 30 de medidor por raio. No Ápice, cada raio abre fissuras para os dois lados (só pulando). Custo alto. |
| **Ira** / Wrath | 60 | Por 5 s × potência: dano causado × 1,2 e recebido × 0,85, em lâminas e poderes; dano periódico não muda. Cargas de armadura contra **2 golpes de lâmina** (quebra de guarda, empurrão, parry, poderes e projéteis continuam interrompendo). Reaplicar reinicia, sem empilhar. Custo alto. |
| **Dreno** / Drain | 15 | Segurado até 1,5 s (300 u): rouba medidor de Fluxo e um pouco de Vigor do alvo e devolve parte a quem drena. Não tira vida. O laço rompe se o alvo sair do alcance. |
| **Arsenal Telecinético** / Telekinetic Arsenal | 55 | Lâminas curtas de energia (2, 2, 3 ou 4 pelo tier) orbitam o corpo por 6 s. **Repetir o comando** lança uma no oponente; cada uma em órbita **segura sozinha um projétil** que chega. Escolha entre defesa e ataque. |

### Técnicas de lâmina (os dois caminhos)

Usam Habilidade com direção ou no ar, gastam **Vigor** (não Fluxo), escalam com a Lâmina e só existem com Poderes ligados. Respostas pensadas para cada uma.

| Técnica (PT / EN) | Resumo | Resposta |
| --- | --- | --- |
| **Giro** / Spin | A lâmina dá a volta no corpo e acerta dos dois lados; quem estava atrás não consegue bloquear. Um acerto só. | aparar de frente, punir a recovery |
| **Avanço com corte** / Dash slash | Avanço longo que termina num corte. No acerto, quem acertou fica livre primeiro, mas sem rápido garantido; defendido ou errado, é punível. | guarda ou parry, punir |
| **Arremesso da lâmina** / Blade throw | A lâmina sai girando até um alcance (480 u na Lâmina 4, ±20 u por ponto, entre 400 e 580) e volta. Acerta uma vez, na ida ou na volta. Enquanto não volta, o lutador não ataca nem defende com a lâmina. | guarda de frente, esquiva, atacar o lutador desarmado |
| **Estocada** / Thrust | Golpe reto e estreito no peito, o maior alcance de lâmina (55 u além do forte). Prep. 0,24 · ativo 0,1 · rec. 0,5 · dano 14 · Vigor 26. | pular por cima, esquivar |
| **Corte ascendente** / Rising cut | De baixo para cima até acima da cabeça. Contra alguém no ar, +30% de dano e lança para cima. Prep. 0,3 · ativo 0,14 · rec. 0,55 · dano 15 · Vigor 26. | ficar no chão e punir |
| **Rajada** / Flurry | Quatro estocadas curtas a cada 0,07 s, 4 de dano cada; cada uma na guarda gasta Vigor. Prep. 0,18 · rec. 0,42 · Vigor 30. | aparar qualquer estocada encerra a sequência |
| **Varredura** / Sweep | Corte rente ao chão que desequilibra por 0,55 s **mesmo quem bloqueia ou apara**. Prep. 0,42 · ativo 0,12 · rec. 0,5 · dano 9 · Vigor 26. | pular, esquivar, acertar na preparação longa |
| **Investida descendente** / Plunging strike | No ar: mergulho com a lâmina para baixo e para a frente, uma vez por pulo (conta como o golpe aéreo). Prep. 0,12 · ativo 0,36 · rec. 0,6 · dano 16 · Vigor 28. | sair do ponto de queda, punir a recovery |

**Choque entre técnicas**: quando as lâminas de duas técnicas corpo a corpo ativas se cruzam, as duas são interrompidas num choque grande (GAME_DESIGN, seção 7).

## 6. Conjuntos

O conjunto base de cada personagem está em [CHARACTERS.md](CHARACTERS.md). Personagens da Aurora escolhem do Fluxo comum e da Aurora; do Eclipse, do Fluxo comum e do Eclipse. Arcade, Sobrevivência, História e a IA usam o conjunto base. O protagonista da História equipa poderes aprendidos na campanha (ver [STORY.md](STORY.md)).

## 7. Ideias guardadas

Fora do plano atual, por repetirem outros poderes: Cataclismo e Redemoinho (repetem a chuva de impactos), Suspensão Suprema (repete o Congelar e levaria a combo garantido), Esmagamento (repete o Estrangular).
