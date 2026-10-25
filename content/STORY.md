# STORY — Mundo, campanha e diálogos

Segue [DESIGN.md](../DESIGN.md) e [GAME_DESIGN.md](../GAME_DESIGN.md). Personagens em [CHARACTERS.md](CHARACTERS.md); arenas em [ARENAS.md](ARENAS.md). Todas as falas são originais; nenhuma frase ou termo da franquia.

## 1. O mundo

- O **Fluxo** corre pelas arenas, mais forte em alguns lugares (a Plataforma de Refino) e silencioso em outros (a Floresta Lumínica). Duelistas sensíveis a ele podem usá-lo pelo caminho da **Aurora** ou do **Eclipse**.
- O **Soberano**, senhor do Eclipse, reúne duelistas no **Anel Orbital** e procura um novo aprendiz. Ele guarda um **herdeiro**.
- O **Ancião**, último grande mestre da Aurora, se esconde na Floresta Lumínica e protege alguém que escondeu dos dois lados.
- O **Predestinado** é esse alguém: dizem que nasceu para equilibrar o Fluxo. Cada mestre o moldou à sua maneira, e por isso ele existe em duas variantes, Aurora e Eclipse.
- O protagonista, aprendiz do **Guardião**, deixa a Plataforma para seguir o rastro do Soberano. O caminho que escolhe no Fluxo decide de que lado do conflito ele chega ao fim.

Tom: poucas palavras, frases curtas, nenhuma explicação a mais. O mundo se revela pelo que os duelistas dizem antes e depois de lutar.

## 2. Estrutura da campanha

```
                        COMUM
 O Teste (Guardião) → Ecos na Floresta (Eco) → A Vespa do Telhado (Vespa) → Brasa na Mina (Brasa)
                                                                                   │
                     ┌──────────── caminho da Aurora ────────────┐                 │
                     │                                           │◀────────────────┤
 O Muro do Santuário (Bastião) → Sombra (Sombra) → A Sombra Desperta → O Soberano  │
                                                                     │             │
                     vida > 75% ──▶ O Predestinado do Eclipse ──▶ Final secreto    │
                     senão ─────▶ Final normal "O Anel Silencia"                   │
                                                                                   │
                     ┌──────────── caminho do Eclipse ───────────┐                 │
                     │                                           │◀────────────────┘
 A Prova do Ceifador (Ceifador) → O Templo do Espelho (Espelho) → A Garça do Telhado (Garça) → O Ancião
                                                                     │
                     vida > 75% ──▶ O Predestinado da Aurora ──▶ Final secreto
                     senão ─────▶ Final normal "A Floresta Cede"
```

- A rota é decidida pelo **Caminho do Fluxo** escolhido na criação, sem escolha em diálogo.
- Cada encontro: adversário, arena, ajuste de dificuldade da IA, diálogo antes e depois, **um round**.
- Derrota: tentar de novo ou voltar à História, sem perder progresso.
- **Final secreto**: vencer o chefe com **mais de 75%** de vida (exatamente 75% não conta) leva ao Predestinado da variante oposta, sempre com IA de chefe.

| # | Encontro | Adversário | Arena | IA | Recompensa (Aurora / Eclipse) |
| --- | --- | --- | --- | --- | --- |
| 1 | O Teste | Guardião | Plataforma de Refino | −1 | pontos |
| 2 | Ecos na Floresta | Eco | Floresta Lumínica | −1 | pontos · Barreira / Puxão |
| 3 | A Vespa do Telhado | Vespa | Telhado Neon | 0 | marco · espaço Frente + Poder · Arremesso / Estrangular |
| 4 | Brasa na Mina | Brasa | Mina de Cristal | 0 | pontos · Cura / Congelar |
| 5A | O Muro do Santuário | Bastião | Santuário Alagado | 0 | pontos · Absorção |
| 6A | Sombra | Sombra | Plataforma de Refino | 0 | marco · espaço Trás + Poder · Foco |
| 7A | A Sombra Desperta | Sombra Desperta | Mina de Cristal | 0 | pontos · Puxão |
| 8A | O Soberano | Soberano | Anel Orbital | 0 | libera o Soberano |
| ★A | O Predestinado do Eclipse | Predestinado (Eclipse) | Santuário Alagado | chefe | libera a variante |
| 5E | A Prova do Ceifador | Ceifador | Anel Orbital | 0 | pontos · Ira |
| 6E | O Templo do Espelho | Espelho | Santuário Alagado | 0 | marco · espaço Trás + Poder · Dreno |
| 7E | A Garça do Telhado | Garça | Telhado Neon | 0 | pontos · Repulsão |
| 8E | O Ancião | Ancião | Floresta Lumínica | 0 | libera o Ancião |
| ★E | O Predestinado da Aurora | Predestinado (Aurora) | Santuário Alagado | chefe | libera a variante |

O "IA" é um ajuste sobre a dificuldade escolhida (−1 = um nível abaixo).

## 3. Criação do protagonista

Seis passos, com a prévia do personagem mudando junto com a opção destacada:

1. **Nome**: lista pronta (Kael, Iria, Tarin, Vessa, Oren, Lyse) ou digitado, até 16 caracteres.
2. **Caminho do Fluxo**: Caminho da Aurora ou Caminho do Eclipse. Define o poder inicial (Repulsão / Raio), os poderes aprendidos, a rota e as falas.
3. **Estilo de luta**: Técnica (base do Guardião), Fúria (base da Sombra), Voo (base da Garça).
4. **Visual**: Errante, Vigia ou Peregrino.
5. **Cor da lâmina**: dez cores do elenco.
6. **Dificuldade**: define o total de pontos de atributo da campanha.

Depois, o jogador distribui os pontos iniciais.

## 4. Progressão do protagonista

- Todos os atributos começam em 3 (total 18), com 3 pontos livres. Qualquer atributo vai até 7; a dificuldade limita só o total.
- Cada encontro vencido dá pontos uma única vez; os marcos (encontros 3 e 6) dão um pouco mais. O chefe e o secreto não dão pontos.

| Dificuldade | Por vitória | Marcos (3 e 6) | Total ao chegar ao chefe |
| --- | --- | --- | --- |
| Fácil | 3 | 3 e 3 | 42 (tudo em 7) |
| Normal | 2 | 3 e 2 | 36 |
| Difícil | 1 | 2 e 2 | 30 |

- Pontos investidos são definitivos. Normal e Difícil obrigam a escolher onde chegar a 7. Mesmo com Fluxo 7, o protagonista fica a −2 dos chefes de Fluxo 9: poderes pela metade contra eles. A lâmina tem de decidir.
- **Espaços de poder**: começa com um (Poder); abre Frente + Poder no 3º encontro e Trás + Poder no 6º.
- **Pontos de habilidade** (decisão do autor; substitui "um poder por encontro"): moeda própria, separada dos pontos de atributo. Cada duelo da História dá pontos, **vencido ou perdido**: vitória 3, derrota 1; os marcos (encontros 3 e 6) dão +1 e o secreto dá 3. Uma campanha sem derrotas soma 26 (29 com o secreto); as duas árvores juntas custam 36 na Aurora e 37 no Eclipse, então o jogador escolhe uma build. Números em `CampaignData` (`skill_points_win`, `skill_points_loss`, `skill_points_milestone`, `skill_points_secret`), nunca no código. Pontos gastos são definitivos.
- **Duas árvores** na mesma tela, com abas: **Poderes** e **Lâmina**. Cada nó custa pontos, exige o nó anterior do mesmo ramo e, nas supremas, o tier de Fluxo (POWERS.md: Tier II a partir do Fluxo 4, Tier III a partir do 7). Um nó desbloqueado e ainda sem requisito de tier aparece como "comprado, exige Fluxo N" e não pode ser equipado.
- **Árvore de Poderes**, do mais simples às supremas (o primeiro nó vem de graça na criação):

| # | Aurora | Custo | Eclipse | Custo |
| --- | --- | --- | --- | --- |
| 1 | Repulsão (inicial) | 0 | Puxão (inicial) | 0 |
| 2 | Puxão | 1 | Repulsão | 1 |
| 3 | Barreira | 1 | Dreno | 1 |
| 4 | Arremesso | 2 | Estrangular | 2 |
| 5 | Foco | 2 | Congelar | 2 |
| 6 | Cura | 2 | Raio | 2 |
| 7 | Absorção | 2 | Truque Mental | 2 |
| 8 | Truque Mental | 2 | Ira · Tier II | 3 |
| 9 | Repulsão Suprema · Tier II | 3 | Fratura · Tier II | 3 |
| 10 | Santuário · Tier II | 3 | Arsenal Telecinético · Tier II | 3 |
| 11 | Telecinese em Massa · Tier III | 4 | Tempestade · Tier III | 4 |
| 12 | Instinto Superior · Tier III | 4 | Singularidade Devastadora · Tier III | 4 |

  Os nós 1–8 formam um ramo em linha; as supremas formam um segundo ramo que abre depois do nó 6 (cada suprema exige a anterior do ramo e o tier). Total: Aurora 26, Eclipse 27.
- **Árvore de Lâmina** (igual nos dois caminhos; as técnicas novas entram no espaço escolhido em Frente, Trás ou Ar): Técnica de frente do estilo (inicial, 0) → Técnica de trás do estilo (2) → Técnica aérea do estilo (2) → Habilidade do estilo (3; antes vinha de graça) → **Corte Projetado** (3). Total 10.
- O conjunto é trocado na mesma tela, entre encontros. Nenhum espaço fica vazio nem repete. Saves antigos: os poderes já aprendidos contam como comprados, sem devolver pontos.
- Na História valem sempre Poderes, exaustão, ferimentos, Foco automático, disputa e finalizações.

## 5. Desbloqueios

- Vencer o Soberano libera o Soberano; vencer o Ancião libera o Ancião.
- Concluir a campanha da Aurora (qualquer final) libera também o Ancião; a do Eclipse, o Soberano.
- Vencer uma variante do Predestinado libera aquela variante.
- Concluir qualquer final libera os trajes Sentinela do elenco e o traje Caído do Predestinado; os finais secretos liberam os trajes Legado, Eremita e Ocaso.

## 6. Diálogos

`{name}` é o nome do protagonista. Narração não mostra nome de quem fala. Quando a fala do protagonista muda com o caminho, aparecem as duas versões.

Personagens que falam: Narrador, Guardião, Eco, Vespa, Brasa, Bastião, Sombra, Sombra Desperta, Soberano, Predestinado, Ceifador, Espelho, Garça, Ancião e o protagonista.

### Encontros comuns

#### 1. O Teste / The Trial

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | Na Plataforma de Refino, o Fluxo corre mais forte do que em qualquer outro lugar. | On the Refinery Platform, the Flow runs stronger than anywhere else. |
| Guardião | {name}. Antes de deixar a Plataforma, mostre o que aprendeu. | {name}. Before you leave the Platform, show me what you have learned. |
| Protagonista (Aurora) | Estou pronto para o teste, mestre. | I am ready for the trial, master. |
| Protagonista (Eclipse) | Chega de testes. Vou provar que já sou mais forte. | No more trials. I will prove I am already stronger. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Guardião | Boa lâmina. Mas o Fluxo não é só força: é escolha. | A good blade. But the Flow is not only strength: it is a choice. |
| Guardião | Dizem que o Soberano reúne duelistas no Anel Orbital. Siga o rastro dele. | They say the Sovereign gathers duelists on the Orbital Ring. Follow his trail. |

#### 2. Ecos na Floresta / Echoes in the Forest

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | A Floresta Lumínica devolve cada passo como um eco. | The Luminous Forest returns every step as an echo. |
| Eco | Procurando o Soberano? Primeiro tente me encontrar. | Looking for the Sovereign? First try to find me. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Eco | Você enxerga através das fintas. Ele vai gostar de você... ou temer. | You see through the feints. He will like you... or fear you. |
| Eco | Quem trabalha para ele espera no Telhado Neon. | Those who work for him wait on the Neon Rooftop. |

#### 3. A Vespa do Telhado / The Rooftop Wasp

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | No Telhado Neon, a chuva não para e ninguém fica parado. | On the Neon Rooftop, the rain never stops and nobody stands still. |
| Vespa | O Soberano paga bem por quem me vence. Pena que ninguém vence. | The Sovereign pays well for anyone who beats me. Too bad nobody does. |
| Protagonista (Aurora) | Não vim pelo pagamento. | I did not come for the money. |
| Protagonista (Eclipse) | Então eu fico com o pagamento. | Then I will take the money. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Vespa | Rápido demais até para mim... | Too fast even for me... |
| Narrador | Algo muda no Fluxo de {name}: agora cabe um segundo poder. | {name}'s Flow shifts: there is room for a second power now. |

#### 4. Brasa na Mina / Ember in the Mine

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | Os cristais da mina guardam a cor de cada lâmina que passa. | The crystals of the mine keep the color of every blade that passes. |
| Brasa | Eu leio cada golpe antes de ele nascer. Mostre o seu. | I read every strike before it is born. Show me yours. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Brasa | Você não tem um padrão. Isso me assusta. | You have no pattern. That scares me. |
| Brasa (Aurora) | O Bastião guarda o Santuário. Ele não deixa ninguém passar. | The Bastion guards the Sanctuary. He lets no one through. |
| Brasa (Eclipse) | O Soberano procura um novo aprendiz. Antes, vai mandar o Ceifador medir você no Anel. | The Sovereign is looking for a new apprentice. First, he will send the Reaper to test you on the Ring. |

### Caminho da Aurora

#### 5A. O Muro do Santuário / The Sanctuary Wall

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | No Santuário Alagado, a água repete o duelo de cabeça para baixo. | In the Flooded Sanctuary, the water repeats the duel upside down. |
| Bastião | Ninguém atravessa. Nem com o Fluxo. | No one gets through. Not even with the Flow. |
| Protagonista | Não quero derrubar você. Só preciso chegar ao Soberano. | I do not want to bring you down. I just need to reach the Sovereign. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Bastião | ...Atravessou. | ...You got through. |
| Bastião | Cuidado com a Sombra. Ela já serve ao Soberano. | Watch out for the Shadow. She already serves the Sovereign. |

#### 6A. Sombra / Shadow

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Sombra | O Soberano viu você chegando. Ele me mandou terminar o serviço. | The Sovereign saw you coming. He sent me to finish the job. |
| Protagonista | Ainda dá tempo de sair do lado dele. | There is still time to leave his side. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Sombra | Isso não acabou. O Fluxo dele me deu mais do que você imagina. | This is not over. His Flow gave me more than you think. |
| Narrador | O Fluxo de {name} se aprofunda: agora cabe um terceiro poder. | {name}'s Flow grows deeper: there is room for a third power now. |

#### 7A. A Sombra Desperta / The Shadow Awakens

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | Na Mina de Cristal, a Sombra volta, maior e mais escura. | In the Crystal Mine, the Shadow returns, bigger and darker. |
| Sombra Desperta | Agora eu entendo o que ele prometeu. | Now I understand what he promised. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Sombra Desperta | O Soberano... espera no Anel. | The Sovereign... waits on the Ring. |
| Narrador | O caminho para o Anel Orbital está aberto. | The way to the Orbital Ring is open. |

#### 8A. O Soberano / The Sovereign

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | No Anel Orbital, o Fluxo gira em volta de um único duelista. | On the Orbital Ring, the Flow revolves around a single duelist. |
| Soberano | Sete duelos. Você chegou mais longe do que todos. | Seven duels. You have come further than anyone. |
| Protagonista | Vim devolver o Fluxo a quem ele pertence. | I came to give the Flow back to those it belongs to. |
| Soberano | Então venha. Mostre que é digno do Anel. | Then come. Prove that you are worthy of the Ring. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Soberano | Impossível... ninguém me tocava assim há anos. | Impossible... no one has touched me like that in years. |

#### ★A. O Predestinado do Eclipse / The Eclipse Foretold

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Soberano | Você venceu quase sem sangrar. Então ainda resta o meu herdeiro. | You won almost unscathed. Then my heir remains. |
| Predestinado | Ele me criou para este duelo. Disse que a Aurora tinha me abandonado. | He made me for this duel. He said the Aurora had abandoned me. |
| Protagonista | A Aurora não abandona ninguém. Ainda dá tempo de escolher. | The Aurora abandons no one. There is still time to choose. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Predestinado | O Fluxo... está quieto. Pela primeira vez. | The Flow... is quiet. For the first time. |

### Caminho do Eclipse

#### 5E. A Prova do Ceifador / The Reaper's Test

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | No Anel Orbital, o Soberano observa de longe. | On the Orbital Ring, the Sovereign watches from afar. |
| Ceifador | Ele quer um novo aprendiz. Eu fui o último a pedir esse lugar. | He wants a new apprentice. I was the last one to ask for that place. |
| Protagonista | Então hoje o lugar muda de dono. | Then today the place changes hands. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Ceifador | Duas lâminas não bastaram... | Two blades were not enough... |
| Soberano | {name}. Um velho mestre da Aurora ainda se esconde. Traga-me o Ancião. | {name}. An old Aurora master is still hiding. Bring me the Elder. |

#### 6E. O Templo do Espelho / The Mirror Temple

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | No Santuário Alagado, cada golpe volta refletido. | In the Flooded Sanctuary, every strike comes back reflected. |
| Espelho | O Ancião não quer guerra. Volte enquanto pode. | The Elder does not want war. Turn back while you can. |
| Protagonista | Ele esconde alguma coisa. Vou descobrir o quê. | He is hiding something. I will find out what. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Espelho | Você não é o que o Soberano pensa. | You are not what the Sovereign thinks. |
| Narrador | O Fluxo de {name} se aprofunda: agora cabe um terceiro poder. | {name}'s Flow grows deeper: there is room for a third power now. |

#### 7E. A Garça do Telhado / The Rooftop Heron

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | No Telhado Neon, alguém salta entre as antenas. | On the Neon Rooftop, someone leaps between the antennas. |
| Garça | O Ancião me treinou. Ele me pediu para não lutar com você. | The Elder trained me. He asked me not to fight you. |
| Protagonista | Então ele devia ter vindo pessoalmente. | Then he should have come himself. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Garça | Ele espera na Floresta Lumínica. E não está sozinho. | He waits in the Luminous Forest. And he is not alone. |

#### 8E. O Ancião / The Elder

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Narrador | Na Floresta Lumínica, o Fluxo fica em silêncio. | In the Luminous Forest, the Flow goes silent. |
| Ancião | O Soberano manda aprendizes e chama isso de força. | The Sovereign sends apprentices and calls it strength. |
| Protagonista | Ninguém me mandou. Vim porque quis. | No one sent me. I came because I wanted to. |
| Ancião | Então mostre o que você quer de verdade. | Then show me what you really want. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Ancião | Forte... mais forte do que eu temia. | Strong... stronger than I feared. |

#### ★E. O Predestinado da Aurora / The Aurora Foretold

**Antes**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Ancião | Você venceu quase sem sangrar. Então está na hora de conhecer quem eu escondi. | You won almost unscathed. Then it is time to meet the one I hid. |
| Predestinado | O Ancião me escondeu dos dois lados. Dizem que eu nasci para equilibrar o Fluxo. | The Elder hid me from both sides. They say I was born to balance the Flow. |
| Protagonista | Então vamos ver para que lado ele pende. | Then let us see which way it leans. |

**Depois**

| Quem | PT-BR | EN |
| --- | --- | --- |
| Predestinado | Você luta pelo Eclipse... mas não como ele. | You fight for the Eclipse... but not like him. |

## 7. Finais

#### O Anel Silencia / The Ring Falls Silent (Aurora, normal)

| PT-BR | EN |
| --- | --- |
| O Soberano cai. O Fluxo volta a correr livre pelas arenas. | The Sovereign falls. The Flow runs free through the arenas again. |
| Dizem que ele guardava um herdeiro. Talvez um duelo mais limpo o tivesse revelado. | They say he kept an heir. Perhaps a cleaner duel would have revealed him. |

#### O Herdeiro Volta / The Heir Returns (Aurora, secreto)

| PT-BR | EN |
| --- | --- |
| O Predestinado baixa a lâmina vermelha. | The Foretold lowers the red blade. |
| Sem o herdeiro, o Anel perde o centro. Aurora e Eclipse voltam a se medir de igual para igual. | Without the heir, the Ring loses its center. Aurora and Eclipse face each other as equals again. |

#### A Floresta Cede / The Forest Yields (Eclipse, normal)

| PT-BR | EN |
| --- | --- |
| O Ancião cai. Nenhum mestre da Aurora resta para desafiar o Soberano. | The Elder falls. No Aurora master is left to challenge the Sovereign. |
| Mas {name} sente um Fluxo escondido em algum lugar. Talvez um duelo mais limpo o tivesse revelado. | But {name} feels a hidden Flow somewhere. Perhaps a cleaner duel would have revealed it. |

#### O Equilíbrio / Balance (Eclipse, secreto)

| PT-BR | EN |
| --- | --- |
| O Predestinado baixa a lâmina. | The Foretold lowers the blade. |
| {name} poderia entregar o Predestinado ao Soberano. Em vez disso, deixa o Fluxo em equilíbrio. | {name} could deliver the Foretold to the Sovereign. Instead, they leave the Flow in balance. |

Os finais normais deixam a pista para o final secreto ("um duelo mais limpo") sem dizer a regra.

## 8. Apresentação

- **Diálogo**: a arena do encontro ao fundo, escurecida, com os dois duelistas presentes em pose de espera; título do capítulo no alto; faixa escura embaixo com o nome de quem fala e a fala. Confirmar avança, voltar pula.
- **Final**: tela cinematográfica com o título do final e as falas do narrador.
- **Duelo**: faixa do topo com `CAPÍTULO N · TÍTULO`.
- **Hub**: Continuar, Evoluir atributos, Poderes, Nova/Recomeçar campanha; à direita, nome, caminho, estilo, poderes, atributos e o protagonista em guarda.
- **Galeria da História** (Extras): rever encontros e finais já vistos.
- Com a técnica visual nova, as cenas de diálogo podem ganhar retratos ou planos de câmera próprios, desde que mantenham o tom seco e cinematográfico. Voz gravada é uma possibilidade futura (ver [design/AUDIO.md](../design/AUDIO.md)).
