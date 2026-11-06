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
| Corsária / Corsair | Eclipse | versátil, duas armas | 3 | 4 · 5 · 4 · 4 · 5 · 4 |
| Lince / Lynx | Aurora | versátil, surpresa | 3 | 4 · 4 · 6 · 4 · 5 · 4 |
| **Chefe** Sombra Desperta / Awakened Shadow | Eclipse | chefe | 3 | 7 · 6 · 6 · 5 · 4 · 7 |
| **Secreto** Soberano / Sovereign | Eclipse | senhor do Fluxo | 2 | 7 · 6 · 9 · 9 · 4 · 9 |
| **Secreto** Ancião / Elder | Aurora | mestre da Aurora | 3 | 6 · 6 · 8 · 8 · 8 · 8 |
| **Secreto** Predestinado / Foretold | Aurora ou Eclipse | Fluxo 10 | 2 | 8 · 10 · 10 · 7 · 9 · 10 |

## Conjuntos de poderes e técnicas (Base)

Direções relativas à frente do lutador. Técnicas usam Direção + Habilidade e, quando há, Habilidade no ar.

| Personagem | Poder | Frente + Poder | Trás + Poder | Quarto poder | Técnica frente | Técnica trás | No ar |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Guardião | Repulsão | Cura | Barreira | — | Avanço com corte | Arremesso da lâmina | — |
| Sombra | Raio | Puxão | Estrangular | — | Avanço com corte | Corte ascendente | Investida descendente |
| Bastião | Repulsão | Absorção | Barreira | — | Corte ascendente | Avanço com corte | — |
| Vespa | Repulsão | Arremesso | Barreira | — | Rajada | Arremesso da lâmina | — |
| Espelho | Repulsão | Arremesso | Barreira | — | Estocada | Corte ascendente | — |
| Haste | Raio | Puxão | Arremesso | — | Estocada | Corte ascendente | — |
| Brasa | Raio | Puxão | Congelar | — | Avanço com corte | Corte ascendente | — |
| Forja | Raio | Puxão | Arremesso | — | Arremesso da lâmina | Corte ascendente | — |
| Garça | Repulsão | Arremesso | Absorção | — | — | Avanço com corte | Investida descendente |
| Ceifador | Repulsão | Puxão | Ira | — | Avanço com corte | Arremesso da lâmina | Investida descendente |
| Eco | Raio | Puxão | Arremesso | — | Rajada | Avanço com corte | — |
| Corsária | Raio | Puxão | Arremesso | — | Rajada Desestabilizadora | Recuo com disparo | — |
| Lince | Repulsão | Arremesso | Barreira | — | Tiro de guarda | Corte ascendente | — |
| Sombra Desperta | Raio | Puxão | Estrangular | — | Avanço com corte | Corte ascendente | Investida descendente |
| Soberano | Raio | Tempestade | Estrangular | — | Corte ascendente | Estocada | — |
| Ancião | Repulsão | Cura | Barreira | — | Estocada | Corte ascendente | — |
| Predestinado (Aurora) | Repulsão | Arremesso | Barreira | Telecinese em Massa | Estocada | — | — |
| Predestinado (Eclipse) | Raio | Puxão | Estrangular | Arsenal Telecinético | Avanço com corte | — | — |

A técnica Giro foi removida na fase 8 (animação ruim, decisão do autor); os substitutos estão na tabela acima.

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
| Corsária | Cobalto `#3f6bff` | Turquesa `#3fe0e0` | Ouro-rosa `#ffb08a` | vencer acertando 12 disparos |
| Lince | Amarelo-lima `#e0ff3f` | Âmbar-claro `#ffe68a` | Azul-violeta `#8a7bff` | vencer acertando 4 disparos |
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

- **Introdução**: Ergue o cabo vertical diante do rosto, acende com calma e desce para a guarda compacta de duas mãos.

**O mestre dos fundamentos.** O personagem de entrada: tudo funciona como manda o livro, e é exatamente por isso que ele é perigoso nas mãos de quem domina o básico.

- **Traço**: bloquear custa 20% menos Vigor.
- **Habilidade — Contraguarda**: postura de resposta curta (0,35 s). No contato, a lâmina desvia o golpe para cima com faíscas e brilho, o corpo recua meio passo e responde com uma estocada curta (o contra-ataque).
- **Sequência**: 2 rápidos (de cima; reverso de baixo para cima).
- **IA**: equilibrada, paciente, apara fortes e pune com o contra-ataque.
- **Visual**: túnica até os joelhos em tom terroso (`#6b5a48`), corpo `#2e2925`; capuz abaixado; cabelo curto castanho; cinto largo de couro com fivela, braçadeiras de couro, botas escuras até a metade da canela. Postura ereta e controlada. Guarda alta: lâmina para cima e para a frente. Cabo com anel no emissor.
- **Família de movimento — Guardião**: econômico, preciso, guarda firme. Base baixa, guarda quase parada, preparação curta e corte direto, quase sem follow-through. Passos curtos, quadril firme, sem giro de lâmina. O empurrão solta a mão livre para a frente. O Avanço com corte desce de cima para baixo.

## Sombra / Shadow

- **Introdução**: Estuda o rival inclinada e de cabeça baixa, acende tarde junto ao quadril e abre a guarda baixa num arco curto.

**A predadora.** Pressão constante: cada acerto a alimenta, e o golpe com armadura atravessa quem tenta interromper.

- **Traço — Ímpeto**: cada golpe que acerta devolve 6 de Vigor.
- **Habilidade — Ímpeto**: avanço cortante com o corpo inteiro e armadura contra 1 golpe.
- **Sequência**: 3 rápidos (de cima largo; ascendente; estocada com passo).
- **IA**: agressiva, fica perto, usa mais fortes, defende pouco.
- **Visual**: capa longa até o chão, quase preta (`#1f2029`), corpo `#121319`; capuz levantado e pontudo; barra da capa rasgada em pontas desiguais; botas altas quase pretas. Postura inclinada para a frente, predatória. Guarda baixa: lâmina para baixo e para a frente. Cabo com pomo curvado. Olhos do Eclipse brilhando dentro do capuz.
- **Família — Agressor**: tronco à frente, preparação alta atrás da cabeça, arcos longos com passo grande e quadril, follow-through largo. Disputa inclinada e vitória larga.

## Bastião / Bastion

- **Introdução**: Ergue a arma com as duas mãos, acende num corte de teste pesado e a recolhe sobre o ombro, enraizando a base.

**A muralha.** Lento, enorme, inevitável. Anda em guarda e não recua.

- **Traço**: anda devagar enquanto bloqueia e não é empurrado no bloqueio.
- **Habilidade — Marreta**: golpe muito lento e pesado, com armadura contra 2 golpes (leva metade do dano).
- **Sequência**: 2 rápidos (curto de cima; ascendente pesado).
- **IA**: anda em guarda até o alcance e solta a Marreta quando o oponente insiste em atacar.
- **Visual**: túnica de armadura verde-oliva (`#3d4636`), corpo `#1f231c`, ombreiras grandes, ombros muito largos; cabeça raspada; duas placas no peito, caneleiras com joelheira, cinto escuro. Postura ereta. Lâmina mais grossa, alta sobre o ombro na guarda (família Colosso). Cabo com empunhadura escura.
- **Família — Colosso**: base larga e baixa, quase sem balanço, golpes curtos e secos no rápido, martelada sobre a cabeça no forte e na Marreta, agachando no impacto. Empurrão de ombro. Disputa enraizada, vitória curta.

## Vespa / Wasp

- **Introdução**: Abre as mãos, acende as lâminas em sequência e gira as duas em sentidos opostos antes de separar as guardas.

**O enxame.** Duas lâminas curtas, a sequência mais longa do jogo e um avanço que troca de lado.

- **Traço**: sequência de 5 rápidos; cada rápido bloqueado drena Vigor extra de quem defende. Pulo duplo mais forte (90%) e dash aéreo mais barato.
- **Habilidade — Zumbido**: avanço invulnerável que atravessa o oponente e troca de lado.
- **Sequência**: 5 rápidos (de cima com a lâmina da frente; reverso subindo com a de trás; estocada; horizontal com a de trás; o 5º fecha as duas em tesoura e empurra mais). **Forte em sequência**: o forte desce com as duas lâminas; forte de novo sobe com as duas, mais rápido e com menos dano.
- **IA**: pressiona com sequências e usa o Zumbido para atravessar fortes.
- **Visual**: túnica curta cor de areia (`#5c4a33`), corpo `#2a2219`; sem capuz; rabo de cavalo castanho-claro; faixas nos antebraços. Muito inclinada para a frente, baixa. **Duas lâminas curtas e finas**: uma à frente, outra invertida para trás. Cabos com empunhadura.
- **Família — Vespa**: base leve e inquieta, cortes que avançam o tronco, cada golpe com a sua lâmina, follow-through solto e giro curto depois do 5º rápido. Na guarda, a lâmina de trás para os golpes baixos, as lâminas se alternam nos rápidos seguidos e cruzam em X contra fortes. Passos longos. Disputa com tronco à frente e tremor maior; vitória larga com giro completo da lâmina.

## Espelho / Mirror

- **Introdução**: Ergue a lâmina vertical diante da máscara, acende, testa uma parada curta e retorna imóvel à vertical.

**O especialista em parry.** Imóvel, mascarado, devolve tudo o que recebe.

- **Traço**: janelas de parry maiores (perfeito 0,12 s, total 0,26 s).
- **Habilidade — Postura de Espera**: postura longa (0,7 s); o golpe que chegar é aparado com efeito de parry perfeito e respondido com o contra-ataque.
- **Sequência**: 2 rápidos (diagonal; ascendente).
- **IA**: prefere guardar a atacar e usa a postura contra qualquer golpe que vê chegando.
- **Visual**: manto longo cinza-claro (`#b9bcc7`) — o único personagem claro do elenco —, corpo `#3a3d47`; capuz levantado e máscara lisa com uma fenda; mangas largas e gola alta. Totalmente ereto, imóvel. Lâmina vertical à frente do rosto. Cabo liso.
- **Família — Esgrimista**: tronco reto, preparação contida, estocadas com o braço estendido, forte num corte diagonal limpo. Disputa firme, vitória curta e precisa.

## Haste / Lance

- **Introdução**: Ergue a haste com as duas mãos, acende a ponta, gira o eixo comprido e o baixa para a linha do rival.

**A distância.** Uma lâmina presa a uma haste longa como uma lança: perigosa na ponta, fraca colada.

- **Traço — Ponto doce**: acerto com a ponta (último terço do alcance) dá +50% de dano; de muito perto (primeiro quarto), 60%.
- **Habilidade — Investida da Haste**: lunge longo com a ponta (substitui a Varredura, removida do jogo).
- **Sequência**: 2 rápidos (estocada; ascendente). **Forte em sequência**: o forte desce a haste; forte de novo estoca reto, com passo longo, mais rápido e com menos dano.
- **IA**: mantém distância para acertar com a ponta.
- **Visual**: túnica cinza-violeta (`#3b3348`), corpo `#1c1924`; sem capuz; cabelo curto; cinto na cor do acabamento. Ereta, longe do oponente. **Cabo de mais de um metro**, como uma lança, com faixas escuras ao longo. Lâmina violeta.
- **Família — Esgrimista**: como o Espelho, com a estocada da Haste virando um lunge longo e a Investida da Haste longa e reta.

## Brasa / Ember

- **Introdução**: Já baixa e à espreita, acende a lâmina invertida junto ao quadril e a recolhe sem revelar intenção.

**A resposta.** Espera, lê e pune tudo com força.

- **Traço**: +20% de dano contra oponente em recovery, desequilibrado ou atordoado.
- **Habilidade — Brasa Viva**: postura de resposta (0,5 s); o golpe de resposta é um corte rápido e forte (startup 0,08 s), não o contra-ataque comum.
- **Sequência**: 3 rápidos (de baixo; de cima; estocada).
- **IA**: espera golpes para usar a postura e pune tudo.
- **Visual**: túnica curta vermelho-queimado (`#5a2c1e`), corpo `#24140f`; capuz levantado, sem capa; faixa na cintura com pontas, ataduras claras nos antebraços. Baixa, à espreita. **Empunhadura invertida**: lâmina longa para trás e para baixo. **Lâmina curta na outra mão**, alta, à frente do peito, nas mesmas cores. Cabos com empunhadura.
- **Família — Golpeador**: base baixa e contida a partir da guarda baixa; o rápido sobe de baixo até a linha do peito, o forte é um corte ascendente com o corpo subindo junto. Disputa baixa, vitória curta. **Na Brasa**, a lâmina curta é apresentação: só a longa acerta. Ela dá um segundo tempo curto depois do 1º rápido, acompanha a estocada, desce enquanto a longa sobe no forte, apara os rápidos e cruza com a longa contra fortes. Introduzida porque Brasa e Eco eram quase iguais de ver.

## Forja / Forge

- **Introdução**: Puxa a arma pesada para trás com as duas mãos, acende e sustenta o peso antes de apoiá-la na guarda alta.

**A carga.** Segura o golpe, a lâmina brilha cada vez mais, e o terceiro nível quebra qualquer guarda.

- **Traço**: knockback maior em tudo.
- **Habilidade — Forja**: apertar começa o golpe; **segurar** prende o golpe no fim da preparação e acumula carga (0,35 s por nível, até 3). Soltar libera. Nível 1 = dano normal; 2 = +35%; 3 = +70% e **quebra a guarda** de quem bloquear. No nível máximo o golpe sai sozinho. A lâmina brilha mais a cada nível: o oponente sempre vê a carga chegando e pode punir, esquivar ou empurrar.
- **Sequência**: 2 rápidos.
- **IA**: carrega o golpe quando o oponente está longe.
- **Visual**: túnica de couro (`#4a3a30`), corpo `#211a15`, ombros largos; sem capuz, cabeça grande, barba curta; avental de couro escuro, braçadeiras grossas, cinto com fivela. Firme, pesada. **Lâmina muito larga**, alta sobre o ombro na guarda. Cabo com guarda atravessada na base da lâmina.
- **Família — Colosso**: como o Bastião.

## Garça / Heron

- **Introdução**: Acende num arco ascendente, faz uma volta leve do corpo e ergue a lâmina atrás do ombro.

**O voo.** Acrobacia como arma: parede, ar e passagem por cima do oponente.

- **Traço**: pulo na parede; esquiva que atravessa o oponente; **dois aéreos** (rápido no ar é um corte, forte no ar é um mergulho).
- **Habilidade — Voo da Garça**: salto alto para a frente que passa por cima do oponente; dá para emendar um aéreo.
- **Sequência**: 3 rápidos (de cima; reverso cruzado; corte largo de trás do ombro com giro da lâmina).
- **IA**: muda de lado pelo ar e ataca de cima.
- **Visual**: túnica curta azul-acinzentada (`#2f4a52`), corpo `#16232a`; **cachecol longo** que voa atrás; sem capuz; cabelo preso em coque; botas altas. Leve, inclinada, sempre pronta para pular. Guarda com a mão à frente do peito e a lâmina apontando para trás na altura dos ombros (ajuste do autor: braço natural, rosto e cabelo livres; vale também para o estilo Voo da História). Cabo com anel.
- **Família — Dançarina**: base alta e solta, arcos largos com o corpo acompanhando, pirueta do corpo na recuperação do forte. Disputa leve, vitória com giro da lâmina.

## Ceifador / Reaper

- **Introdução**: Surge imóvel de capa e capuz, baixa o capuz devagar e encara o rival, solta a capa temporária, gira o cabo, acende as duas pontas em sequência e assenta numa guarda baixa e larga; peças do traje escolhido permanecem.

**A roda.** Lâmina dupla de cabo único, acrobata do Eclipse.

- **Traço**: o terceiro rápido da sequência empurra e atordoa mais.
- **Habilidade — Roda Dupla**: corpo firme e agachado enquanto o bastão gira duas voltas na frente do corpo; as duas pontas varrem à frente e atrás e acertam dos dois lados.
- **Sequência**: 3 rápidos (de cima; de baixo para cima com a outra ponta; estocada que fecha com meia volta da arma).
- **IA**: agressivo e móvel, usa a Roda Dupla quando o oponente tenta cercar.
- **Visual**: túnica curta escura (`#1c1517`), corpo `#0f0c0d`, acabamento carmesim (`#7a1f24`); sem capuz, cabeça à mostra com os olhos do Eclipse; faixa vermelha no pescoço; faixa carmesim com pontas e braçadeiras. Ombros estreitos, tronco à frente. **Bastão com uma lâmina em cada ponta**, lâminas mais curtas que as do elenco e cabo longo marcado no centro. Original: sem rosto, chifres, marcas ou traje copiados.
- **Família — Ceifador**: guarda com o bastão atravessado à frente, base um pouco baixa, balanço solto. O forte gira o bastão uma volta inteira na preparação antes de descer; o Avanço com corte gira o bastão durante a arrancada.
- **Trajes**: Viajante (capa `#3a3f47`, capuz); Sentinela (capa `#2e2422`, acabamento `#9a6b4a`, ombreiras).

## Eco / Echo

- **Introdução**: Insinua uma guarda alta apagada, acende durante um giro curto do punho e desvia para a guarda baixa.

**A trapaceira.** Nada do que ela começa é garantido.

- **Traço — Finta**: tocar a guarda durante a preparação do forte cancela o golpe (custa 12 de Vigor) e volta à guarda. Bom contra quem espera para aparar. Contra a finta: não apertar a guarda cedo demais, ou empurrar.
- **Habilidade — Passo-reflexo**: passo muito curto e invulnerável na direção apertada (para trás sem direção).
- **Sequência**: 2 rápidos.
- **IA**: finta fortes contra quem apara muito e usa o passo-reflexo para escapar de punições.
- **Visual**: túnica escura curta (`#23202b`), corpo `#121017`; capuz e máscara lisa; manga rasgada só no braço da frente; cinto escuro. Baixa e torta, imprevisível. Lâmina baixa à frente. Cabo com empunhadura.
- **Família — Golpeador**: como a Brasa, sem a lâmina curta.

---

## Família Versáteis / Versatile

Decisão do autor (tasks 07 e 08): lâmina numa mão e disparos de blaster. Mecânica da família: **Disparo Tático**, um disparo encaixado em certos recuos, reposicionamentos e passos da sequência (regras e números em GAME_DESIGN, "Disparo Tático"). Os disparos são projéteis que a guarda bloqueia e o parry devolve; **não interrompem golpe no ativo ou com armadura** (dão um tranco em quem está no startup desarmado, com imunidade curta; regra em GAME_DESIGN) (só dão um tranco em quem está parado, andando ou na recovery), para a família não ficar forte demais. A família não tem suprema própria (decisão do autor): as técnicas de disparo são técnicas de lâmina comuns que exigem blaster.

| | Corsária (Duelista Armado) | Lince (Atirador de Lâmina) |
| --- | --- | --- |
| Arma | lâmina numa mão, blaster separado na outra | uma lâmina com emissor de disparo no cabo |
| Disparos | frequentes: passo da sequência, técnica de frente e recuo | pontuais: só o tiro de guarda |
| Corpo a corpo | equilibrado | principal |
| Distância | forte | moderada |
| Identidade | alternância de armas, pressão | surpresa, interrupção, controle de distância |
| Técnica marcante | Rajada Desestabilizadora: cinco disparos e um avanço com corte | Tiro de guarda, que sai da guarda |

- **Família de movimento — Versáteis**: perfil de esgrimista, lâmina média à frente na altura do peito; a Corsária leva a mão do blaster baixa, à frente do quadril, apontando para o chão; o Lince, sem segunda arma, recolhe a mão livre atrás do corpo, escondida pela silhueta. Swing de uma mão, curto e de punho; o tiro estica o braço livre na altura do peito com um coice curto.
- Nomes, aparência, cores e falas são originais; nenhuma referência a personagens da franquia.
- **Liberação**: os dois já vêm liberados (como o elenco comum).
- **Equilíbrio** (matriz de 6 duelos por par no Difícil, 13 personagens): valores ao entrar, Corsária 55,6%, Lince 54,2%, dentro da meta de 40–60%; hoje Corsária 29,2% e Lince 81,9% (ver ROADMAP). Em 40 s de IA contra IA, a Corsária atira mais que o dobro do Lince (teste `test_blade_gunner_shoots_clearly_less_than_the_armed_duelist`).

## Corsária / Corsair

- **Introdução**: Ergue o blaster junto ao rosto, baixa-o ao quadril e só então acende a lâmina à frente.

**A pressão de duas armas.** Corta de perto, atira de longe e atira recuando: quem foge da sequência leva um disparo.

- **Atributos**: Vida 4 · Vigor 5 · Lâmina 5 · Defesa 5 · Agilidade 5 · Fluxo 4. Caminho Eclipse.
- **Ajuste a pedido do autor**: Lâmina e Defesa +1, rápidos +2 de dano e fortes +4. Na simulação, mudar só os disparos, a distância ou o uso de técnica quase não alterou o resultado, ou piorou: o que a derrubava era o corpo a corpo.
- **Traço — Saque rápido**: recupera 3 de Vigor a cada golpe de lâmina que acerta.
- **Habilidade — Recuo tático**: avanço para trás (200 u, invulnerável 0,18 s, 14 de Vigor); com direção para frente, avança.
- **Sequência**: 3 rápidos (ascendente; **corte com disparo**: o passo 2 corta e dispara no mesmo tick ativo; estocada).
- **Técnicas**: frente **Rajada Desestabilizadora** (técnica comum que exige blaster; ver content/POWERS.md); trás **Recuo com disparo** (salta 110 u para trás e dispara no início; prep. 0,1 · rec. 0,3 · Vigor 12).
- **Poderes**: Raio, Puxão, Arremesso. Na seleção, o editor também oferece o **Disparo duplo** (dois disparos com 0,12 s entre eles; prep. 0,16 · rec. 0,3 · Vigor 10).
- **IA**: mantém meia distância, atira em quem recua ou está em recovery, recua atirando quando o rival encosta; usa a técnica bem mais que a média.
- **Visual**: casaco curto de abas, colete justo e faixa cruzada no peito, cabelo preso; cinto com coldre. Corpo `#2c3440`, casaco `#6a4a2e` (couro), acabamento `#c9a46a`. **Blaster** compacto na mão livre, cano curto e grosso com aleta, desenhado pelo jogo na cor de metal do traje.
- **Lâmina**: Cobalto `#3f6bff` · Arcade Turquesa `#3fe0e0` · Desafio Ouro-rosa `#ffb08a` (vencer acertando 12 disparos).
- **Finalização do forte**: Execução Cruzada (GAME_DESIGN §10): dois cortes nos antebraços, recuo de alguns passos, disparo no peito da vítima ajoelhada, queda para trás e lâmina apagada.
- **Trajes**: Original; Viajante; Sentinela (regras do elenco comum).

## Lince / Lynx

- **Introdução**: Estende o cabo apagado à frente como quem mira, ergue-o e acende a lâmina para cima.

**A surpresa.** Luta de lâmina e guarda o tiro para cortar a aproximação no momento certo.

- **Atributos**: Vida 4 · Vigor 4 · Lâmina 6 · Defesa 4 · Agilidade 5 · Fluxo 4. Caminho Aurora.
- **Traço — Precisão**: +15% de dano contra quem está em recovery, desequilibrado ou atordoado.
- **Habilidade — Contragolpe**: postura de resposta (0,4 s); a resposta é um corte rápido.
- **Sequência**: 3 rápidos, todos de lâmina (horizontal; descendente; estocada).
- **Técnicas**: frente **Tiro de guarda** (prep. 0,05 · rec. 0,25 · Vigor 8; disparo mais rápido e mais fraco, 3 de dano; **pode sair da guarda**); trás **Corte ascendente**.
- **Poderes**: Repulsão, Arremesso, Barreira. A Sequência Corte e Disparo foi removida (decisão do autor).
- **IA**: luta de perto; usa o tiro de guarda contra quem avança ou dá um avanço com corte de longe.
- **Visual**: sobretudo longo e fechado até o pescoço, mangas justas, botas altas, cabelo curto raspado dos lados. Corpo `#1f2a2a`, sobretudo `#3e4f4a` (verde-ardósia), acabamento `#b7c4b0`. **Emissor no cabo**: um anel com lente na lateral do cabo, que acende na cor do disparo ao atirar.
- **Lâmina**: Amarelo-lima `#e0ff3f` · Arcade Âmbar-claro `#ffe68a` · Desafio Azul-violeta `#8a7bff` (vencer acertando 4 disparos).
- **Finalização do forte**: Sentença Precisa (GAME_DESIGN §10): corte diagonal, passagem para trás da vítima com corte lateral, disparo do cabo à queima-roupa, queda de joelhos e para a frente, lâmina apagada.
- **Trajes**: Original; Viajante; Sentinela.

## Chefe: Sombra Desperta / Awakened Shadow

- **Introdução**: Começa curvada e pesada, ergue lentamente a arma ao acender e a recolhe alta atrás da cabeça.

A Sombra depois de aceitar o Fluxo do Soberano. Mesma pessoa, mais perigosa.

- Mais vida (150), forte mais pesado, mesmos traço e habilidade da Sombra.
- No Arcade e na Sobrevivência, abaixo de metade da vida **desperta**: "A SOMBRA DESPERTA", letterbox pulsando, IA de chefe.
- **Visual**: silhueta da Sombra com ombreiras, ombros mais largos, capa ainda mais escura, barra rasgada, placas no peito e lâmina mais grossa. Guarda alta atrás da cabeça (a outra guarda do Agressor), para a silhueta se separar da Sombra. Continua magenta.
- Não aparece na seleção.

## Secretos

Os três têm **potencial**: o teto de todos os atributos sobe (+1, +2, +3), e a seleção mostra os segmentos extras em dourado. São os únicos acima do Fluxo 7: Ancião e Soberano no tier Profundo (roxo), o Predestinado sozinho no Ápice (vermelho).

### Soberano / Sovereign

- **Introdução**: Quase imóvel, adianta lentamente o punho e acende tarde com a ponta já dirigida ao adversário.

**O imperador sombrio.** Pressiona com Raio e Estrangular, cobre a aproximação com a Tempestade, mas o corpo é lento.

- Base de jogo da Haste: ponto doce e Investida da Haste; 2 rápidos.
- Potencial +2 (até 9).
- **Visual**: manto preto até o chão (`#211c27`, um tom acima do preto puro para a silhueta ler), corpo `#131016`; capuz fundo com o rosto na sombra, só os olhos do Eclipse visíveis; sem ombreiras; tronco curvado para a frente, ombros estreitos; gola alta e mangas largas. Lâmina carmesim apontada para o rival, braço adiantado com cotovelo flexível e mão livre recuada (família Esgrimista).
- **Trajes**: Original; **Legado** (final secreto): capa `#34394a`, capa longa e máscara.
- **Disputa pelo Fluxo**: na disputa de lâminas, segura a lâmina do rival no ar com a mão aberta em vez de cruzar a sua; no choque, empurra com a palma (só apresentação, ver design/VFX.md).
- Liberado ao vencê-lo na História ou ao concluir a campanha do Eclipse.

### Ancião / Elder

- **Introdução**: Reúne as mãos junto ao peito, acende a lâmina vertical com paciência e abre a guarda alta econômica.

**O mestre da Aurora.** Defesa e técnica acima de todos.

- Base de jogo da Garça: pulo na parede e mergulho aéreo. **Habilidade — Salto**: avança pelo ar e cai golpeando. 3 rápidos.
- Potencial +1 (até 8). Lâmina e Agilidade no teto.
- **Visual**: manto longo cor de pergaminho (`#8a7c5c`), corpo `#3c3a2c`, acabamento `#c9b98a`; sem capuz; barba longa branca; mangas largas; ombros estreitos, levemente curvado. Guarda alta. Lâmina verde-jade. Movimento da família Guardião.
- **Trajes**: Original; **Eremita** (final secreto): capa `#5c5a48`, capuz e capa longa.
- Liberado ao vencê-lo na História ou ao concluir a campanha da Aurora.

### Predestinado / Foretold

- **Introdução**: Ergue o cabo num giro contido, acende e firma a guarda compacta; Aurora e Eclipse assentam em suas próprias guardas.

**O ápice.** Nascido para equilibrar o Fluxo; o único com quatro poderes.

- Base de jogo do Eco: finta e Passo-reflexo. 2 rápidos (de cima; reverso de baixo para cima). Movimento da família Guardião.
- Potencial +3 (até 10). Lâmina e Vigor no teto.
- **Duas variantes**, escolhidas na seleção: **Aurora** (Repulsão, Arremesso, Barreira, quarto poder Telecinese em Massa; técnica Estocada) e **Eclipse** (Raio, Puxão, Estrangular, quarto poder Arsenal Telecinético; técnica Avanço com corte; cabo com pomo curvado e olhos do Eclipse). O **quarto poder** usa Poder + Habilidade juntos.
- **Visual base**: túnica clara cor de areia (`#c9c3b5`), corpo `#2a2f3a`, acabamento azul (`#6fb2ff`); sem capuz; cinto com fivela e botas escuras. Lâmina azul-aurora.
- **Trajes**:
  - **Ocaso** (final secreto): presença austera de quem já passou pelo fim; capuz levantado, manto longo, túnica em camadas, luvas de bronze escurecido. Manto `#1c1a20`, corpo `#26222b`, acabamento bronze fosco `#7a6650`.
  - **Caído** (concluir a História): cavaleiro de armadura negra com capa longa e capuz marrom-escuros, máscara cinza-aço, ombreiras, luvas pretas e o antebraço da lâmina protético (metal, `CostumeData.prosthetic_arm`). Manto `#33241a`, corpo `#24242b`, acabamento `#4a4e58`.
  - **Duelo** (vencer o Arcade com ele): túnica escura em camadas (gola alta), sem capa e sem capuz, cabelo castanho-escuro ondulado até o queixo e o antebraço da lâmina protético. Manto `#2b2119`, corpo `#120f0d`, acabamento `#4d3c2d`.
  - **Legado** (final secreto): capa `#34394a`, capa longa e máscara.
- Variantes liberadas ao vencê-las na História (o final secreto de cada rota enfrenta a variante oposta) ou pelo segredo do Equilíbrio.
- **Lâmina por variante**: a Aurora usa o azul-aurora (`#6fb2ff`); a Eclipse usa o **vermelho do Ápice** (`#ff2b45`), como cita a fala final da rota Aurora. A regra "lâminas sem moral" continua valendo: a cor marca a variante, não o caráter.

## Protagonista da História

**Coldre / Holster** (task 15): quarto estilo, Duelista de Coldre / Holster Duelist. Reutiliza arte corporal, introdução, guarda e sequência da família Guardião. Dano de todos os golpes de lâmina 10% menor nos mesmos atributos, sem herdar a redução de custo de guarda do Guardião. Pistola original visível no quadril; a mão auxiliar só a saca para Saque duplo (frente), Saque de recuo (trás) e Fogo de cobertura (habilidade). No ar usa Investida descendente. Variante de dados com rifle às costas, tiro de duas mãos e lâmina baixa. Sem entrada no elenco selecionável. IA defensiva de distância média: prefere 180 u, recua até 420 u, usa tiros por alcance e alterna guarda/parry com lâmina ao se aproximar. Números em GAME_DESIGN; carregamento em STORY.

- **Introdução**: Herda a entrada de Técnica (Guardião), Fúria (Sombra), Voo (Garça) ou Coldre (Guardião), preservando a aparência e a cor escolhidas.

Criado pelo jogador (ver [STORY.md](STORY.md)).

- **Nome**: da lista (Kael, Iria, Tarin, Vessa, Oren, Lyse) ou digitado, até 16 caracteres.
- **Caminho**: Aurora ou Eclipse (define os poderes e as falas).
- **Estilo de luta**: **Técnica** (golpes, habilidade e técnicas do Guardião), **Fúria** (da Sombra), **Voo** (da Garça) ou **Coldre** (Guardião com arma carregada).
- **Kit comprado na História**: só a técnica de frente vem na criação. Trás, Ar, habilidade do estilo e Corte Projetado são comprados na aba Lâmina, com os mesmos pontos de habilidade dos poderes. Para completar os espaços só do protagonista, Técnica usa Investida descendente no ar e Voo usa Estocada na frente; o elenco acima permanece igual. Detalhes e migração em STORY.md §4.
- **Visual**: **Errante** (capa longa azul-ardósia `#3e4a5e`, corpo `#1d222b`, acabamento `#7f90aa`, lenço, sem capuz nem máscara), **Vigia** (capa curta `#454d58`, capuz e máscara) ou **Peregrino** (capa longa terrosa `#51483c`, ombreiras, sem capuz ou máscara); mais Placas claras e Túnica em camadas; e, a pedido do autor, **Batedor** (túnica verde-oliva `#3c4630`, lenço, sem capa); **Nobre** (capa vinho `#4a1c24`, gola alta, acabamento dourado `#c8a45a`); **Cinzas** (capa cinza `#4a4a4e`, capuz sem máscara); **Duelista** (preto `#1c1a1e` com acabamento vermelho `#a83a3a`, gola e ombreiras, sem capa); **Andarilho do deserto** (areia `#8a7450`, capuz e lenço, sem capa); **Sentinela azul** (capa azul-aço `#2c3a52`, placas no peito).
- **Traje** (fase 8, além dos três acima): **Armadura de placas clara** (peitoral e ombreiras de placas claras sobre a túnica, sem capa) e **Túnica escura em camadas** (gola alta e capa). Trajes em `data/story/outfits/`.
- **Cabelo**: raspado, curto, médio ondulado, ondulado até o queixo, longo, rabo de cavalo, coque e, a pedido do autor, cortes femininos: chanel com franja, longo liso, trança, rabo de cavalo alto e franja lateral. **Barba**: nenhuma, curta, cheia aparada, longa ou bigode. **Cor do cabelo** (6) e **tom de pele** (5). Combinam livremente com os trajes; são arquétipos, nunca a réplica de um personagem existente. Editáveis depois pelo hub (Aparência).
- **Cor da lâmina**: Ciano-gelo, Verde-ácido, Amarelo-âmbar, Branco-prata, Violeta, Laranja-brasa, Verde-menta, Rosa-pálido, Magenta ou Vermelho-forja.
- **Olhos do Eclipse** se escolher o caminho do Eclipse (e só nesse caso, qualquer que seja o estilo).

## Olhos do Eclipse

Lutadores do Eclipse (inclusive a variante Eclipse do Predestinado e o protagonista do Eclipse) mostram olhos âmbar (`#ffb22e`) com centro vermelho (`#e2321e`) e um halo fraco. Leem melhor dentro da sombra do capuz. Com máscara, não aparecem. A Aurora e o Fluxo comum não mudam os olhos.
