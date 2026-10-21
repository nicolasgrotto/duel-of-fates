# CHARACTERS — Elenco

Segue [DESIGN.md](../DESIGN.md), [GAME_DESIGN.md](../GAME_DESIGN.md) e [design/ART_DIRECTION.md](../design/ART_DIRECTION.md). Poderes e técnicas citados estão em [POWERS.md](POWERS.md).

Todos os personagens são originais. A referência é sempre um **arquétipo** (o mestre técnico, o duelista sombrio, o imperador encapuzado), nunca um personagem da franquia: nada de rosto, nome, traje, marca ou silhueta copiados.

## Regras do elenco

- Cada personagem muda **a forma de jogar**: traço passivo, habilidade (`Habilidade` neutro), sequência de rápidos, técnicas, poderes e IA próprios.
- Todos usam os mesmos comandos (gramática em GAME_DESIGN). A variedade vem do conteúdo dos golpes.
- **Teste da silhueta**: pintado de preto, cada um continua reconhecível.
- **Lâminas sem moral**: uma cor única por personagem, espaçadas no círculo cromático para dois lutadores nunca se confundirem.
- Atributos de 1 a 7 (secretos até 8, 9 e 10). Ordem: Vida · Vigor · Lâmina · Defesa · Agilidade · Fluxo.
- **Família de movimento**: personagens com o mesmo jeito de lutar compartilham a base das animações (postura, arcos, defesa, disputa). A diferença vem da silhueta, da lâmina, dos golpes e da habilidade.

> Valores iniciais das habilidades e traços: [GAME_DESIGN.md](../GAME_DESIGN.md), seção 7 ("Habilidades e traços: valores iniciais"). Os dados ficam em `data/characters/<id>/<id>.tres`.

## Tipos de habilidade

- **Golpe**: ataque com propriedades extras (armadura, alcance enorme, carga).
- **Postura de resposta**: o lutador fica em guarda por um tempo curto; um golpe de frente nesse tempo é desviado (o atacante fica desequilibrado) e respondido na hora. Se nada vier, a postura termina com recovery punível. É **leitura antecipada**, diferente do parry, que é reação.
- **Avanço**: dash para a frente, invulnerável no começo, que pode atravessar o oponente.

## Resumo

| Personagem (PT / EN) | Caminho | Estilo | Rápidos | V · Vg · L · D · A · F |
| --- | --- | --- | --- | --- |
| Guardião / Guardian | Aurora | técnico, fundamentos | 2 | 5 · 4 · 4 · 6 · 4 · 5 |
| Sombra / Shadow | Eclipse | agressiva, pressão | 3 | 3 · 4 · 5 · 3 · 4 · 5 |
| Bastião / Bastion | Aurora | tanque, peso | 2 | 6 · 6 · 6 · 7 · 2 · 2 |
| Vespa / Wasp | Aurora | velocidade, duas lâminas | 5 | 3 · 6 · 3 · 3 · 7 · 3 |
| Espelho / Mirror | Aurora | defensivo, parry | 2 | 3 · 5 · 4 · 7 · 3 · 6 |
| Haste / Lance | Eclipse | alcance, lâmina em haste | 2 | 7 · 4 · 4 · 4 · 3 · 4 |
| Brasa / Ember | Eclipse | resposta, leitura | 3 | 3 · 5 · 5 · 4 · 4 · 5 |
| Forja / Forge | Eclipse | pesada, carga | 2 | 6 · 3 · 6 · 5 · 3 · 2 |
| Garça / Heron | Aurora | acrobática, mobilidade | 3 | 5 · 6 · 5 · 3 · 6 · 5 |
| Ceifador / Reaper | Eclipse | acrobata, lâmina dupla | 3 | 3 · 5 · 4 · 2 · 6 · 4 |
| Eco / Echo | Eclipse | trapaceira, fintas | 2 | 6 · 6 · 5 · 3 · 6 · 6 |
| **Chefe** Sombra Desperta / Awakened Shadow | Eclipse | chefe | 3 | 7 · 6 · 6 · 5 · 4 · 7 |
| **Secreto** Soberano / Sovereign | Eclipse | senhor do Fluxo | 2 | 7 · 6 · 9 · 9 · 4 · 9 |
| **Secreto** Ancião / Elder | Aurora | mestre da Aurora | 3 | 6 · 6 · 8 · 8 · 8 · 8 |
| **Secreto** Predestinado / Foretold | Aurora ou Eclipse | Fluxo 10 | 2 | 8 · 10 · 10 · 7 · 9 · 10 |

## Conjuntos de poderes e técnicas (Base)

Direções relativas à frente do lutador. Técnicas usam Direção + Habilidade e, quando há, Habilidade no ar.

| Personagem | Poder | Frente + Poder | Trás + Poder | Quarto poder | Técnica frente | Técnica trás | No ar |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Guardião | Repulsão | Cura | Barreira | — | Avanço com corte | Arremesso da lâmina | — |
| Sombra | Raio | Puxão | Estrangular | — | Avanço com corte | Giro | Investida descendente |
| Bastião | Repulsão | Absorção | Barreira | — | Corte ascendente | Giro | — |
| Vespa | Repulsão | Arremesso | Barreira | — | Rajada | Arremesso da lâmina | — |
| Espelho | Repulsão | Arremesso | Barreira | — | Estocada | Giro | — |
| Haste | Raio | Puxão | Arremesso | — | Estocada | Giro | — |
| Brasa | Raio | Puxão | Congelar | — | Avanço com corte | Varredura | — |
| Forja | Raio | Puxão | Arremesso | — | Arremesso da lâmina | Corte ascendente | — |
| Garça | Repulsão | Arremesso | Absorção | — | — | Giro | Investida descendente |
| Ceifador | Repulsão | Puxão | Ira | — | Avanço com corte | Arremesso da lâmina | Investida descendente |
| Eco | Raio | Puxão | Arremesso | — | Rajada | Varredura | — |
| Sombra Desperta | Raio | Puxão | Estrangular | — | Avanço com corte | Giro | Investida descendente |
| Soberano | Raio | Tempestade | Estrangular | — | Corte ascendente | Giro | — |
| Ancião | Repulsão | Cura | Barreira | — | Estocada | Giro | — |
| Predestinado (Aurora) | Repulsão | Arremesso | Barreira | Telecinese em Massa | Estocada | — | — |
| Predestinado (Eclipse) | Raio | Puxão | Estrangular | Arsenal Telecinético | Varredura | — | — |

Na seleção de Duelar, 2 Jogadores e Treino, o jogador pode trocar para um conjunto **Personalizado**: os mesmos espaços, preenchidos com poderes do Fluxo comum e do seu caminho, sem repetir e respeitando o nível mínimo de cada poder.

## Cores de lâmina e desafios

| Personagem | Padrão | Arcade | Desafio | Desafio para liberar |
| --- | --- | --- | --- | --- |
| Guardião | Ciano-gelo `#7fe4ff` | Azul-profundo `#5f8bff` | Verde-água `#3fffc8` | vencer com 3 parries perfeitos |
| Sombra | Magenta `#ff3f9e` | Violeta-escuro `#c23cff` | Rubi `#ff2a3a` | vencer causando 200 de dano |
| Bastião | Verde-ácido `#9dff3f` | Ouro-pálido `#ffe08a` | Azul-céu `#3fd0ff` | vencer com 12 defesas |
| Vespa | Amarelo-âmbar `#ffd23f` | Lima `#7cff6b` | Rosa `#ff6bd5` | vencer acertando a sequência completa de 5 |
| Espelho | Branco-prata `#e8eeff` | Prata-azulada `#9fd8ff` | Marfim `#ffe2b0` | vencer com 4 parries perfeitos |
| Haste | Violeta `#a46bff` | Anil `#6b7cff` | Fúcsia `#ff6bff` | vencer com 15 golpes acertados |
| Brasa | Laranja-brasa `#ff7a2a` | Ouro `#ffcf3f` | Carmim `#ff3f5a` | vencer com 3 golpes de resposta da postura |
| Forja | Vermelho-forja `#ff4038` | Laranja-forno `#ff9a3f` | Verde-escória `#b0ff3f` | vencer quebrando a guarda 2 vezes |
| Garça | Verde-menta `#5fffc0` | Azul-gelo `#a6e8ff` | Coral `#ff8a6b` | vencer acertando 4 ataques aéreos |
| Ceifador | Vermelho-sangue `#ff2a2a` | Laranja-brasa `#ff7a2e` | Violeta `#c43bff` | vencer com uma sequência de 5 acertos |
| Eco | Rosa-pálido `#ffa6e0` | Lilás `#c9a6ff` | Prata `#d6dbe6` | vencer fintando 5 vezes |
| Soberano | Carmesim `#ff3040` | Ouro-velho | — | — |
| Ancião | Verde-jade `#3fd07a` | — | — | — |
| Predestinado | Azul-aurora `#6fb2ff` (variante Eclipse: Vermelho-ápice `#ff2b45`) | — | — | — |

O desafio vale em qualquer duelo vencido contra a IA (Duelar ou Arcade, qualquer dificuldade), cumprido no duelo inteiro.

## Trajes

- **Elenco comum**: Original; **Viajante** (vencer o Arcade com o lutador): capa cinza-azulada `#454d58`, corpo `#222730`, acabamento `#83909e`, capuz abaixado e lenço; **Sentinela** (concluir qualquer final da História): capa terrosa `#51483c`, corpo `#28231e`, acabamento `#a0957e`, ombreiras.
- Trajes alternativos herdam as peças do traje base e mudam as cores; trocam peças só quando a peça não combina com eles.
- Trajes são cosméticos: não mudam atributos, golpes, lâmina ou hitbox.

---

## Guardião / Guardian

**O mestre dos fundamentos.** O personagem de entrada: tudo funciona como manda o livro, e é exatamente por isso que ele é perigoso nas mãos de quem domina o básico.

- **Traço**: bloquear custa 20% menos Vigor.
- **Habilidade — Contraguarda**: postura de resposta curta (0,35 s). No contato, a lâmina desvia o golpe para cima com faíscas e brilho, o corpo recua meio passo e responde com uma estocada curta (o contra-ataque).
- **Sequência**: 2 rápidos (de cima; reverso de baixo para cima).
- **IA**: equilibrada, paciente, apara fortes e pune com o contra-ataque.
- **Visual**: túnica até os joelhos em tom terroso (`#6b5a48`), corpo `#2e2925`; capuz abaixado; cabelo curto castanho; cinto largo de couro com fivela, braçadeiras de couro, botas escuras até a metade da canela. Postura ereta e controlada. Guarda alta: lâmina para cima e para a frente. Cabo com anel no emissor.
- **Família de movimento — Guardião**: econômico, preciso, guarda firme. Base baixa, guarda quase parada, preparação curta e corte direto, quase sem follow-through. Passos curtos, quadril firme, sem giro de lâmina. O empurrão solta a mão livre para a frente. O Avanço com corte desce de cima para baixo.

## Sombra / Shadow

**A predadora.** Pressão constante: cada acerto a alimenta, e o golpe com armadura atravessa quem tenta interromper.

- **Traço — Ímpeto**: cada golpe que acerta devolve 6 de Vigor.
- **Habilidade — Ímpeto**: avanço cortante com o corpo inteiro e armadura contra 1 golpe.
- **Sequência**: 3 rápidos (de cima largo; ascendente; estocada com passo).
- **IA**: agressiva, fica perto, usa mais fortes, defende pouco.
- **Visual**: capa longa até o chão, quase preta (`#1f2029`), corpo `#121319`; capuz levantado e pontudo; barra da capa rasgada em pontas desiguais; botas altas quase pretas. Postura inclinada para a frente, predatória. Guarda baixa: lâmina para baixo e para a frente. Cabo com pomo curvado. Olhos do Eclipse brilhando dentro do capuz.
- **Família — Agressor**: tronco à frente, preparação alta atrás da cabeça, arcos longos com passo grande e quadril, follow-through largo. Disputa inclinada e vitória larga.

## Bastião / Bastion

**A muralha.** Lento, enorme, inevitável. Anda em guarda e não recua.

- **Traço**: anda devagar enquanto bloqueia e não é empurrado no bloqueio.
- **Habilidade — Marreta**: golpe muito lento e pesado, com armadura contra 2 golpes (leva metade do dano).
- **Sequência**: 2 rápidos (curto de cima; ascendente pesado).
- **IA**: anda em guarda até o alcance e solta a Marreta quando o oponente insiste em atacar.
- **Visual**: túnica de armadura verde-oliva (`#3d4636`), corpo `#1f231c`, ombreiras grandes, ombros muito largos; cabeça raspada; duas placas no peito, caneleiras com joelheira, cinto escuro. Postura ereta. Lâmina mais grossa, quase horizontal na guarda. Cabo com empunhadura escura.
- **Família — Colosso**: base larga e baixa, quase sem balanço, golpes curtos e secos no rápido, martelada sobre a cabeça no forte e na Marreta, agachando no impacto. Empurrão de ombro. Disputa enraizada, vitória curta.

## Vespa / Wasp

**O enxame.** Duas lâminas curtas, a sequência mais longa do jogo e um avanço que troca de lado.

- **Traço**: sequência de 5 rápidos; cada rápido bloqueado drena Vigor extra de quem defende. Pulo duplo mais forte (90%) e dash aéreo mais barato.
- **Habilidade — Zumbido**: avanço invulnerável que atravessa o oponente e troca de lado.
- **Sequência**: 5 rápidos (de cima; reverso; estocada; reverso; o 5º fecha com giro da lâmina e empurra mais).
- **IA**: pressiona com sequências e usa o Zumbido para atravessar fortes.
- **Visual**: túnica curta cor de areia (`#5c4a33`), corpo `#2a2219`; sem capuz; rabo de cavalo castanho-claro; faixas nos antebraços. Muito inclinada para a frente, baixa. **Duas lâminas curtas e finas**: uma à frente, outra invertida para trás. Cabos com empunhadura.
- **Família — Vespa**: base leve e inquieta, cortes que avançam o tronco, arcos alternados entre as duas lâminas (a de trás conduz o corte reverso), follow-through solto e giro curto depois do 5º rápido e do forte. Passos longos. Disputa com tronco à frente e tremor maior; vitória larga com giro completo da lâmina.

## Espelho / Mirror

**O especialista em parry.** Imóvel, mascarado, devolve tudo o que recebe.

- **Traço**: janelas de parry maiores (perfeito 0,12 s, total 0,26 s).
- **Habilidade — Postura de Espera**: postura longa (0,7 s); o golpe que chegar é aparado com efeito de parry perfeito e respondido com o contra-ataque.
- **Sequência**: 2 rápidos (diagonal; ascendente).
- **IA**: prefere guardar a atacar e usa a postura contra qualquer golpe que vê chegando.
- **Visual**: manto longo cinza-claro (`#b9bcc7`) — o único personagem claro do elenco —, corpo `#3a3d47`; capuz levantado e máscara lisa com uma fenda; mangas largas e gola alta. Totalmente ereto, imóvel. Lâmina vertical à frente do rosto. Cabo liso.
- **Família — Esgrimista**: tronco reto, preparação contida, estocadas com o braço estendido, forte num corte diagonal limpo. Disputa firme, vitória curta e precisa.

## Haste / Lance

**A distância.** Uma lâmina presa a uma haste longa como uma lança: perigosa na ponta, fraca colada.

- **Traço — Ponto doce**: acerto com a ponta (último terço do alcance) dá +50% de dano; de muito perto (primeiro quarto), 60%.
- **Habilidade — Varredura**: golpe de alcance enorme e startup lento.
- **Sequência**: 2 rápidos (estocada; ascendente).
- **IA**: mantém distância para acertar com a ponta.
- **Visual**: túnica cinza-violeta (`#3b3348`), corpo `#1c1924`; sem capuz; cabelo curto; cinto na cor do acabamento. Ereta, longe do oponente. **Cabo de mais de um metro**, como uma lança, com faixas escuras ao longo. Lâmina violeta.
- **Família — Esgrimista**: como o Espelho, com a estocada da Haste virando um lunge longo e a Varredura baixa e longa.

## Brasa / Ember

**A resposta.** Espera, lê e pune tudo com força.

- **Traço**: +20% de dano contra oponente em recovery, desequilibrado ou atordoado.
- **Habilidade — Brasa Viva**: postura de resposta (0,5 s); o golpe de resposta é um corte rápido e forte (startup 0,08 s), não o contra-ataque comum.
- **Sequência**: 3 rápidos (de baixo; de cima; estocada).
- **IA**: espera golpes para usar a postura e pune tudo.
- **Visual**: túnica curta vermelho-queimado (`#5a2c1e`), corpo `#24140f`; capuz levantado, sem capa; faixa na cintura com pontas, ataduras claras nos antebraços. Baixa, à espreita. **Empunhadura invertida**: lâmina para trás e para baixo. Cabo com empunhadura.
- **Família — Golpeador**: base baixa e contida a partir da guarda baixa; o rápido sobe de baixo até a linha do peito, o forte é um corte ascendente com o corpo subindo junto. Disputa baixa, vitória curta.

## Forja / Forge

**A carga.** Segura o golpe, a lâmina brilha cada vez mais, e o terceiro nível quebra qualquer guarda.

- **Traço**: knockback maior em tudo.
- **Habilidade — Forja**: apertar começa o golpe; **segurar** prende o golpe no fim da preparação e acumula carga (0,35 s por nível, até 3). Soltar libera. Nível 1 = dano normal; 2 = +35%; 3 = +70% e **quebra a guarda** de quem bloquear. No nível máximo o golpe sai sozinho. A lâmina brilha mais a cada nível: o oponente sempre vê a carga chegando e pode punir, esquivar ou empurrar.
- **Sequência**: 2 rápidos.
- **IA**: carrega o golpe quando o oponente está longe.
- **Visual**: túnica de couro (`#4a3a30`), corpo `#211a15`, ombros largos; sem capuz, cabeça grande, barba curta; avental de couro escuro, braçadeiras grossas, cinto com fivela. Firme, pesada. **Lâmina muito larga** à frente. Cabo com guarda atravessada na base da lâmina.
- **Família — Colosso**: como o Bastião.

## Garça / Heron

**O voo.** Acrobacia como arma: parede, ar e passagem por cima do oponente.

- **Traço**: pulo na parede; esquiva que atravessa o oponente; **dois aéreos** (rápido no ar é um corte, forte no ar é um mergulho).
- **Habilidade — Voo da Garça**: salto alto para a frente que passa por cima do oponente; dá para emendar um aéreo.
- **Sequência**: 3 rápidos (de cima; reverso cruzado; corte largo de trás do ombro com giro da lâmina).
- **IA**: muda de lado pelo ar e ataca de cima.
- **Visual**: túnica curta azul-acinzentada (`#2f4a52`), corpo `#16232a`; **cachecol longo** que voa atrás; sem capuz; cabelo preso em coque; botas altas. Leve, inclinada, sempre pronta para pular. Lâmina alta, apontando para trás por cima do ombro. Cabo com anel.
- **Família — Dançarina**: base alta e solta, arcos largos com o corpo acompanhando, pirueta do corpo na recuperação do forte. Disputa leve, vitória com giro da lâmina.

## Ceifador / Reaper

**A roda.** Lâmina dupla de cabo único, acrobata do Eclipse.

- **Traço**: o terceiro rápido da sequência empurra e atordoa mais.
- **Habilidade — Roda Dupla**: corpo firme e agachado enquanto o bastão gira duas voltas na frente do corpo; as duas pontas varrem à frente e atrás e acertam dos dois lados.
- **Sequência**: 3 rápidos (de cima; de baixo para cima com a outra ponta; estocada que fecha com meia volta da arma).
- **IA**: agressivo e móvel, usa a Roda Dupla quando o oponente tenta cercar.
- **Visual**: túnica curta escura (`#1c1517`), corpo `#0f0c0d`, acabamento carmesim (`#7a1f24`); sem capuz, cabeça à mostra com os olhos do Eclipse; faixa vermelha no pescoço; faixa carmesim com pontas e braçadeiras. Ombros estreitos, tronco à frente. **Bastão com uma lâmina em cada ponta**, lâminas mais curtas que as do elenco e cabo longo marcado no centro. Original: sem rosto, chifres, marcas ou traje copiados.
- **Família — Ceifador**: guarda com o bastão atravessado à frente, base um pouco baixa, balanço solto. O forte gira o bastão uma volta inteira na preparação antes de descer; o Avanço com corte gira o bastão durante a arrancada.
- **Trajes**: Viajante (capa `#3a3f47`, capuz); Sentinela (capa `#2e2422`, acabamento `#9a6b4a`, ombreiras).

## Eco / Echo

**A trapaceira.** Nada do que ela começa é garantido.

- **Traço — Finta**: tocar a guarda durante a preparação do forte cancela o golpe (custa 12 de Vigor) e volta à guarda. Bom contra quem espera para aparar. Contra a finta: não apertar a guarda cedo demais, ou empurrar.
- **Habilidade — Passo-reflexo**: passo muito curto e invulnerável na direção apertada (para trás sem direção).
- **Sequência**: 2 rápidos.
- **IA**: finta fortes contra quem apara muito e usa o passo-reflexo para escapar de punições.
- **Visual**: túnica escura curta (`#23202b`), corpo `#121017`; capuz e máscara lisa; manga rasgada só no braço da frente; cinto escuro. Baixa e torta, imprevisível. Lâmina baixa à frente. Cabo com empunhadura.
- **Família — Golpeador**: como a Brasa.

---

## Chefe: Sombra Desperta / Awakened Shadow

A Sombra depois de aceitar o Fluxo do Soberano. Mesma pessoa, mais perigosa.

- Mais vida (150), forte mais pesado, mesmos traço e habilidade da Sombra.
- No Arcade e na Sobrevivência, abaixo de metade da vida **desperta**: "A SOMBRA DESPERTA", letterbox pulsando, IA de chefe.
- **Visual**: silhueta da Sombra com ombreiras, ombros mais largos, capa ainda mais escura, barra rasgada, placas no peito e lâmina mais grossa. Continua magenta.
- Não aparece na seleção.

## Secretos

Os três têm **potencial**: o teto de todos os atributos sobe (+1, +2, +3), e a seleção mostra os segmentos extras em dourado. São os únicos acima do Fluxo 7: Ancião e Soberano no tier Profundo (roxo), o Predestinado sozinho no Ápice (vermelho).

### Soberano / Sovereign

**O imperador sombrio.** Pressiona com Raio e Estrangular, cobre a aproximação com a Tempestade, mas o corpo é lento.

- Base de jogo da Haste: ponto doce e Varredura; 2 rápidos.
- Potencial +2 (até 9).
- **Visual**: manto preto até o chão (`#211c27`, um tom acima do preto puro para a silhueta ler), corpo `#131016`; capuz fundo com o rosto na sombra, só os olhos do Eclipse visíveis; sem ombreiras; tronco curvado para a frente, ombros estreitos; gola alta e mangas largas. Lâmina carmesim.
- **Trajes**: Original; **Legado** (final secreto): capa `#34394a`, capa longa e máscara.
- Liberado ao vencê-lo na História ou ao concluir a campanha do Eclipse.

### Ancião / Elder

**O mestre da Aurora.** Defesa e técnica acima de todos.

- Base de jogo da Garça: pulo na parede e mergulho aéreo. **Habilidade — Salto**: avança pelo ar e cai golpeando. 3 rápidos.
- Potencial +1 (até 8). Lâmina e Agilidade no teto.
- **Visual**: manto longo cor de pergaminho (`#8a7c5c`), corpo `#3c3a2c`, acabamento `#c9b98a`; sem capuz; barba longa branca; mangas largas; ombros estreitos, levemente curvado. Guarda alta. Lâmina verde-jade. Movimento da família Guardião.
- **Trajes**: Original; **Eremita** (final secreto): capa `#5c5a48`, capuz e capa longa.
- Liberado ao vencê-lo na História ou ao concluir a campanha da Aurora.

### Predestinado / Foretold

**O ápice.** Nascido para equilibrar o Fluxo; o único com quatro poderes.

- Base de jogo do Eco: finta e Passo-reflexo. 2 rápidos (de cima; reverso de baixo para cima). Movimento da família Guardião.
- Potencial +3 (até 10). Lâmina e Vigor no teto.
- **Duas variantes**, escolhidas na seleção: **Aurora** (Repulsão, Arremesso, Barreira, quarto poder Telecinese em Massa; técnica Estocada) e **Eclipse** (Raio, Puxão, Estrangular, quarto poder Arsenal Telecinético; técnica Varredura; cabo com pomo curvado e olhos do Eclipse). O **quarto poder** usa Poder + Habilidade juntos.
- **Visual base**: túnica clara cor de areia (`#c9c3b5`), corpo `#2a2f3a`, acabamento azul (`#6fb2ff`); sem capuz; cinto com fivela e botas escuras. Lâmina azul-aurora.
- **Trajes**:
  - **Ocaso** (final secreto): presença austera de quem já passou pelo fim; capuz levantado, manto longo, túnica em camadas, luvas de bronze escurecido. Manto `#1c1a20`, corpo `#26222b`, acabamento bronze fosco `#7a6650`.
  - **Caído** (concluir a História): cavaleiro de armadura negra com capa longa e capuz marrom-escuros, máscara cinza-aço, ombreiras e luvas pretas. Manto `#33241a`, corpo `#24242b`, acabamento `#4a4e58`.
  - **Duelo** (vencer o Arcade com ele): túnica escura em camadas, sem capa e sem capuz, luvas pretas e cabelo castanho-escuro ondulado até o queixo. Manto `#2b2119`, corpo `#120f0d`, acabamento `#4d3c2d`.
  - **Legado** (final secreto): capa `#34394a`, capa longa e máscara.
- Variantes liberadas ao vencê-las na História (o final secreto de cada rota enfrenta a variante oposta) ou pelo segredo do Equilíbrio.
- **Lâmina por variante**: a Aurora usa o azul-aurora (`#6fb2ff`); a Eclipse usa o **vermelho do Ápice** (`#ff2b45`), como cita a fala final da rota Aurora. A regra "lâminas sem moral" continua valendo: a cor marca a variante, não o caráter.

## Protagonista da História

Criado pelo jogador (ver [STORY.md](STORY.md)).

- **Nome**: da lista (Kael, Iria, Tarin, Vessa, Oren, Lyse) ou digitado, até 16 caracteres.
- **Caminho**: Aurora ou Eclipse (define os poderes e as falas).
- **Estilo de luta**: **Técnica** (golpes, habilidade e técnicas do Guardião), **Fúria** (da Sombra) ou **Voo** (da Garça).
- **Visual**: **Errante** (capa longa azul-ardósia `#3e4a5e`, corpo `#1d222b`, acabamento `#7f90aa`, lenço, sem capuz nem máscara), **Vigia** (capa curta `#454d58`, capuz e máscara) ou **Peregrino** (capa longa terrosa `#51483c`, ombreiras, sem capuz ou máscara).
- **Cor da lâmina**: Ciano-gelo, Verde-ácido, Amarelo-âmbar, Branco-prata, Violeta, Laranja-brasa, Verde-menta, Rosa-pálido, Magenta ou Vermelho-forja.
- **Olhos do Eclipse** se escolher o caminho do Eclipse.

## Olhos do Eclipse

Lutadores do Eclipse (inclusive a variante Eclipse do Predestinado e o protagonista do Eclipse) mostram olhos âmbar (`#ffb22e`) com centro vermelho (`#e2321e`) e um halo fraco. Leem melhor dentro da sombra do capuz. Com máscara, não aparecem. A Aurora e o Fluxo comum não mudam os olhos.
