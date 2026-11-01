# POWERS — O Fluxo e as técnicas de lâmina

Segue [GAME_DESIGN.md](../GAME_DESIGN.md). Efeitos visuais em [design/VFX.md](../design/VFX.md). Números são valores iniciais de calibração.

O **Fluxo** é a energia que atravessa as arenas e alguns duelistas. Dois caminhos o usam de formas opostas: a **Aurora** (proteção, cura, controle) e o **Eclipse** (dor, domínio, destruição). Parte dos poderes pertence aos dois, o **Fluxo comum**.

Os poderes são uma camada opcional do duelo (opção **Poderes**, ligada por padrão). Sem eles, o jogo é o duelo de lâmina puro.

## 1. Nível, tier e medidor

- **Nível do Fluxo**: o atributo Fluxo do lutador (1–7 no elenco; 8, 9 e 10 nos secretos). Define a potência, o ganho do medidor, a resistência aos poderes alheios e a cor da energia.
- **Tiers** (forma e cor da energia, nunca da lâmina):

| Tier (PT / EN) | Níveis | Cor | Quem |
| --- | --- | --- | --- |
| Tênue / Faint | 1–3 | azul-claro `#9cc4ff` | Bastião, Forja, Vespa |
| Firme / Steady | 4–6 | azul `#5d8dff` | o resto do elenco |
| Profundo / Deep | 7–9 | roxo `#b26bff` | Sombra Desperta, Ancião, Soberano |
| Ápice / Apex | 10 | vermelho `#ff2b45` | só o Predestinado |

  Pisos dos tiers revistos pelo autor: Tier II a partir do Fluxo 4, Tier III a partir do 7 (o protagonista da História chega a ele com o Fluxo no máximo) e Tier IV só no 10 (só o Predestinado). Simulação da matriz no Difícil antes e depois: totais de vitória dentro de ±2 pontos.

- **Supremas exigem tier** (decisão do autor). Nenhuma suprema existe no Tier I. O requisito é o nível de Fluxo do poder (`PowerData.min_level`), lido como tier por `PowerData.min_tier`; a simulação recusa o lançamento abaixo dele, a Galeria apaga os tiers bloqueados e avisa "Só a partir do Tier N", e a árvore da História mostra Fluxo e tier.

| Tier mínimo | Fluxo | Supremas |
| --- | --- | --- |
| II | 4+ | Repulsão Suprema, Santuário, Fratura, Ira, Arsenal Telecinético |
| III | 7+ | Telecinese em Massa, Tempestade, Instinto Superior, Singularidade Devastadora |

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
- Repulsão, Puxão e Raio não têm projétil: o efeito é decidido no instante ativo ou a cada pulso. Arremesso e objetos do Arsenal são projéteis.
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
| **Repulsão Suprema** / Supreme Push | 60 | Onda em volta do corpo todo (240 u). Pode ser lançada **enquanto o lutador apanha**: como fuga, 4 de dano; livre, como ataque, 14. Guarda e resultado pela tabela da Repulsão. Recarga própria de 6 s. Custo alto. Tier II. |
| **Fratura** / Fracture | 55 | Golpeia o chão: uma rachadura corre à frente até a parede, cada trecho fica rachado ~0,25 s e explode. Só acerta quem está no chão: **a única saída é pular**. Guarda, Absorção, Barreira e até a esquiva invulnerável não seguram. Custo alto. Tier II. |

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
| **Cura** / Heal | 40 | Lançamento curto (preparação 0,18 s, recuperação 0,2 s; antes 0,3 + 0,3). Devolve vida ao longo de 2 s, até 14 × potência e nunca mais que 35% da vida perdida. Fecha ferimentos se completar. Ser atingido interrompe. Pode ser lançada com vida cheia. |
| **Foco** / Focus | 35 | Por 4 s × potência, atacar, bloquear e esquivar custam metade do Vigor; habilita o Foco automático (GAME_DESIGN). |
| **Absorção** / Absorption | 10 + 20/s | Segurada até 1,5 s: absorve **qualquer poder** que chega, pulso a pulso no caso do Raio (como a troca de raios entre dois mestres), reduzindo ou anulando pela diferença de Fluxo e convertendo parte da energia em medidor. Não segura lâmina e não absorve a Tempestade. |
| **Santuário** / Sanctuary | 65 | Escudo colado ao corpo que absorve 20 × potência de dano enquanto o lutador age normalmente, por até 6 s. Racha conforme absorve e se quebra no limite. Custo alto. Tier II. |
| **Telecinese em Massa** / Mass Telekinesis | 75 (Tier III, Fluxo 7+) | Invocação de ~0,8 s, interrompível, só com a mão erguida. Quando o poder sai, o duelo congela por 1,05 s (determinístico, em dado) para a mini-cinemática de ~1,5 s: a câmera sobe ao céu, um meteoro é puxado e racha, e a câmera desce com os pedaços. Os pedaços caem sobre marcas no chão (5, 6 ou 7 impactos pelo tier, 7 de dano cada, com empurrão). Quem lança pode se mover, mas não atacar, durante a chuva. Sem céu à vista, fragmentos conjurados. Custo alto. |
| **Instinto Superior** / Higher Instinct | 70 (Tier III, Fluxo 7+) | Preparação calma de 0,2 s, recuperação de 0,2 s; dura 4 s × potência e tem recarga própria de 8 s. Esquiva automaticamente de lâminas corpo a corpo dirigidas ao corpo, sem Vigor nem custo por esquiva, consumindo o acerto e interrompendo a própria ação. Cada sucesso abre 0,35 s para usar o rápido como contra-ataque normal do personagem, sem bônus adicional de dano. Não evita empurrões, agarrões, poderes, projéteis ou golpes que atingem os dois lados. Dano efetivo de poder encerra o status e a janela; absorção total pelo Santuário não encerra. Choques e disputas continuam valendo, pois resolvem contato entre lâminas antes do acerto. Uma postura curta e pulso de letterbox anunciam a ativação; sem câmera lenta nova. |

### Eclipse

| Poder (PT / EN) | Custo | Resumo |
| --- | --- | --- |
| **Raio** / Lightning | 15 + 55/s | Segurado até 1 s: raios da mão até o alvo (480 u) que ferem e prendem a cada pulso. Na guarda, um quarto do dano passa. Feixes pelo tier: 1, 1 com ramo, 2, 3. |
| **Estrangular** / Choke | 45 + 10/s | Segurado até 1,8 s (240 u): ergue a vítima no ar, que não age e perde 3 de vida por segundo. Quem estrangula fica parado, sem atacar. Ao soltar, os dois voltam ao neutro **sem vantagem de punição**. +3 ou mais fura a guarda; −2 dura e drena metade; −3 falha. |
| **Congelar** / Freeze | 40 | Prende o alvo por 1,1 s sem dano (340 u); o primeiro golpe quebra o gelo. −1 dura 75%, −2 dura 40%, −3 falha; +3 fura a guarda. |
| **Tempestade** / Storm | 70 (Tier III, Fluxo 7+) | Em fases: **Invocação** (~0,5 s, o braço sobe e um raio vai ao céu, a arena escurece; a **única janela de interrupção**); **escudo de raios** em volta de quem lança, que fica parado e imune a lâmina e poder; **tempestade** (~5 s) com ondas de 2, 3 ou 4 raios ao mesmo tempo pelo tier, dois sempre perto do oponente e os outros espalhados de forma determinística, cada um marcado no chão 0,5 s antes, 5 de dano e no máximo um acerto por onda; **encerramento** (~0,8 s), vulnerável. A guarda não bloqueia, a Absorção não absorve, a esquiva invulnerável passa, a Barreira segura pagando 30 de medidor por raio. A partir do Tier III, cada raio abre fissuras para os dois lados (só pulando), com o dano do raio (decisão do autor: antes só no Ápice; o Tier III recebeu a ruptura como reforço). Custo alto. |
| **Ira** / Wrath | 60 | Por 5 s × potência: dano causado × 1,2 e recebido × 0,85, em lâminas e poderes; dano periódico não muda. Cargas de armadura contra **2 golpes de lâmina** (quebra de guarda, empurrão, parry, poderes e projéteis continuam interrompendo). Reaplicar reinicia, sem empilhar. Custo alto. Tier II. |
| **Dreno** / Drain | 15 | Segurado até 1,5 s (300 u): rouba medidor de Fluxo e um pouco de Vigor do alvo e devolve parte a quem drena. Não tira vida. O laço rompe se o alvo sair do alcance. |
| **Arsenal Telecinético** / Telekinetic Arsenal | 55 (Tier II) | Lâminas curtas de energia (2, 2, 3 ou 4 pelo tier) orbitam o corpo por 6 s. **Repetir o comando** lança uma no oponente; cada uma em órbita **segura sozinha um projétil** que chega. Escolha entre defesa e ataque. |

| **Singularidade Devastadora** / Devastating Singularity | 80 (Tier III, Fluxo 7+) | Criação interrompível de 0,6 s; campo de 3,7 s e recuperação de 0,2 s, recarga de 10 s. Esfera sobe por 0,4 s a 280 u sobre o ponto médio inicial. Ondas a cada 0,65 s: duas marcas de meia-largura 48 u (três no Tier IV), uma na posição atual do alvo e as outras sorteadas, sempre com faixa segura mínima de 80 u entre marcas; aviso de 0,65 s antes de arrancar. Extração só no chão: 3 × potência de dano, suspensão de 0,2 s e impulso vertical 480 u/s. Campo até 600 u: no chão soma 30 u/s para o centro, permitindo correr; no ar acelera 1.600 u/s² na horizontal e 3.300 u/s² na vertical, limitada a 360 u/s. Nos últimos 0,65 s fixa a mira na posição/altura do alvo e comprime a massa; arremessa a 900 u/s, raio 54 u e alcance 1.400 u, causando 38 × potência de dano, 0,6 s de desequilíbrio e empurrão 620 u/s. Trajetória reta, sem perseguição: sair do caminho ou usar esquiva invulnerável evita. Guarda, Barreira, Absorção e Arsenal não seguram a massa física; Santuário absorve dano normalmente e Instinto não evita. Durante o campo o lançador pode mover, saltar, defender e esquivar, mas não atacar nem lançar outros poderes; continua vulnerável e a morte cancela o campo e marcas pendentes. Não muda o conjunto base de nenhum personagem. |

### Técnicas de lâmina (os dois caminhos)

Usam Habilidade com direção ou no ar, gastam **Vigor** (não Fluxo), escalam com a Lâmina e só existem com Poderes ligados. Respostas pensadas para cada uma.

| Técnica (PT / EN) | Resumo | Resposta |
| --- | --- | --- |
| **Avanço com corte** / Dash slash | Avanço longo que termina num corte. No acerto, quem acertou fica livre primeiro, mas sem rápido garantido; defendido ou errado, é punível. | guarda ou parry, punir |
| **Arremesso da lâmina** / Blade throw | A lâmina sai girando até um alcance (480 u na Lâmina 4, ±20 u por ponto, entre 400 e 580) e volta. Acerta uma vez, na ida ou na volta. Enquanto não volta, o lutador não ataca nem defende com a lâmina. | guarda de frente, esquiva, atacar o lutador desarmado |
| **Estocada** / Thrust | Golpe reto e estreito no peito, o maior alcance de lâmina (55 u além do forte). Prep. 0,24 · ativo 0,1 · rec. 0,5 · dano 14 · Vigor 26. | pular por cima, esquivar |
| **Corte ascendente** / Rising cut | De baixo para cima até acima da cabeça. Contra alguém no ar, +30% de dano e lança para cima. Prep. 0,3 · ativo 0,14 · rec. 0,55 · dano 15 · Vigor 26. | ficar no chão e punir |
| **Rajada** / Flurry | Quatro estocadas curtas a cada 0,07 s, 4 de dano cada; cada uma na guarda gasta Vigor. Prep. 0,18 · rec. 0,42 · Vigor 30. | aparar qualquer estocada encerra a sequência |
| **Rajada Desestabilizadora** / Unsettling Barrage | Exige blaster (só a Corsária hoje). Cinco disparos a 0,08 s (3 de dano cada, 6 de Vigor na guarda, tranco comum: não interrompem ataques) e logo um avanço de 240 u com corte (16 de dano, conta como forte; finalização atravessando no K.O. decisivo). Prep. 0,12 · Vigor 30. Antes era suprema de Fluxo; o autor a tornou técnica de lâmina comum. | guarda segura a rajada; esquiva ou parry no avanço |
| **Disparo duplo** / Double Shot | Exige blaster. Dois disparos com 0,12 s entre eles. Prep. 0,16 · rec. 0,3 · Vigor 10. | guarda; parry devolve |
| **Recuo com disparo** / Retreating Shot | Exige blaster. Recua 110 u durante o ativo e dispara para a frente. Prep. 0,1 · rec. 0,3 · Vigor 12. | avançar com guarda |
| **Corte Projetado** / Projected Cut | Prep. 0,25 · ativo 0,1 · rec. 0,45 · dano 12 · Vigor 24. Técnica neutra: corte de cima para baixo que solta a onda em meia-lua (520 u). Bloqueável, esquivável e devolvida pelo parry perfeito. Apertar a técnica de novo durante o corte lança um **segundo corte** (prep. 0,3, mais 24 de Vigor) com a lâmina girando de volta ao alto; no máximo dois seguidos. A onda cresce com o tier de Fluxo de quem lança (0,8 / 1,0 / 1,2 / 1,4 do tamanho de referência, desenho e área de acerto). Gasta Vigor e escala com a Lâmina. Neutra. | guarda, parry perfeito para devolver |
| **Investida descendente** / Plunging strike | No ar: mergulho com a lâmina para baixo e para a frente, uma vez por pulo (conta como o golpe aéreo). Prep. 0,12 · ativo 0,36 · rec. 0,6 · dano 16 · Vigor 28. **No acerto, recuperação 0,27 s** (`recovery_on_hit`): quem acerta fica cerca de +4 quadros (antes ficava −15 e era punido mesmo acertando); na guarda continua −24. | sair do ponto de queda, punir a recovery |

**Choque entre técnicas**: quando as lâminas de duas técnicas corpo a corpo ativas se cruzam, as duas são interrompidas num choque grande (GAME_DESIGN, seção 7).

## 6. Conjuntos

O conjunto base de cada personagem está em [CHARACTERS.md](CHARACTERS.md). Personagens da Aurora escolhem do Fluxo comum e da Aurora; do Eclipse, do Fluxo comum e do Eclipse. Arcade, Sobrevivência e a IA usam o conjunto base. O protagonista da História compra e equipa poderes e o kit de lâmina nas duas árvores com pontos de habilidade (ver [STORY.md](STORY.md)).

## 7. Ideias guardadas

Fora do plano atual, por repetirem outros poderes: Cataclismo e Redemoinho (repetem a chuva de impactos), Suspensão Suprema (repete o Congelar e levaria a combo garantido), Esmagamento (repete o Estrangular).

O Corte Projetado tem alcance de 520 u e velocidade de 700 u/s. O custo de 24 de Vigor e a recuperação de 0,45 s compensam a segurança da distância, entre o Arremesso e a Estocada. Até duas ondas seguidas, cada uma pagando o próprio Vigor (decisão do autor: o corte duplo do antigo Ápice era o ponto alto da técnica e voltou como escolha do jogador); a lâmina permanece na mão. O tamanho por tier (0,8 / 1,0 / 1,2 / 1,4; o autor achou a primeira escala grande demais e cada tier passou ao tamanho do anterior) torna o tier visível sem mudar dano. A onda também é um projétil, interceptado pelo Arsenal.

O Instinto Superior escolhe a esquiva pelo corte: horizontal/arco → inclinar, ascendente → passo atrás, estocada → giro, descendente → deslize baixo. A esquiva cancela a ação atual, preserva posição física e altura, e não cria invulnerabilidade a poderes. O contra-ataque só é pedido no chão, pela mesma ação de rápido; a janela se consome ao iniciar o golpe e expira normalmente. Barreira, armadura e Santuário não são gastos por um golpe esquivado.

A Singularidade não prende indefinidamente: a breve suspensão da extração termina no ar, permitindo esquiva aérea. Só o oponente é afetado pelo campo. Os centros das marcas ficam imóveis depois do aviso e respeitam as bordas da arena; cada marca fica separada das outras por duas meias-larguras mais 80 u de passagem; no Tier IV a terceira marca ocupa a posição livre mais próxima do sorteio. Não há atração durante invulnerabilidade, disputa ou Estrangular. Extrações não executam finalizações; só o arremesso final usa BLAST no K.O. decisivo, sem mutilação. Depois de criada, a esfera persiste mesmo se o lançador sofrer acertos, como a chuva da Telecinese; a criação é sua janela de interrupção.
