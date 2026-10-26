# ARENAS

Segue [DESIGN.md](../DESIGN.md) e [design/ART_DIRECTION.md](../design/ART_DIRECTION.md).

## Regras de todas as arenas

- **A lâmina é a principal fonte de luz.** O cenário é escuro e de saturação baixa; o contraste alto pertence aos lutadores e às lâminas. Luzes do cenário (lua, neon, sol, faróis) nunca competem com uma lâmina.
- **Cenário, não obstáculo**: a arena não muda a lógica dos lutadores e não mata ninguém. Chão plano, duas paredes laterais, largura útil de ~1200 u.
- **Profundidade**: três ou mais planos com parallax; pouco detalhe perto da área de luta, para as silhuetas lerem.
- **Ambiente vivo e discreto**: partículas lentas e pouco opacas atrás dos corpos (vapor, poeira, chuva, neve, esporos), que nunca encobrem os lutadores.
- **Reação a eventos**: a arena pode reagir aos eventos do combate (poeira no knockback, cristais que pegam a cor das lâminas), sempre como apresentação. Elementos interativos maiores (colunas que caem, cristais que estilhaçam) ficam para o futuro, pelo mesmo caminho.
- **Música e ambiência** próprias por arena (ver [design/AUDIO.md](../design/AUDIO.md)).
- Cada arena tem uma frase curta para a seleção e uma miniatura.

As cores entre parênteses são a paleta-base de referência; a arte final pode enriquecê-las mantendo o valor (claro/escuro) e a saturação.

---

## Plataforma de Refino / Refinery Platform

*"Plataforma industrial suspensa sobre o fosso."* A arena-símbolo do jogo e onde a História começa.

- **Fundo**: pilares industriais distantes, passarelas e feixes de luz verticais; fosso escuro sem fundo abaixo.
- **Chão**: plataforma metálica com segmentos e suportes, que **reflete as lâminas** como mancha de luz.
- **Ambiente**: vapor subindo devagar.
- **Clima**: escala enorme, metal frio, ecos.

## Santuário Alagado / Flooded Sanctuary

*"Templo em ruínas sob a lua, sobre a água."* A arena mais calma do jogo: silêncio e respeito.

- **Fundo**: lua grande e fria (`#9fb7d9`), colunas de pedra quebradas em alturas diferentes (`#1d2430`), um arco partido, escombros.
- **Chão**: lâmina d'água rasa e escura (`#0a1622`) com borda clara. **Os lutadores e as lâminas se refletem** na água, de cabeça para baixo e escurecidos.
- **Ambiente**: ondulações pequenas e lentas na água (também nos passos), poeira fina caindo na luz da lua.

## Mina de Cristal / Crystal Mine

*"Caverna onde os cristais pegam a cor das lâminas."*

- **Fundo**: rocha quase preta (`#110d16`) em camadas irregulares, estalactites; cristais angulosos (`#2a2140`, arestas `#4d3d70`) em dois planos.
- **Assinatura**: os cristais **acendem na cor da lâmina mais próxima**, com intensidade que cai com a distância. A caverna muda de cor conforme os lutadores se movem.
- **Ambiente**: brilhos minúsculos flutuando.

## Telhado Neon / Neon Rooftop

*"Topo de prédio na chuva, entre letreiros de glifos."*

- **Fundo**: cidade vertical em silhueta (`#0d111c`), janelas apagadas, **letreiros em glifos inventados** (traços geométricos, nenhuma letra real) em neon frio e fraco (`#5fd4e6`).
- **Chão**: laje molhada (`#10141f`) que reflete os lutadores, mais fraco que a água do Santuário.
- **Assinatura**: chuva inclinada, rápida e fina; a chuva vira vapor ao tocar as lâminas.

## Anel Orbital / Orbital Ring

*"Plataforma presa a um anel, acima de um planeta."* Onde o Soberano espera.

- **Fundo**: céu preto com estrelas, **planeta enorme** (`#16233a`) na parte de baixo do fundo, com a borda iluminada pela atmosfera (`#4f7fb8`), e a curva do anel cruzando o céu.
- **Iluminação**: sol forte e distante de um lado, luz dura lateral, terminador dia/noite no planeta.
- **Chão**: placa metálica com borda clara.
- **Ambiente**: poeira quase parada, como em gravidade baixa.

## Floresta Lumínica / Luminous Forest

*"Clareira onde os fungos acendem com as lâminas."* Onde o Ancião se esconde; o Fluxo fica em silêncio.

- **Fundo**: troncos e raízes em silhueta (`#0c1410`), copas fechando o céu, fungos nos troncos (`#1f3a30`).
- **Assinatura**: os **fungos acendem na cor da lâmina mais próxima**, como os cristais da Mina.
- **Chão**: musgo escuro (`#0f1a14`).
- **Ambiente**: esporos subindo devagar (`#6fe0b0`, opacidade baixa).

## Salinas de Vidro / Glass Salt Flats

*"Deserto de sal ao entardecer, entre miragens."* A arena mais quente, mas ainda escura: o sol já afundou.

- **Fundo**: céu em faixas horizontais avermelhadas (`#8a4a3c`), mais fortes perto do horizonte; sol grande e baixo, meio escondido (`#e89a5c`); mesas e rochas distantes em silhueta.
- **Chão**: crosta de sal (`#24212a`) com rachaduras em polígonos; reflexo fraco dos lutadores.
- **Assinatura**: **miragem de calor** (linhas curtas e trêmulas entre o horizonte e o chão) e **poeira de sal no knockback** (cada golpe que acerta alguém no chão levanta poeira nos pés, empurrada na direção do golpe).
- **Ambiente**: poeira fina levada pelo vento.

## Convés em Voo / Skyborne Deck

*"Convés de um cargueiro atravessando as nuvens."* A única arena com movimento constante.

- **Fundo**: céu noturno, mar de nuvens em dois planos, estruturas do cargueiro em silhueta (ponte de comando de um lado, mastro com antenas do outro, guarda-corpo baixo atrás do convés); duas luzes de navegação pequenas, nunca mais fortes que uma lâmina.
- **Chão**: convés metálico com juntas de placas.
- **Assinatura**: **parallax rápido**, nuvens e riscos de vento cruzando a tela; **vento nas capas**: capas, túnicas, capuzes, cabelos e cachecóis pendem e tremulam na direção do vento.

## Cume Nevado / Snowbound Peak

*"Mosteiro no alto da montanha, em plena nevasca."* Luz branca difusa, sem fonte definida.

- **Fundo**: picos em dois planos, o de trás mais claro pela névoa; mosteiro em terraços com telhados inclinados e uma torre nos dois lados, centro livre; luz atravessando a nevasca.
- **Chão**: neve compactada, escura o bastante para os pés lerem, montes baixos nas pontas.
- **Assinatura**: **neve de lado** em dois planos (muitos flocos pequenos e rápidos, poucos grandes e lentos); pegadas e neve levantada nos passos e esquivas.

## Cidadela do Eclipse / Eclipse Citadel

*"Salão de pedra onde o eclipse apaga tudo menos as lâminas."*

- **Fundo**: paredes de concreto brutalista em blocos e pilares grossos; janela enorme com caixilhos em grade; lá fora, o eclipse: disco preto com a coroa brilhando (`#f2dcae`) e um anel fino.
- **Chão**: pedra polida com juntas largas.
- **Assinatura**: **o eclipse escurece tudo menos as lâminas**: arena e corpos ficam numa sombra densa; as lâminas, a luz delas nos corpos e os efeitos vêm por cima com cor total. Os lutadores leem pela luz das próprias lâminas.
- **Ambiente**: pó lento na cor da coroa.

## Forja de Magma / Magma Forge

*"Uma forja cravada no vulcão, sobre um mar de lava."* Pedido do autor (um cenário com lava ao fundo); a arte é original, sem reproduzir planetas ou estruturas de filmes.

- **Fundo**: céu em faixas vermelho-escuras (`#0a0406` → `#3a1208`), cinza no ar; picos vulcânicos recortados com o topo em brasa; um **mar de lava** no horizonte, com correntes que deslizam devagar e quedas de lava escorrendo dos picos. A lava é laranja contido (`#7a2a0c`, correntes `#c8501a`, borda `#ffb060` fina): ilumina o horizonte, mas fica abaixo do brilho das lâminas.
- **Meio**: silhuetas de torres de forja com janelas acesas em laranja.
- **Chão**: basalto escuro em placas, com rachaduras finas em brasa.
- **Assinatura**: **brasas subindo** do chão e da lava, e **cinza caindo** devagar; a poeira do knockback sai como cinza.
- **Música e ambiência**: ambiência própria (borbulhar grave e estalos); música compartilhada até ganhar tema próprio.

## Plataforma de Treino / Training Platform

Arena neutra do Treino, do Tutorial, dos Treinos guiados e da Galeria de poderes: plataforma simples, fundo escuro sem distrações e marcações discretas de distância no chão (úteis para ler alcance).

---

## Implementação

As nove arenas novas são cenas montadas com `SceneryLayer` (`arenas/common/scenery_layer.gd`), um pintor de cenário em pixel art com tipos de camada (céu em faixas, lua, sol, planeta, eclipse, cordilheira, mar de lava, torres com letreiros de glifos, colunas, troncos com fungos, cristais, teto de caverna, nuvens que correm, navio, mosteiro, salão brutalista com janela, anel, chão por estilo) e partículas de clima (`CPUParticles2D`: chuva inclinada, neve em dois planos, esporos, poeira, brilhos, riscos de vento). As cenas e os `ArenaData` são gerados por `tools/art/make_arenas.py`; céu, discos, anel e nuvens ficam presos à tela na vertical, e o que fica no chão rola com ele. Cristais e fungos estão na máscara de luz das lâminas, então pegam a cor delas. O Convés tem `ArenaData.wind`, que empurra capas, túnicas, cachecóis e faixas. A Cidadela usa um ambiente bem escuro (as lâminas e efeitos ficam por cima com cor total).

Assinaturas de chão (flags do `ArenaData`): reflexo dos lutadores (`fighter_reflection`: Santuário 0,45, Telhado 0,25, Cidadela 0,2, Salinas 0,16), ondulações nos passos e aterrissagens (Santuário), vapor da chuva saindo das lâminas (Telhado), poeira de sal empurrada na direção do golpe (Salinas), pegadas e neve levantada nos passos, aterrissagens e esquivas (Cume). A miragem das Salinas é uma camada `MIRAGE` com linhas curtas que tremulam entre o horizonte e o chão. A seleção de arena mostra a miniatura da própria cena. Ainda faltam música e ambiência próprias (fase 8; até lá todas usam as da Plataforma de Refino).

## Rodízio

Duelar começa na Plataforma de Refino. Arcade e Sobrevivência fazem rodízio na ordem: Plataforma de Refino, Santuário Alagado, Mina de Cristal, Telhado Neon, Anel Orbital, Floresta Lumínica, Salinas de Vidro, Convés em Voo, Cume Nevado, Cidadela do Eclipse, Forja de Magma. A seleção de arena começa com **Aleatória**.
