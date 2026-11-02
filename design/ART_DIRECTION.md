# ART DIRECTION

Identidade visual do jogo. Segue [DESIGN.md](../DESIGN.md). Efeitos em [VFX.md](VFX.md); interface em [UI_UX.md](UI_UX.md).

## Identidade

O jogo deve transmitir: duelo cinematográfico, velocidade elegante, peso nos golpes, tensão, atmosfera sci-fi, contraste forte e combate de alto nível. A cena é escura; a luz e a cor saturada pertencem às lâminas.

Referências de **sensação** (nunca de assets): os duelos de sabre da trilogia prequel (coreografia veloz, acrobacia, cenários industriais e templos enormes, a lâmina iluminando rostos), duelos de samurai do cinema (tensão antes do golpe), Sekiro e For Honor (defesa no tempo certo), Nidhogg e Limbo (silhuetas fortes em cenários escuros), concept art sci-fi industrial e fotografia com neon em ambiente escuro.

## Técnica de apresentação

- O **duelo acontece num plano 2D lateral**. A câmera do duelo é lateral; profundidade é cenário. Infiltração e naves têm a exceção top-down autorizada em DESIGN, "Além do duelo".
- **Técnica decidida: pixel art sci-fi com esqueleto** (decisão da migração para pixel art; a versão em alta definição está na tag `phase-5-hd`). O mundo inteiro (arena, lutadores, lâminas, poderes e efeitos) é desenhado **nativamente numa grade de pixels baixa** e ampliado sem suavização. Não é um filtro sobre a arte em alta definição: cada peça é pintada direto na grade, com tons e contornos definidos.
- **Grade**: 1 pixel do mundo = **2 u** (0,5 px/u). Um lutador tem ~75 px de altura; no enquadramento neutro a grade tem ~480×270 e cada pixel ocupa ~4 px de uma tela 1080p. O zoom da câmera muda o tamanho de **todos** os pixels por igual (entre ~2,5 e ~4,5 px de tela), nunca reamostra uma peça isolada. A câmera anda em pixels inteiros da grade; o deslize suave vem do deslocamento da imagem final.
- **Peças**: o mesmo esqueleto (`Skeleton2D`, IK, tecidos com física, pose calculada da simulação por família de movimento). As peças são pintadas na grade sem antialias: borda dura, **4 tons por cor** (sombra, base, luz, brilho), **contorno seletivo** de 1 px (escuro no lado da sombra; no lado da luz, que vem da frente e de cima, a borda sobe um tom), para membros finos de 4–5 px não virarem só contorno, **luz de forma** pintada em cada peça (frente clara, costas escuras) e detalhe interno só onde ele lê em 1–2 px (olho, sobrancelha, nariz, brilho do cabelo, dobras de cotovelo e joelho, punho, biqueira e sola da bota, lapela da túnica, bolsa no cinto). A cabeça tem ~11 px de altura (proporção heroica, ~1/7 do corpo) e pescoço curto, para o rosto ler na grade. As peças de trás (perna, braço, capa) ficam acima do cenário na ordem de desenho, sempre visíveis. Os trajes trocam a paleta (8 slots), como num jogo de pixel art clássico. O mapa de normal é pintado na mesma grade: a luz das lâminas ilumina o corpo em degraus de pixel.
- **Rotação**: peças giram com o osso e são rasterizadas na grade (sem subpixel); por isso as peças são pequenas e com formas simples, que continuam limpas em qualquer ângulo.
- **Interface**: continua em alta resolução, com a Oxanium; só o mundo é pixel art.
- Descartados: filtro de pixelização sobre a arte em alta definição (proibido), sprites quadro a quadro (volume de arte enorme com 15 lutadores, 4 armas e variantes, e perderia a sincronia automática com a simulação) e 2.5D com modelos 3D.
- O pipeline anterior (alta definição, 4 px/u, fase 3) fica registrado em ARCHITECTURE.md; o formato das peças (mapa de material + mapa de normal) é o mesmo.

## Escala e enquadramento

### Infiltração — vista superior (task 10)

Vista ortográfica de cima, sem perspectiva/isometria: chão em grade, paredes com borda de metal e tampa vista de cima. Mantém **1 px = 2 u**, mundo nativo em SubViewport ampliado pelo `PixelStage`, câmera com centro preso à grade e interface em alta resolução. Câmera segue o jogador e respeita as bordas do mapa; cerca de 960×540 u visíveis a 1080p. Zoom uniforme, sem girar a câmera.

Tiles de 32×32 px: chão de placas escuras com juntas, rebites discretos e quatro tons; parede mais clara que o chão, topo e contorno seletivo; caixas com cantos reforçados; faixa de serviço discreta. Paleta de Infiltração no `UiPalette`, sem cores soltas nos scripts. Ferramenta original `tools/art/make_infiltration_tiles.py` gera atlas e sprites, sem imagens externas. Arte é pintada nessa grade, não reduzida a partir de imagens maiores.

Novo ponto de vista do pipeline: sprite simples e utilizável do Guardião visto de cima, 24×28 px, cabeça, ombros, túnica, cinto, mãos e botas legíveis, quatro tons dessaturados e contorno seletivo. Corpo orienta-se para a mira; passada curta alterna pés e torso sem deformar a silhueta; furtivo recolhe o corpo. Um boneco de treino e um emissor mecânico têm sprites próprios no mesmo atlas. A lâmina fica à frente da mão, ciano-gelo do tema, desenhada na grade com núcleo claro e halo curto; é a principal fonte de brilho. Não reutilizar o rig lateral visto de cima nem introduzir uma nova família estética. A arte inicial pode ser enriquecida depois sem alterar hitboxes.

Disparos usam branco quente do `UiPalette.bolt`, traço curto com núcleo claro, faíscas de desvio na lâmina e devolução na cor dela. Preparação e arco do golpe são legíveis; guarda mostra a lâmina transversal à mira. Na task 11, cones de visão são malha de baixa opacidade com borda tracejada, nunca preenchimento opaco; ícones/forma distinguem suspeita de alerta além da cor. Colisão/mira/setor de guarda só aparecem no F3, sem cones de detecção fictícios na task 10.

Na task 11, o atlas superior ganha soldado de ombros estreitos e arma lateral, sentinela mecânica com base angular e pesado de ombreiras largas. O painel é um terminal pequeno com indicador partido; portas de reforço têm marca de acesso no piso. Cones usam malha discreta e contorno tracejado, recortados nas paredes/caixas. Suspeita usa arco e `?`, alerta usa `!`; as formas persistem com efeitos reduzidos. Indicador de painel usa destaque quando disponível, perigo quando ativo e secundário cortado quando inutilizado, sem clarão global.

Task 12: os mapas de missão reutilizam o atlas industrial e a ferramenta de tiles. Terminal de informação é um monitor angular com duas barras; saída é contorno quadrado aberto e seta no piso; prisioneiro usa sprite superior sem arma de 24×28 px, gerado pela ferramenta existente com túnica clara da paleta e losango acima da cabeça, sem imitar personagem de outra obra. Geometria na mesma grade e cores do UiPalette; sem novos efeitos luminosos. Estados concluídos usam marca de confirmação além da cor. A apresentação só lê o estado da missão.

### Combate de naves — vista superior (task 13)

Mesma grade de 1 px = 2 u e filtro nearest, mundo no PixelStage e UI em alta resolução. Trama: sprite nativo de 40×40 px, casco hexagonal curto, proa chanfrada, espinha transversal e duas caixas de motor de comprimentos diferentes; cockpit pequeno, sem asas em X/H, esfera central ou silhuetas de franquias. Drone-alvo: 32×32 px, corpo octogonal achatado e emissor lateral curto, sem aparência de lutador. `tools/art/make_ships.py` gera ambos com quatro tons, contorno seletivo, rebites e placas; slots metálicos de prosthetic_metal/infiltration_wall, bordas de accent, cockpit de menu_blade_a, propulsão de menu_blade_b, tudo do UiPalette.

Espaço escuro: fundo background, estrelas em três planos discretos com paralaxe pela câmera, nebulosa em manchas conectadas de pixels de storm_cloud com opacidade baixa. A ferramenta de naves gera uma textura original periódica de 256×128 px, com quatro degraus de opacidade e contorno irregular; nenhum retângulo isolado parece painel atrás da luta. Sem imagens externas, ruído por frame ou brilho que concorra com tiros. Estrelas são geometria e manchas são textura procedural determinística de apresentação, sem colisão. Borda da área de treino marcada por traços e cantos discretos, sem parede futurista nova. Câmera segue a nave sem girar; mesma escala e centro preso à grade da Infiltração.

Tiro do jogador é um traço curto quente (`bolt`); drone usa ponta partida e borda de danger para separar por forma e cor. Futuro míssil terá corpo sólido e rastro descontínuo legível, diferente dos tiros. Impulso comprime a nave transversalmente e deixa dois ecos curtos, sem imitar avião real nem adicionar rolagem 3D. Escudo é contorno local em degraus, sem bolha permanente que esconda o casco.

Task 14 amplia a mesma ferramenta de naves: caça de proa curta e placas em cunha; interceptador comprido com motor deslocado; canhoneira larga com três bocas; lançador com dois compartimentos; torre angular em pedestal; gerador com bobina quadrada e motor com grelhas. Capital é espinha industrial de placas com seções separadas; chefe Ferro de maré tem casco largo irregular e três recessos de núcleo, sem asas ou composição de outra obra. Sprites de núcleo/gerador/motor continuam reconhecíveis apagados. Detritos são polígonos irregulares de quatro tons de rock/rock_light, gerados com semente local, sem fotografias. Míssil é cápsula sólida com chama e rastro curto descontínuo; distinto do traço da primária por forma. Núcleo fechado tem barras cruzadas; aberto tem contorno partido e marca central. Tamanhos e colisões vêm dos dados e continuam na grade de 2 u.

Nas missões, a câmera mantém o zoom uniforme de 1,8 e acompanha a nave com antecipação de 35% do deslocamento até o objetivo ativo, limitada a 240 u, a ±150 u na vertical e às bordas. Isso enquadra os núcleos e avisos da capital durante a aproximação sem reduzir a escala dos pixels e preserva espaço sob o HUD. É leitura de apresentação; não muda alvo, giro ou disparo do jogador.

### Duelo

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

### Armas de disparo (família Versáteis)

Desenhadas pelo jogo, como os cabos, na cor de metal e de couro do traje. **Blaster da Corsária** (revisto a pedido do autor, para ler como arma): cabo de couro inclinado com guarda-mato, corpo de 15 × 5,5 u com faixa escura embaixo, trilho claro em cima, cano mais escuro e boca clara; uma célula de energia na lateral, na cor do disparo (`UiPalette.bolt`). Em repouso aponta para o chão à frente; no tiro fica na horizontal. **Cabo do Lince**: um bloco preso de lado no cabo, perpendicular a ele e virado para a frente, com cano curto e lente na ponta, e um anel de gatilho perto da mão: o cabo parece uma empunhadura de pistola. A lente fica acesa fraca e brilha na cor do disparo a cada tiro. Nenhuma forma copia armas da franquia: sem cano longo com mira telescópica, sem anéis de refrigeração no cano.

### Disparos

Branco quente de baixa saturação `#ffe2b0` (`UiPalette.bolt`) com núcleo branco, em traço curto e duro. Fica fora do círculo saturado das lâminas e das cores do Fluxo, para o disparo ler como "não é lâmina" pela forma e pela saturação. Ver [VFX.md](VFX.md#disparos).

### Revisão de animação aprovada (próxima etapa)

Decisões do autor para a revisão de combate e animação (ver ROADMAP, fase 7.5). Só apresentação, salvo onde GAME_DESIGN indica regra nova. Referência de sensação: duelos técnicos, velozes e acrobáticos, com coreografia de esgrima e artes marciais; cada família com o seu corpo e temperamento.

**Postura e empunhadura por família** (a forma de segurar decide a silhueta):

| Família | Guarda | Empunhadura | Swing |
| --- | --- | --- | --- |
| Guardião (defensivo) | compacta e firme, lâmina diagonal à frente do rosto, cotovelos perto do corpo | duas mãos, a de trás no pomo | curto e econômico, volta rápida à guarda, bloqueios sucessivos |
| Esgrimista (técnico) | perfil estreito, braço da frente estendido, ponta para o rival | uma mão; a livre recuada atrás do corpo, na altura do ombro | estocadas e paradas curtas, punho mais que ombro |
| Agressor (ofensivo) | tronco à frente, lâmina baixa e para trás ou alta atrás da cabeça | duas mãos ao carregar, uma mão nos giros | arcos longos com quadril e passo grande, follow-through largo |
| Colosso (pesado) | base larga, lâmina alta sobre o ombro | duas mãos sempre | descendentes pesados, peso caindo na perna da frente |
| Dançarina (acrobático) | base alta e leve, lâmina para trás | troca de mão nos giros | arcos com o corpo inteiro, giros e piruetas |
| Vespa (duas lâminas) | uma lâmina alta à frente, a outra baixa e invertida atrás | uma lâmina em cada mão, com posição própria | as duas alternam: uma corta enquanto a outra guarda, nunca as duas paradas no mesmo ângulo |
| Versáteis (lâmina e disparo) | perfil de esgrimista, lâmina média à frente na altura do peito; mão livre baixa junto ao quadril | uma mão; a outra segura o blaster (Corsária) ou fica livre (Lince) | cortes curtos de punho com a lâmina atrasada em relação à mão e soltura em chicote (`wrist_lag` 1,6), follow-through maior; no tiro, o braço livre (ou o cabo, no Lince) estica na altura do peito com coice curto. Sequência da Corsária sem vaivém: o 1º rápido leva a lâmina por cima e para trás e sobe em concha, o 2º aproveita o fim alto para armar sobre o ombro e cortar à frente, o 3º recolhe e estoca |

- Mão de trás presa ao cabo por IK nas empunhaduras de duas mãos; nas de uma mão, a mão livre tem pose própria (equilíbrio, palma aberta nos poderes).
- **Revisão geral de braços e guardas (fase 8)**: as posições autoradas das mãos acompanham a rotação do tronco, no mesmo referencial anatômico dos ombros. O ângulo da lâmina continua no espaço do duelo para preservar a linha do corte e da defesa. Antes do IK, a empunhadura inteira cabe no alcance dos dois braços com folga; a mão de trás fica sobre o cabo, inclusive depois da mistura entre poses. Cotovelos têm preferência própria por braço, recolhidos na guarda e recuados na preparação. Só estocadas e a palma da Repulsão aproximam o braço da extensão completa. Guardas altas deixam espaço entre mão e rosto; guardas baixas conservam a dobra do cotovelo. As silhuetas aprovadas de cada personagem permanecem a referência.
  - Guardião, Ancião e Predestinado adiantam a empunhadura compacta à altura do peito; Bastião e Forja elevam as mãos à frente da têmpora, com a lâmina passando acima da cabeça rumo ao ombro; Sombra Desperta recolhe as mãos atrás da cabeça. Garça eleva a empunhadura para a lâmina passar acima do cabelo. Esgrimista estende o braço sem travar: Espelho vertical, Haste e Soberano apontados ao rival. Brasa conserva a lâmina invertida; Eco e Sombra conservam guardas baixas. Vespa separa as mãos à frente e atrás; Ceifador adianta o bastão e abre a distância entre as mãos. A mão livre de Esgrimista e Golpeador recua para equilibrar o corpo e relaxa na caminhada. Mão livre e segunda lâmina da Vespa ficam abaixo do ombro, perto do quadril e um pouco atrás, com o braço quase estendido e o cotovelo apontando para trás: nunca na altura do ombro, nem dobradas contra o peito.
  - O antebraço e a mão de trás passam à frente da roupa quando seguram o cabo ou alcançam a frente do corpo; o ombro continua na camada traseira. Isso evita que a túnica esconda a empunhadura. Na derrapada, quadril baixo e tronco recuado aproximam o ombro do chão antes de apoiar a palma.
  - A preferência do cotovelo da preparação retorna progressivamente durante o ativo, evitando trocar de direção no primeiro quadro do corte. Esquivas em ambos os sentidos, pulo duplo, transposição, recuperação e pressão de lâminas também passam pela mesma geometria de alcance e empunhadura.
- Implementado (fase 7.5): dados por família em `MotionFamily` (`back_hand_spacing`, `free_hand`, `off_guard_hand`/`off_guard_angle`, `wrist_lag`, `recover_share`, `one_hand_follow`) e guarda por personagem em `CharacterData`. Decisões de silhueta: a Sombra mantém a guarda baixa à frente e a Sombra Desperta usa a alta atrás da cabeça (as duas guardas do Agressor; a baixa e para trás confundiria com a empunhadura invertida da Brasa); Bastião e Forja passam a guardar a lâmina alta sobre o ombro; o Espelho mantém a lâmina vertical à frente do rosto (assinatura do personagem), com o braço estendido e a mão livre atrás, como o resto do Esgrimista; a Haste segura a haste com as duas mãos. Na Vespa, nos passos pares da sequência a lâmina da frente corta e a de trás guarda baixa e invertida balançando; nos ímpares a de trás conduz o corte e a da frente sobe para a guarda.
- **Cadeia ombro → cotovelo → punho**: o swing começa no ombro e no quadril, o cotovelo segue e o punho chega por último, girando a lâmina; a lâmina percorre o arco inteiro, sem pular de pose a pose.
- **Tipos de corte**: cada passo da sequência de rápidos de cada família recebe um tipo (horizontal no tronco, descendente, ascendente diagonal, estocada, giro como fecho), sem repetir dentro da sequência. O forte é sempre o mais comprometido (descendente ou giro largo). Exceção registrada: o forte do Golpeador (Brasa) continua ascendente com o corpo subindo junto, que é o golpe comprometido da família. Implementado como `MoveData.cut` (dado de cada golpe): o horizontal e o giro torcem o corpo (`RigPose.turn`), então a lâmina passa por trás em escorço e volta à frente no impacto. Sequências: Guardião, Ancião e Predestinado descendente → ascendente (→ estocada no Ancião); Agressor descendente → ascendente → estocada; Colosso descendente → ascendente; Vespa descendente → ascendente → estocada → horizontal → giro; Espelho descendente → ascendente; Haste e Soberano estocada → ascendente; Golpeador ascendente → descendente (→ estocada na Brasa); Garça descendente → horizontal → giro; Ceifador descendente → ascendente → estocada.
- **Escalas de tempo** (referência a 60 FPS): golpe rápido 6–12 quadros, combo ou contra-ataque 12–24, acrobacia ou disputa 24–48. Sempre antecipação, impacto (hitstop) e recuperação, com silhueta clara em cada fase.
- **Guarda direcional (só visual, revisão responsiva)**: a regra continua uma guarda só. A mão busca um ponto de interceptação na frente do corpo: durante a preparação lê a geometria prevista do golpe (tipo de corte, ângulo, empunhadura da família e altura do atacante) e passa progressivamente ao segmento realmente desenhado quando o contato se aproxima. Escolhe uma inclinação transversal à lâmina que chega, dentro do alcance dos braços e da dobra mínima, em vez de trocar entre quatro poses fixas. Sem segmento utilizável, a classificação alto/baixo/estocada continua como fallback, com posições e ângulos nos dados da família.
  - Empunhadura e ângulo seguem uma mola de segunda ordem amortecida, com velocidade preservada ao trocar o alvo. Pequeno recolhimento antecipa o golpe; bloqueio, parry e parry perfeito dão um impulso de recuo na direção da lâmina, maior no forte e mais contido no parry, com tronco e brilho existentes. O blockstun conserva a linha de contato até retomar o acompanhamento. A suavização externa não atrasa de novo a mão já acompanhada pela mola. Tudo só lê estado, segmentos e eventos.
  - Sem ameaça, a defesa tem postura própria da família, respiração, balanço discreto e deriva lenta para a altura da arma rival. Na caminhada em guarda, pés e peso acompanham a velocidade. Guardião, Ancião e Predestinado são compactos; Colosso, baixo e pesado; Esgrimista, ereto e econômico; Dançarina, amplo e fluido; Agressor, adiantado; Golpeador conserva a empunhadura invertida. Vespa cruza as duas lâminas contra fortes; Ceifador encontra o golpe com a parte central do bastão; Haste mantém a empunhadura longa de duas mãos.
    - Parâmetros em `MotionFamily`: postura, envelope de mãos, frequência/amortecimento, antecipação e recuo. O mesmo IK prende as duas mãos ao cabo quando necessário. F3 mostra interceptação no espaço do corpo, velocidade do acompanhamento e tempo previsto de contato. Grade, paleta, faíscas e sons continuam os do duelo.
    - Sincronização do ataque: os testes de contato revelaram que a pose antiga ainda estava inteiramente recolhida no primeiro tick ativo, quando o bloqueio já acontece. A soltura visual começa nos últimos 40% da preparação e chega a 75% do arco no primeiro tick ativo; o restante termina durante o active. Essa remarcação contínua é só da apresentação, parametrizada por família, sem antecipar hitbox, dano, rastro ou evento. Arremessos conservam sua própria marcação.
- **Salto de transposição**: ao passar por cima do oponente no pulo, cambalhota para a frente e aterrissagem já virado para ele.
- **Recuperação acrobática (só visual)**: nas separações longas (perder a disputa, choque grande, Repulsão), as famílias ágeis (Dançarina, Vespa, Ceifador) caem com mortal para trás e pousam em guarda; as outras derrapam com a mão no chão. O tempo de punição não muda. Implementado: perder a disputa, o choque entre técnicas e ser atingido pela Repulsão ou pela Repulsão Suprema disparam a recuperação (`MotionFamily.acrobatic_recovery`, `tumble_time`); o salto de transposição começa quando o lutador no pulo passa por cima do oponente (`vault_time`) e o desenho vira de lado no meio da cambalhota, antes de a simulação virar no pouso.
- **Esquiva com giro**: rotação baixa e curta atravessando o oponente (o corpo achata como no fecho girado das sequências), a lâmina recolhida junto ao corpo; pouso virado.
- **Pressão de lâminas**: como a disputa, mas mais baixa e móvel: as lâminas encostadas mudam de inclinação a cada pressão e os corpos andam meio passo. **Desengajamento**: rotação do punho que solta a lâmina por baixo e corta por outro ângulo, com rastro curto. Implementado como corte ascendente (`cut` ascendente no golpe `disengage`) que sai da pose da disputa: o ângulo da preparação passa por baixo do cruzamento.
- **Arremesso da lâmina com duas lâminas (Vespa)**: as duas saem com 0,06 s de intervalo, em arcos espelhados (uma um pouco acima, outra abaixo), cada uma girando no próprio sentido, e voltam cada uma para a sua mão; os braços acompanham as duas idas e voltas. Implementado só na apresentação (a simulação continua com um projétil): a segunda lâmina segue a primeira com o atraso em dado (`PowerVfxConfig.dual_throw_delay`, `dual_throw_arc`); enquanto as lâminas estão fora, as mãos ficam estendidas e abertas para a volta (em qualquer arma).

## Interface

Fundo `#05070d`, texto `#e8ecf5`, texto secundário `#8a94ab`, destaque `#9fb4d9`, perigo `#e5484d`. Cor saturada só para informação crítica.

### Ícones de poder

Os vinte e um poderes recebem glifos originais de 24×24 pixels, em `assets/ui/powers/<id>.png`, gerados deterministicamente por `tools/art/make_power_icons.py`. Silhuetas distintas representam a função: onda de empurrão, garra que puxa, arco de escudo, raio, cristal de gelo, aperto no pescoço e assim por diante. Tons planos e borda escura de um pixel, reutilizando o cálculo de borda do pintor; sem gradiente ou desenho cartunesco. A fonte de cores é `UiPalette`: Aurora `#5aa2ff`, Eclipse `#ff4458`, comuns no destaque `#9fb4d9`, borda no fundo e luz no texto. A tela mostra ×3 em 1080p (×2 em 720p), com filtro nearest; o detalhe pode ampliar para ×6. Estado bloqueado usa modulação secundária e moldura/legenda, sem cor nova. O ícone pertence ao próprio `PowerData`, para futura reutilização na Galeria e no HUD, sem catálogo paralelo.

## A lâmina

A lâmina é a protagonista visual e a principal fonte de luz.

- **Camadas**: núcleo branco fino, glow interno forte na cor da lâmina, glow externo largo e suave, bloom. Na grade: cada camada é um único polígono com a ponta afinada (núcleo de ~1,5 px, que nunca se quebra na diagonal; cor de 3 px; halo em dois degraus de 5 e 7 px), sem antialias e sem sobrepor transparências; um bloco branco de 2×2 px marca o emissor.
- **Rastro** (trail) durante o active dos golpes, na cor da lâmina, curto (~0,12 s), que mostra o arco exato do corte. Na grade, o rastro é desenhado em faixas de opacidade (do mais novo, quase opaco, ao mais velho, tênue), sem gradiente contínuo.
- **Luz**: ilumina o próprio corpo (borda do lado da lâmina), o oponente quando perto, o chão (mancha de luz abaixo), as partículas e o ambiente (cristais, fungos, água, metal). Em impactos, o ambiente ganha por um instante o tom da lâmina.
- **Zumbido visual**: em guarda, a lâmina balança levemente com a respiração; o glow pulsa de leve.
- **Ignição**: no começo de cada round, acende da base à ponta. **Apagar**: no K.O., a lâmina do derrotado se apaga da ponta à base.
- **Desequilíbrio**: em `STAGGERED`, o glow tremula (o núcleo continua aceso). O jogador lê que o oponente está aberto sem texto.
- **Parry**: a lâmina de quem aparou clareia (flare branco curto).
- **Carga (Forja)**: o flare cresce a cada nível de carga.
- **Cabos**: todos têm emissor mais largo e claro, pomo escuro, um fio de brilho lateral e um botão de 1 px na cor da lâmina; além disso, desenho próprio por personagem, em metal com empunhadura escura: com anel no emissor (Guardião, Garça, Ancião, Soberano, Predestinado Aurora), pomo curvado (Sombra, Sombra Desperta, Predestinado Eclipse), empunhadura (Bastião, Vespa, Brasa, Eco), guarda atravessada (Forja), haste com faixas (Haste), cabo duplo marcado no centro (Ceifador), liso (Espelho).
- Lâminas especiais: mais grossa (Bastião, Sombra Desperta), muito larga (Forja), finas e curtas (Vespa), em haste (Haste), dupla de cabo único (Ceifador).

## Luz

- O cenário tem luz-base fraca; as lâminas iluminam os corpos de verdade (mapas de normal ou luz 3D, conforme a técnica).
- Luzes do cenário (lua, sol, neon, faróis) são fracas, frias e nunca mais fortes que uma lâmina.
- **Arenas de sombra**: o eclipse da Cidadela e a escuridão da Tempestade escurecem arena e corpos; lâminas, a luz delas e os efeitos continuam com cor total.
- Reflexos: água do Santuário, laje do Telhado, sal das Salinas e metal da Plataforma refletem lâminas (e, na água, os lutadores).

## Animação

### Introduções dos lutadores

Entradas originais descritas em CHARACTERS.md, sem reproduzir enquadramentos, gestos ou silhuetas reconhecíveis de filmes. O corpo e a arma usam o mesmo rig, IK e grade de 2 u do combate. Preparação curta, gesto legível, ignição e assentamento na guarda da família antes do título; `blend_time` elimina o salto na liberação do combate. As duas armas da Vespa têm poses próprias durante o giro; o bastão do Ceifador acende as pontas em sequência. A câmera mantém ambos inteiros, sem aproximações adicionais, inclusive com efeitos reduzidos.

O Ceifador inicia imóvel, com capa e capuz temporários nas cores do traje. Leva a mão ao capuz e o baixa devagar em etapas na grade, encara o adversário, solta a capa, gira o cabo e acende uma ponta após a outra; termina na base baixa e larga da família. A capa solta usa o tecido existente e some em degraus antes do título; peças que pertencem ao traje escolhido permanecem. Pular remove somente os acessórios temporários. Sem novas texturas ou cores.

As Opções mantêm a lista centralizada dentro de uma área rolável entre título e rodapé; a linha destacada permanece visível ao navegar por teclado ou gamepad. A paleta grava explicitamente as quatro cores de tier no recurso para evitar que a carga antecipada do editor encontre um array nulo; são as mesmas cores aprovadas acima.

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
- **Pulo**: impulso, pernas recolhidas, giros e cambalhotas conforme o personagem; aterrissagem com peso. **Pulo duplo**: todos dão uma cambalhota completa encolhidos, com a lâmina esticada à frente desenhando uma roda. Por família (`MotionFamily`: `double_jump_turns`, `double_jump_time`, `double_jump_corkscrew`, `air_twirl`): a Dançarina (Garça) dá duas voltas em parafuso, a Vespa uma volta em parafuso, o Ceifador gira o bastão na mão durante o salto, o Colosso gira mais devagar e o Golpeador mais rápido.

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
| Esquiva de precisão | inclinação breve para trás, joelhos baixos, recuo mínimo; varia a cada sucesso seguido. Entra em 3 ticks, recolhe a lâmina para perto do corpo e a ergue, segura no sucesso e volta à guarda suavemente |
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

- **Avanço com corte** (revisão aprovada): **duas etapas**, como nos duelos de espadachim. 1) Arrancada: o corpo dispara rente e inclinado, a lâmina recolhida atrás do quadril, quase sem rastro, com imagens residuais. 2) Corte: no fim do avanço, um corte rápido e largo (diagonal de baixo para cima; o Guardião de cima para baixo; o Ceifador gira o bastão), com o rastro inteiro e uma pausa curta na pose final antes de voltar à guarda. Implementado: a família escolhe o corte (`MotionFamily.dash_cut`; o Guardião desce) e o Ceifador gira o bastão na arrancada (`dash_twirl`); a pausa ocupa o primeiro terço da recovery.
- **Corte Projetado**: preparação alta atrás da cabeça, corte amplo até o chão e uma onda na cor da lâmina, sem repetição por tier.
- **Arremesso da lâmina**: lâmina recua atrás do corpo, soltura com passo e braço estendido; a mão vazia acompanha a volta.
- **Estocada**: lâmina recolhida no peito, braço todo estendido, passo longo.
- **Corte ascendente**: corpo abaixa com a lâmina atrás do quadril e sobe com ela até acima da cabeça.
- **Rajada**: quatro idas e voltas rápidas alternando a altura.
- **Investida da Haste** (substitui a Varredura): haste recolhida na altura do quadril, passo longo e braço da frente esticado até a ponta; a mão de trás empurra o cabo.
- **Investida descendente** (revisão aprovada): no alto do pulo, o corpo se encolhe e vira para baixo com a lâmina erguida (antecipação curta); depois desce numa **estocada para baixo** (ponta à frente do corpo, duas mãos no cabo) ou num **corte descendente** que termina batendo a lâmina no chão (ou no oponente, se ele estiver embaixo). No pouso: faíscas e poeira no ponto em que a lâmina toca o chão, joelho dobrado e pausa curta antes da recovery. Por família: Agressor e Ceifador com o corte descendente; Dançarina com a estocada após uma pirueta. Implementado (`MotionFamily.plunge_cut`, `plunge_pirouette`): a lâmina desce nos primeiros quadros do ativo, porque a hitbox já existe desde o início do mergulho; as outras famílias (na Galeria) usam a estocada. Faíscas pela receita `plunge_impact` e poeira/pedrinhas (`PowerVfxConfig.plunge_dust`, `plunge_chunks`) na ponta da lâmina, no evento de pouso.
- **Contraguarda (Guardião)**: desvio para cima com faíscas, meio passo atrás, estocada curta.
- Na grade, giros do corpo (fecho girado das sequências, esquiva com giro) são feitos achatando o corpo na horizontal (frente → perfil fino → costas → frente) enquanto a lâmina encurta em escorço ao passar por trás; a técnica Giro foi removida na fase 8. A mão livre abre a palma em poderes, empurrão e estrangulamento (peça `hand_open`).

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
- A peça sai do lado certo: pela frente, o membro da frente; pelas costas, o de trás.
- **Queda pelo corte**: sem cabeça, o corpo cai de joelhos e depois tomba para a frente; sem perna, desaba rápido para trás; sem braço (ou sem finalização), cai para trás.
- **Brasa**: no coto, uma tampa em brasa (núcleo amarelo-quente `#ffd27a`, borda laranja `#ff7a2a`) esfria até cicatriz escura `#3a1a10` em ~1,6 s, pinga faíscas no primeiro 0,7 s e solta fumaça por ~3 s. A peça voa com rastro de brasa, solta fumaça ao pousar, e a cabeça rola pelo chão.
- **Personalização do protagonista** (fase 8): as bases do protagonista (Guardião, Sombra, Garça) têm peças opcionais de cabelo (`hair_short`, `hair_mid_wavy`, `hair_wavy`, `hair_long`, `hair_ponytail`, `hair_bun`), barba (`beard_short`, `beard_full`, `beard_long`, `beard_mustache`) e o peitoral de placas `plate` (no slot de acabamento, claro na Armadura de placas). A cor do cabelo e o tom de pele trocam os slots de paleta. Arquétipos, nunca réplicas.
- **Próteses** (fase 8, decisão do autor): o braço ou a perna perdidos num K.O. que não decide a partida voltam no round seguinte como **prótese robótica** até o fim da partida: o antebraço e a mão (ou a canela e a bota), que são as peças cortadas, trocam a paleta pelo metal (`UiPalette.prosthetic_metal`, material de prótese do rig), com a luz das lâminas por cima. Só apresentação.
- **Finalizações cinematográficas** (K.O. decisivo; regra em GAME_DESIGN, seção 10): o corpo é cortado por um plano no shader do lutador e uma segunda cópia do rig, na mesma pose, mostra a outra metade; as metades se separam com física própria da apresentação e a borda do corte fica em brasa (amarelo-quente → laranja → cicatriz) soltando fumaça. Sem sangue.
  - **Avanço com corte**: rastro reto e claro pelo caminho; quem corta aparece parado atrás da vítima com a lâmina estendida na horizontal (~1,1 s); a vítima fica de pé um instante, a metade de cima desliza devagar pelo corte, tomba e cai; a de baixo desaba.
  - **Corte Projetado**: o mesmo corte na cintura, sem o rastro de quem corta.
  - **Investida descendente e Corte ascendente**: corte vertical; as duas metades caem para os lados.
  - **Arremesso da lâmina**: corte diagonal na parte de cima, que escorrega e cai.
  - **Puxão**: a vítima chega puxada e é cortada ao meio; as metades seguem voando para trás de quem puxou.
  - **Raio**: ~0,6 s de raio-X (corpo escuro piscando e um esqueleto estilizado de traços claros, crânio em círculo), depois o corpo escurece até carbonizado, solta fumaça e cai.
  - **Repulsão e Repulsão Suprema**: estouro de brasa e faíscas; o corpo inteiro é arremessado longe num arco e cai deitado.
  - **Estrangular**: estalo de brasa no pescoço e a queda.
  - **Desarme e execução** (forte): no impacto, os dois antebraços saem girando e a lâmina da vítima apaga; ela cai de joelhos com os cotos em brasa. Quem corta recolhe a lâmina atrás do ombro e passa um corte horizontal na altura do pescoço, marcado por um rastro reto e claro na cor da lâmina; a cabeça sai rolando e o corpo tomba para a frente.
  - **Tesoura** (forte da Vespa): o mesmo desarme; as duas lâminas abrem para trás e se fecham em X na altura do pescoço, com dois rastros cruzados.
  - **Duas lâminas** (forte parado da lâmina simples e da haste): duas etapas bem separadas. (1) Dois cortes rápidos, um em cada antebraço. (2) O cabo apagado da vítima cai, quica e para no chão. (3) Quem corta estende a mão livre aberta; na palma aparece a bola do Puxão, o cabo treme envolto em anéis claros de Fluxo, sobe e voa num arco girando até a mão, que fecha; a lâmina acende na cor da vítima. Precisa parecer domínio do Fluxo, nunca a lâmina surgindo na mão. (4) As duas lâminas se abrem, uma alta e uma baixa, dos dois lados do pescoço, com uma pausa curta. (5) Fecham em X com dois rastros, cada um na cor da sua lâmina. (6) A cabeça sai; o corpo fica de pé um instante, cai de joelhos e tomba para a frente. (7) No fim, a lâmina emprestada apaga e o cabo cai da mão.
  - **Execução por cima** (forte parado do Colosso): o impacto empurra a vítima para trás e ela cai de joelhos; quem corta ergue a lâmina reta acima da cabeça, pausa e desce com força; o corte vertical separa as metades, que caem para os lados.
  - **Giro duplo** (forte parado do Ceifador): o bastão gira inteiro na frente do corpo e leva os dois antebraços; a vítima fica de pé sem as mãos; o segundo giro, mais largo, passa pelo pescoço; ela cai de joelhos e tomba.
  - **Giro** (forte de avanço da Garça): movimento contínuo. Corte baixo girando que desequilibra a vítima; a Garça passa por trás dela (desenhada atrás do corpo) em duas piruetas; de costas, corte horizontal no pescoço; a lâmina sobe num arco fluido; ela termina composta, lâmina baixa, enquanto o corpo cai. Três rastros: baixo, horizontal e subida.
  - **Estilo por personagem** (`FinisherStyle`): a coreografia é a mesma e muda o jeito. Soberano: deliberado, mais lento e ereto (domínio). Sombra Desperta: rápido, inclinado e com passo largo. Predestinado: confiante, sem esforço; gira a lâmina emprestada ao pegá-la. Ancião: lento e econômico, gestos curtos. Garça: fluida, pirueta e giro da lâmina na passagem para a preparação. Os outros usam a coreografia base.
  - **Estocada** (forte de avanço do Esgrimista): o braço estende e a lâmina atravessa o peito, com a ponta saindo pelas costas; no ponto de entrada abre um anel em brasa que esfria até cicatriz. Quem estoca segura um instante e recolhe; a vítima cai de joelhos e tomba para a frente.
- **Ferimento** (braço/perna) durante o round: talho cauterizado diagonal sobre o membro (borda vermelho-escura `#5a1410`, núcleo em brasa pulsando devagar), brasas subindo de vez em quando e sombra leve no membro, até a Cura terminar ou o round acabar. Braço ferido: guarda mais baixa. Perna ferida: manca (passada curta e o corpo afunda quando o peso cai nela).

## Interface

Minimalista, cinematográfica, legível e pouco intrusiva. Uma única fonte: **Oxanium** (SIL Open Font License). Detalhes em [UI_UX.md](UI_UX.md).

## O que evitar

- Aparência genérica de jogo mobile; brilho em tudo.
- Detalhe que apaga a silhueta.
- Animações robóticas, sem easing ou sem antecipação; velocidade ilegível.
- Gore, sangue, órgãos.
- Qualquer traje, rosto, capacete, marca ou símbolo reconhecível da franquia.


### Ícones de lâmina

Os nós de Lâmina usam a mesma grade de 24×24, contorno de um pixel, tons planos e filtro nearest dos ícones de poder. Glifos originais por estilo de técnica (arco, avanço, arremesso, estocada, ascendente, rajada, investida, mergulho e onda) mostram uma lâmina no destaque neutro do UiPalette. Habilidades usam um glifo por tipo (golpe, postura, avanço, carga, salto). Gerados por `tools/art/make_power_icons.py`, em `assets/ui/blade/<id>.png`; sem cor de caminho ou tier.

### Instinto Superior

Postura de ativação calma, joelhos suaves, lâmina baixa e palma aberta junto ao peito. Nas esquivas: inclinar o tronco contra horizontais/arcos, meio passo atrás contra ascendentes, giro curto em escorço contra estocadas e deslize baixo contra descendentes. Nenhum teleporte, cabelo transformado, silhueta nova ou referência visual de outra obra. A simulação escolhe e guarda a variante; a pose apenas a lê. Aura e olhos usam UiPalette.text com toque da cor de tier. O ícone de 24×24 representa um olho sob quatro marcas abertas de movimento, no azul da Aurora.

### Singularidade Devastadora (task 05)

Silhueta irregular de rocha em torno de um núcleo do fundo quase preto (UiPalette.background), com pequenos planos de UiPalette.rock e rock_light. O centro mistura flow_tiers[tier] com UiPalette.eclipse, mantendo o violeta do tier III e vermelho no Ápice. Arcos finos e faixas descontínuas na grade de pixels substituem distorção suave; nada de buraco negro fotográfico, espiral borrada ou nova paleta. O glifo de 24×24 é um anel quebrado e quatro placas convergentes, no Eclipse.
