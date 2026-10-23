# ART DIRECTION

Identidade visual do jogo. Segue [DESIGN.md](../DESIGN.md). Efeitos em [VFX.md](VFX.md); interface em [UI_UX.md](UI_UX.md).

## Identidade

O jogo deve transmitir: duelo cinematográfico, velocidade elegante, peso nos golpes, tensão, atmosfera sci-fi, contraste forte e combate de alto nível. A cena é escura; a luz e a cor saturada pertencem às lâminas.

Referências de **sensação** (nunca de assets): os duelos de sabre da trilogia prequel (coreografia veloz, acrobacia, cenários industriais e templos enormes, a lâmina iluminando rostos), duelos de samurai do cinema (tensão antes do golpe), Sekiro e For Honor (defesa no tempo certo), Nidhogg e Limbo (silhuetas fortes em cenários escuros), concept art sci-fi industrial e fotografia com neon em ambiente escuro.

## Técnica de apresentação

- O **combate acontece num plano 2D lateral**. A câmera é lateral; profundidade é cenário.
- **Técnica decidida: pixel art sci-fi com esqueleto** (decisão da migração para pixel art; a versão em alta definição está na tag `phase-5-hd`). O mundo inteiro (arena, lutadores, lâminas, poderes e efeitos) é desenhado **nativamente numa grade de pixels baixa** e ampliado sem suavização. Não é um filtro sobre a arte em alta definição: cada peça é pintada direto na grade, com tons e contornos definidos.
- **Grade**: 1 pixel do mundo = **2 u** (0,5 px/u). Um lutador tem ~75 px de altura; no enquadramento neutro a grade tem ~480×270 e cada pixel ocupa ~4 px de uma tela 1080p. O zoom da câmera muda o tamanho de **todos** os pixels por igual (entre ~2,5 e ~4,5 px de tela), nunca reamostra uma peça isolada. A câmera anda em pixels inteiros da grade; o deslize suave vem do deslocamento da imagem final.
- **Peças**: o mesmo esqueleto (`Skeleton2D`, IK, tecidos com física, pose calculada da simulação por família de movimento). As peças são pintadas na grade sem antialias: borda dura, **4 tons por cor** (sombra, base, luz, brilho), **contorno seletivo** de 1 px (escuro no lado da sombra; no lado da luz, que vem da frente e de cima, a borda sobe um tom), para membros finos de 4–5 px não virarem só contorno, **luz de forma** pintada em cada peça (frente clara, costas escuras) e detalhe interno só onde ele lê em 1–2 px (olho, sobrancelha, nariz, brilho do cabelo, dobras de cotovelo e joelho, punho, biqueira e sola da bota, lapela da túnica, bolsa no cinto). A cabeça tem ~11 px de altura (proporção heroica, ~1/7 do corpo) e pescoço curto, para o rosto ler na grade. As peças de trás (perna, braço, capa) ficam acima do cenário na ordem de desenho, sempre visíveis. Os trajes trocam a paleta (8 slots), como num jogo de pixel art clássico. O mapa de normal é pintado na mesma grade: a luz das lâminas ilumina o corpo em degraus de pixel.
- **Rotação**: peças giram com o osso e são rasterizadas na grade (sem subpixel); por isso as peças são pequenas e com formas simples, que continuam limpas em qualquer ângulo.
- **Interface**: continua em alta resolução, com a Oxanium; só o mundo é pixel art.
- Descartados: filtro de pixelização sobre a arte em alta definição (proibido), sprites quadro a quadro (volume de arte enorme com 15 lutadores, 4 armas e variantes, e perderia a sincronia automática com a simulação) e 2.5D com modelos 3D.
- O pipeline anterior (alta definição, 4 px/u, fase 3) fica registrado em ARCHITECTURE.md; o formato das peças (mapa de material + mapa de normal) é o mesmo.

## Escala e enquadramento

- Em enquadramento neutro, um lutador ocupa cerca de 25–30% da altura da tela; a arena é grande diante deles.
- A câmera acompanha o ponto médio dos lutadores, com zoom suave conforme a distância e margem para as lâminas. O chão é a âncora vertical.
- Punch-in curto no impacto forte, no parry perfeito e no K.O. (ver VFX).

## Silhuetas

- **Teste da silhueta**: pintado de preto, cada personagem continua reconhecível. Resolvem isso: capuz (levantado, pontudo, fundo, ausente), comprimento da roupa (capa até o chão, túnica curta), largura dos ombros, ombreiras, cachecol, postura e, principalmente, a **forma de segurar a lâmina** (guarda alta, baixa, invertida, haste longa, duas lâminas, bastão duplo).
- O detalhe interno nunca compete com a silhueta: costuras, fivelas e faixas ficam discretas; o que muda a silhueta tem prioridade.
- Descrição de cada personagem em [content/CHARACTERS.md](../content/CHARACTERS.md).

## Paleta

### Ambiente

Preto profundo, azul escuro, cinza, metais frios. Saturação baixa. Cada arena tem sua paleta-base (ver [content/ARENAS.md](../content/ARENAS.md)).

Na grade de pixels, céus e fossos são **faixas** de cor (sem degradê contínuo), feixes de luz são fatias com opacidade em degraus, detalhes (costuras, rebites, janelas, parafusos, luzes de aviso âmbar) têm 1–4 px e todo desenho de cenário usa medidas múltiplas de 2 u.

### Personagens

Roupas em tons dessaturados (terrosos, cinzas, oliva, vinho, ardósia) para a lâmina manter o contraste. Só o Espelho é claro. Cores por personagem em CHARACTERS.

### Lâminas

Uma cor por personagem, espaçada no círculo cromático. **Sem moral**: nenhuma cor significa herói ou vilão.

### Energia do Fluxo

A cor vem do tier de quem lança: Tênue `#9cc4ff`, Firme `#5d8dff`, Profundo `#b26bff`, Ápice `#ff2b45`. Nunca da lâmina. O lado de um poder (na interface) usa Aurora `#5aa2ff` e Eclipse `#ff4458`.

### Interface

Fundo `#05070d`, texto `#e8ecf5`, texto secundário `#8a94ab`, destaque `#9fb4d9`, perigo `#e5484d`. Cor saturada só para informação crítica.

## A lâmina

A lâmina é a protagonista visual e a principal fonte de luz.

- **Camadas**: núcleo branco fino, glow interno forte na cor da lâmina, glow externo largo e suave, bloom. Na grade: núcleo de 1 px, glow interno de 2–3 px e externo de 5–6 px, sem antialias.
- **Rastro** (trail) durante o active dos golpes, na cor da lâmina, curto (~0,12 s), que mostra o arco exato do corte. Na grade, o rastro é desenhado em faixas de opacidade (do mais novo, quase opaco, ao mais velho, tênue), sem gradiente contínuo.
- **Luz**: ilumina o próprio corpo (borda do lado da lâmina), o oponente quando perto, o chão (mancha de luz abaixo), as partículas e o ambiente (cristais, fungos, água, metal). Em impactos, o ambiente ganha por um instante o tom da lâmina.
- **Zumbido visual**: em guarda, a lâmina balança levemente com a respiração; o glow pulsa de leve.
- **Ignição**: no começo de cada round, acende da base à ponta. **Apagar**: no K.O., a lâmina do derrotado se apaga da ponta à base.
- **Desequilíbrio**: em `STAGGERED`, o glow tremula (o núcleo continua aceso). O jogador lê que o oponente está aberto sem texto.
- **Parry**: a lâmina de quem aparou clareia (flare branco curto).
- **Carga (Forja)**: o flare cresce a cada nível de carga.
- **Cabos**: desenho próprio por personagem, em metal com empunhadura escura: com anel no emissor (Guardião, Garça, Ancião, Soberano, Predestinado Aurora), pomo curvado (Sombra, Sombra Desperta, Predestinado Eclipse), empunhadura (Bastião, Vespa, Brasa, Eco), guarda atravessada (Forja), haste com faixas (Haste), cabo duplo marcado no centro (Ceifador), liso (Espelho).
- Lâminas especiais: mais grossa (Bastião, Sombra Desperta), muito larga (Forja), finas e curtas (Vespa), em haste (Haste), dupla de cabo único (Ceifador).

## Luz

- O cenário tem luz-base fraca; as lâminas iluminam os corpos de verdade (mapas de normal ou luz 3D, conforme a técnica).
- Luzes do cenário (lua, sol, neon, faróis) são fracas, frias e nunca mais fortes que uma lâmina.
- **Arenas de sombra**: o eclipse da Cidadela e a escuridão da Tempestade escurecem arena e corpos; lâminas, a luz delas e os efeitos continuam com cor total.
- Reflexos: água do Santuário, laje do Telhado, sal das Salinas e metal da Plataforma refletem lâminas (e, na água, os lutadores).

## Animação

### Princípios

- Toda ação tem 4 fases: **preparação** (o corpo e a lâmina anunciam o golpe) → **movimento** (arco rápido com rastro) → **impacto** (hit stop, efeitos) → **recuperação** (volta à guarda, momento vulnerável).
- A animação **obedece à simulação**: startup, active e recovery vêm dos dados do golpe; a animação é sincronizada a eles, nunca o contrário. A lâmina tem de passar pela hitbox real no active.
- **Velocidade com leitura**: a preparação é sempre legível, mesmo nos rápidos. O ativo é rápido e quase linear; a preparação desacelera no fim (antecipação); a recuperação volta com easing suave e follow-through curto.
- Nada de transições instantâneas ou poses que saltam: mistura curta entre ações e continuidade do arco nas sequências.
- **Sequências nunca repetem o arco**: cada golpe da cadeia tem trajetória própria e sai de onde o anterior terminou.
- Movimento secundário: capas, túnicas, cachecóis, cabelo, barbas e faixas reagem ao movimento, ao vento das arenas e aos impactos.

### Idle, caminhada e pulo

- **Idle**: respiração lenta, a lâmina balança levemente. Nunca totalmente parado. Exausto: respiração mais funda e guarda pendendo.
- **Caminhada**: passos curtos de base de luta (os pés não se cruzam), corpo sobe e desce, roupa arrasta para trás. Andar para trás é mais cauteloso.
- **Pulo**: impulso, pernas recolhidas, giros e cambalhotas conforme o personagem (a Garça e o Ceifador são os mais acrobáticos); pulo duplo com rotação; aterrissagem com peso.

### Famílias de movimento

Personagens com o mesmo jeito de lutar compartilham a base de animação.

| Família | Personagens | Intenção | Como aparece |
| --- | --- | --- | --- |
| Guardião | Guardião, Ancião, Predestinado, protagonista Técnica | econômico, preciso, guarda firme | base baixa, preparação curta, corte direto, quase sem follow-through, sem giro de lâmina |
| Vespa | Vespa | duas lâminas, giros curtos | base leve e inquieta, arcos alternados entre as lâminas, follow-through solto, giro de lâmina no fim da sequência |
| Agressor | Sombra, Sombra Desperta, protagonista Fúria | amplo, pressiona | tronco à frente, preparação alta atrás da cabeça, arcos longos com passo grande e quadril |
| Colosso | Bastião, Forja | pesado, inevitável | base larga e baixa, golpes curtos e secos, martelada sobre a cabeça, agacha no impacto, empurrão de ombro |
| Esgrimista | Espelho, Haste, Soberano | ereto, de ponta | tronco reto, preparação contida, estocadas com braço estendido, corte diagonal limpo |
| Dançarina | Garça, protagonista Voo | leve, acrobático | base alta, arcos largos com o corpo, pirueta na recuperação do forte |
| Golpeador | Brasa, Eco | enrolado, explosivo | base baixa, rápido subindo de baixo, forte ascendente com o corpo subindo junto |
| Ceifador | Ceifador | bastão duplo | bastão atravessado à frente, meias e voltas inteiras da arma, as pontas trocando de lugar |

### Poses de combate

| Estado | Pose |
| --- | --- |
| Rápido | lâmina recua curta, corte rápido com o tronco avançando, volta à guarda |
| Forte | preparação maior (lâmina bem atrás da cabeça, peso no pé de trás), corte longo com passo e quadril |
| Guarda | lâmina quase vertical à frente do corpo, mãos adiantadas, base baixa |
| Esquiva | corpo baixo e inclinado na direção da esquiva; rolamentos e saltos curtos conforme o personagem |
| Esquiva de precisão | inclinação breve para trás, joelhos baixos, recuo mínimo; varia a cada sucesso seguido |
| Atingido | tronco joga para trás, lâmina cai |
| Desequilibrado | tronco aberto, lâmina tremulando, base desfeita |
| Atordoado | corpo curvado, lâmina apontando para o chão, balanço lento |
| Morto | cai para trás e a lâmina apaga |
| Lançar poder | lâmina para trás, mão livre à frente, corpo inclinado |
| Canalizar | mão livre estendida, tremor leve |
| Invocar | lâmina baixa ao lado, mão livre erguida ao céu |
| Estrangular | quem segura: mão estendida e firme; vítima: erguida, mãos no pescoço, pernas pendendo, lâmina caída |
| Congelado | parado na pose do instante, dentro da casca de gelo de energia |

### Técnicas

- **Giro**: o corpo gira (frente → costas → frente) com a lâmina estendida quase na horizontal, passando pela frente, por trás e de volta.
- **Avanço com corte**: avanço baixo com corte diagonal de baixo para cima; o Guardião corta de cima para baixo; o Ceifador gira o bastão.
- **Arremesso da lâmina**: lâmina recua atrás do corpo, soltura com passo e braço estendido; a mão vazia acompanha a volta.
- **Estocada**: lâmina recolhida no peito, braço todo estendido, passo longo.
- **Corte ascendente**: corpo abaixa com a lâmina atrás do quadril e sobe com ela até acima da cabeça.
- **Rajada**: quatro idas e voltas rápidas alternando a altura.
- **Varredura**: corpo baixo, joelho da frente dobrado, lâmina rente ao chão.
- **Investida descendente**: no ar, joelhos encolhidos, lâmina para baixo e para a frente até o chão.
- **Contraguarda (Guardião)**: desvio para cima com faíscas, meio passo atrás, estocada curta.
- Na grade, o Giro é feito achatando o corpo na horizontal (frente → perfil fino → costas → frente) enquanto a lâmina encurta em escorço ao passar por trás; a mão livre abre a palma em poderes, empurrão e estrangulamento (peça `hand_open`).

### Disputa de lâminas

- Os dois se inclinam um contra o outro, base baixa, mãos recolhidas e erguidas; as lâminas cruzam num **X entre os rostos**, iluminando os dois.
- Quem está ganhando avança o tronco e o ponto de contato; quem perde recua e afunda a base. A leitura vem do corpo, sem barra nem número.
- Mãos e lâminas tremem cada vez mais; cada pressão é um empurrão curto da mão.
- **Vitória**: a lâmina empurra através do cruzamento até um corte baixo e volta à guarda, com o jeito da família (curto e controlado no Guardião, largo com giro na Vespa e na Dançarina, mínimo e preciso no Esgrimista, curto e pesado no Colosso). O perdedor fica desequilibrado.

### Finalizações

- **Braço**: fica o coto do ombro ao cotovelo; o antebraço com a mão sai girando (no braço da lâmina, o cabo já apagado cai junto).
- **Perna**: fica a coxa; canela e pé saem girando.
- **Cabeça**: o corpo cai sem a cabeça, com brasa no pescoço; a cabeça rola com capuz, máscara ou cabelo, sem rosto visível, e para no chão.
- A peça sai para longe de quem cortou, gira, pousa e fica no chão até o round acabar. Pontas cortadas em brasa que esfria em ~1,2 s. **Sem sangue**.
- Ferimento (braço/perna) durante o round: sombra discreta sobre o membro até a Cura terminar ou o round acabar.

## Interface

Minimalista, cinematográfica, legível e pouco intrusiva. Uma única fonte: **Oxanium** (SIL Open Font License). Detalhes em [UI_UX.md](UI_UX.md).

## O que evitar

- Aparência genérica de jogo mobile; brilho em tudo.
- Detalhe que apaga a silhueta.
- Animações robóticas, sem easing ou sem antecipação; velocidade ilegível.
- Gore, sangue, órgãos.
- Qualquer traje, rosto, capacete, marca ou símbolo reconhecível da franquia.
