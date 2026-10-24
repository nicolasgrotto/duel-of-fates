# VFX — Efeitos

Segue [ART_DIRECTION.md](ART_DIRECTION.md). Poderes em [content/POWERS.md](../content/POWERS.md).

## Princípios

- Efeitos são **curtos e fortes**. Nenhum efeito de combate passa de ~0,5 s, exceto o K.O. e os canais de poder (que duram o canal).
- A **intensidade acompanha a importância**: golpe leve < bloqueio < golpe forte < quebra de guarda < choque < K.O.
- O efeito **nunca esconde** o que o oponente está fazendo.
- **Cor**: faíscas de impacto brancas e amarelo-claras; luz de impacto na cor da lâmina de quem atacou (no choque, as duas cores); efeitos de poder na cor do **tier** de quem lança.
- Efeitos são **apresentação**: reagem aos eventos da simulação e nunca mudam o resultado.

```
Simulação → evento (hit, block, clash, death...)
Efeitos   → escolhe e cria as partículas, luzes e flashes
Câmera    → tremor, punch-in, enquadramento
Áudio     → som do evento
HUD       → barras, avisos
```

## Ferramentas de impacto

- **Hit stop**: a simulação congela por um instante no impacto (valores em GAME_DESIGN, seção 13); efeitos e câmera continuam. O atingido treme 2–3 u na horizontal durante o congelamento.
- **Câmera lenta**: só no **K.O.** (30% por 0,8 s) e no **parry perfeito** (50% por 0,25 s). Nenhum outro momento, para não perder o peso.
- **Punch-in**: zoom curto em direção ao contato, que volta em ~0,25 s: forte 3%, quebra de guarda 4%, parry perfeito 5%, K.O. 6%.
- **Tremor de câmera**: só em impactos fortes, curto (no máximo ~0,3 s).
- **Flash de tela**: camada aditiva que cai a zero, alpha máximo 0,35.
- **Hit flash**: o atingido fica branco por ~0,06 s.
- **Letterbox**: barras na intro do round, no K.O., curtas no parry perfeito, pulsando no despertar do chefe e na invocação da Telecinese em Massa.
- **Vibração do gamepad** acompanha os impactos (choque, golpe forte, pulsos fracos na disputa).

## Assinaturas

- **Dessaturação do parry perfeito**: por 0,15 s, arena e corpos perdem a cor e escurecem um pouco; lâminas, rastros e efeitos continuam com cor total. No momento mais importante, só a luz das lâminas tem cor.
- **Anel do parry**: círculo fino, aditivo, na cor da lâmina de quem aparou, crescendo e sumindo em ~0,25 s. Só existe no parry.
- **Lâmina tremulando** no desequilíbrio.
- **Lâmina apagando** no K.O.

## Catálogo

| Efeito | Quando | Elementos | Tremor | Flash |
| --- | --- | --- | --- | --- |
| Rastro da lâmina | active de um golpe | faixa na cor da lâmina, ~0,12 s | — | — |
| Luz da lâmina | sempre | luz no corpo, no chão e no ambiente | — | — |
| Faísca de acerto | rápido acerta | 6–10 faíscas, luz pequena | — | — |
| Impacto pesado | forte acerta | 12–16 faíscas, luz média | leve | fraco |
| Faísca de bloqueio | bloqueio | 10–16 faíscas, luz média | muito leve | — |
| Quebra de guarda | guarda quebra | 18–24 faíscas, luz forte | médio | fraco |
| Choque | clash | 24–32 faíscas, luz forte nas duas cores | forte | médio |
| Golpe final | K.O. | flash, tremor máximo, punch-in, câmera lenta | máximo | máximo |
| Parry | parry | 10–14 faíscas para cima, anel, lâmina clareia | leve | — |
| Parry perfeito | parry perfeito | 16–22 faíscas, anel maior, lâmina clareia, dessaturação, punch-in | médio | fraco |
| Empurrão | empurrão | 4–6 faíscas baixas, luz pequena, poeira | muito leve | — |
| Imagens residuais | esquiva e dash aéreo | 3 silhuetas transparentes que somem rápido | — | — |
| Brilho de esquiva | esquiva de precisão bem-sucedida | luz curta no peito na cor da lâmina de quem esquivou, sem anel | — | — |
| Ação recusada | falta Vigor/Fluxo | só HUD e som | — | — |

**Faíscas**: saem do contato na direção do golpe, num leque inclinado para cima; caem com gravidade e atrito; riscos curtos na direção do movimento, aditivos.

## Disputa de lâminas

Sem câmera lenta, sem dessaturação, sem tela sobreposta. A tensão vem da pose, do tremor, das faíscas e do som.

- **Entrada**: 16–22 faíscas em leque aberto, luz nas duas cores, tremor, flash fraco, hit stop curto, punch-in leve. Mais fraco que o choque, porque a disputa ainda vai se resolver.
- **Durante**: 1–2 faíscas contínuas no cruzamento; cada pressão solta 3–5 faíscas para o lado de quem foi empurrado e uma luz pequena **na cor da lâmina de quem apertou** (quem aperta mais acende mais a própria cor). O ponto de contato desliza na direção de quem está perdendo.
- **Vitória**: 12–16 faíscas na direção do perdedor, luz na cor do vencedor, tremor, flash fraco, hit flash no perdedor.
- **Empate**: 10–14 faíscas para os dois lados, luz nas duas cores, tremor leve.

## Consequências

- **Exaustão**: sem efeito de tela; o corpo mostra (respiração funda, guarda pendendo).
- **Ferimento**: impacto pesado mais faíscas baixas extras na direção do golpe; sombra sobre o membro ferido.
- **Finalização**: 10–14 faíscas na cor da lâmina de quem cortou, saindo do corte, brilho curto, brasa no coto e na peça. Usa a câmera lenta do K.O. A brasa é laranja `#ff7a2a` e esfria até a cor do corpo em ~1,2 s.
- Cores de faísca: branco `#ffffff` e amarelo-claro `#fff1b8`, alternadas. Na disputa, metade das faíscas de cada pressão vem na cor da lâmina de quem apertou.
- **Cura que fecha ferimento**: luz suave na cor do tier sobre o corpo; o talho e a sombra do membro somem.
- Detalhe do corte, da brasa, da fumaça e do talho em ART_DIRECTION ("Finalizações"); desenho em `CutMarks` (coto e talho, no rig) e `SeveredPiece` (peça).

## Poderes

Sempre na cor do tier de quem lança. Tiers mais altos mudam a **forma** (mais feixes, ondas maiores, mais pedras), nunca o alcance real.

- **Preparação de qualquer poder**: brilho na mão da frente que cresce até o instante ativo. É o aviso para o oponente.
- **Revisão aprovada dos poderes** (próxima etapa, ROADMAP fase 7.5):
  - **Repulsão (revisão aprovada da fase 8)**: palma aberta empurrando com o corpo (passo atrás, braço estendido de uma vez, recuo do ombro). Os três chevrons são substituídos por uma grande onda de choque de ar em arco `)`, convexa para o alvo e espelhada com o lutador. Nasce na palma desenhada e termina no limite real do poder, medido a partir da borda do corpo como na simulação. Cresce de meio corpo até pouco mais que a altura do lutador, afinando nas pontas. Borda frontal clara e fina, corpo translúcido em três faixas, um ou dois ecos fracos atrás, riscos de ar junto ao chão e a poeira existente. Cor do tier; tiers maiores aumentam altura, espessura e ecos, nunca o alcance. Repulsão Suprema usa a mesma onda para os dois lados, a partir do corpo, sem anel sólido. Grade de 2 u, sem antialias; fade em degraus de `EffectsConfig.fade_steps`. Efeitos reduzidos mantêm a onda principal legível e removem ecos e riscos adicionais. Parâmetros em `PowerVfxConfig`.
  - **Puxão**: hoje aparece uma bola atrás do oponente e nada em quem lança. Passa a ser a mão do lançador em garra puxando para trás, brilho na mão e um fio de energia da mão até o alvo que se recolhe junto com ele; no alvo, só um contorno curto. Sem esfera atrás do alvo. Implementado: a mão estende aberta na preparação e recolhe em garra no instante ativo (`PoseSolver._pull`); o fio (`PowerView` `TETHER`, `pull_tether_time`) vai da mão até o peito do alvo, limitado ao alcance do tier, e encurta enquanto o alvo é puxado; o contorno (`OUTLINE`, `pull_outline_time`) só aparece se o Puxão acertou.
  - **Raio, tiers 3 e 4**: os feixes estão juntos demais e parecem um feixe grosso. Abrir em leque, com origem nos dedos (desvio de alguns pixels), ângulos distintos (mínimo ~6 px de separação no meio do caminho), fases de tremor diferentes e chegada em pontos diferentes do corpo. Implementado em `PowerView._draw_lightning_fan` com os números do grupo Lightning do `PowerVfxConfig` (intervalo entre dedos, entre pontos de chegada, curvatura do leque no meio e defasagem do tremor).
  - **Telecinese em Massa**: a cinemática passa rápido demais, parece acelerada. Alvo de ~1,5 s (subida ~0,45 s, meteoro rachando ~0,6 s, descida ~0,45 s). Para caber sem mudar o resultado, o poder ganha um congelamento determinístico da simulação no evento ativo (como um hitstop longo, em dado do poder), e a cinemática roda dentro dele. Implementado: `PowerData.cinematic_freeze` (1,05 s = subida + meteor rachando) congela a simulação inteira (`MatchSimulation.cinematic_ticks`: lutadores, marcas, projéteis e entradas); a descida da câmera (0,45 s) acontece já com as marcas contando, antes do primeiro impacto (0,5 s), e os pedaços caem ao longo do atraso de cada marca. Números da câmera e do meteoro em `PowerVfxConfig` (`mass_rise`, `mass_hold`, `mass_descend`, `meteor_crack`).
  - **Corte de Fluxo**: o swing precisa ser grande: preparação com a lâmina bem atrás e acima da cabeça e arco inteiro até a lâmina bater no chão, de onde nasce o arco de energia. No tier 4, os cortes seguidos ficam espaçados (no mínimo 0,35 s entre eles, em dado), cada um com o arco completo. Implementado: `PowerData.apex_repeat_delay` (0,35 s) separa as duas ondas e alonga a recovery do Ápice pelo mesmo tempo (`recovery_ticks_at`); a pose (`PoseSolver._flow_cleave`) ergue a lâmina atrás da cabeça, desce até o chão no instante da onda e, no Ápice, volta por baixo e desce de novo.
- **Repulsão**: grande arco de ar comprimido `)` saindo da palma até o alcance real; cresce durante a viagem, com borda fina clara, corpo translúcido em faixas e pontas afinadas, ecos fracos, riscos baixos e poeira. Forma e redução de efeitos conforme a revisão aprovada acima.
- **Repulsão Suprema**: a mesma onda de ar para os dois lados, `(` e `)`, saindo do corpo, com poeira; como fuga, um estouro curto e claro. Os tiers não alteram o alcance.
- **Puxão**: fio de energia da mão até o alvo, que se recolhe com ele (ver a revisão acima).
- **Arremesso**: pedras sobem do chão com poeira na preparação e são lançadas girando; contorno fino na cor do tier; fragmentos escuros no impacto. 1 a 4 pedras pelo tier.
- **Truque Mental**: anéis elípticos ondulando sobre a cabeça do alvo. Sem filtro de tela (não atrapalha a tela compartilhada).
- **Fratura**: golpe no chão com poeira; uma linha de fissuras luminosas corre à frente e cada trecho explode em sequência (luz, faíscas para cima, pedrinhas). O trecho rachado ainda não explodido tem de ser legível para o pulo.
- **Barreira**: domo grande que pulsa e clareia ao absorver; cresce com o tier.
- **Santuário**: casca justa ao corpo, menor que a Barreira; racha em etapas conforme absorve e estilhaça ao quebrar.
- **Absorção**: brilho na mão com luzes girando e entrando nela; cada poder absorvido fecha um anel e é puxado em partículas para a mão.
- **Cura**: brilho que sobe do quadril ao peito.
- **Foco**: aura calma — contorno contínuo atrás do corpo respirando devagar e dois pontos de luz orbitando o peito.
- **Ira**: aura agressiva — contorno atrás do corpo que treme irregularmente e brasas subindo dos ombros. Cada carga de armadura gasta acende um anel no centro do corpo.
- **Raio**: feixes trêmulos da mão até o alvo (1, 1 com ramo, 2, 3 pelo tier), redesenhados em intervalos curtos; flash no atingido a cada pulso.
- **Estrangular**: brilho pulsando no pescoço da vítima, que sobe aos poucos e treme no ar; quem estrangula fica firme, transmitindo controle; na soltura, a vítima cai com poeira.
- **Congelar**: casca fina em volta do corpo com brilho fixo e silhuetas defasadas tremendo rápido; some quando o golpe quebra o gelo.
- **Tempestade**: na invocação, arcos pelo corpo e raios subindo da mão ao céu (1, 2, 3 pelo tier); depois que o poder sai, a arena escurece (lâminas e efeitos com cor total) e **o céu do fundo se eletriza**: faixas de nuvem com borda irregular descem sobre o cenário (atrás das colunas, à frente do vazio), relâmpagos distantes caem das nuvens a cada ~0,3 s e cada um clareia as nuvens na cor do tier e a arena por um instante; escudo de arcos girando em volta do corpo; marcas no chão que fecham até o impacto, com uma coluna fraca subindo; cada raio cai do céu com faíscas, luz, tremor pequeno e clarão curto. No Ápice, fissuras correm pelo chão a partir de cada raio.
- **Dreno**: fio de partículas do alvo até a mão (sentido inverso do Raio), que afina e esmaece perto do alcance máximo, para o alvo ler que pode romper.
- **Telecinese em Massa**: na preparação, só a mão erguida com o brilho de aviso. **Quando o poder sai** (evento ativo, nunca na preparação interrompível), a mini-cinemática: letterbox, a câmera recua e **sobe ao céu** (~0,2 s), o meteoro chega puxado na diagonal com contorno e brilho do tier, racha com fissuras brancas e se parte num clarão (~0,28 s), e **a câmera desce** (~0,22 s) acompanhando os pedaços, que caem acelerando cada um sobre a sua marca, com rastro; cada impacto solta anel, poeira e fragmentos. O tempo das marcas não muda: a cinemática cabe antes do primeiro impacto.
- **Corte de Fluxo**: **arco vertical** de energia na cor da lâmina que nasce do chão (cresce nos primeiros ~70 u), grosso embaixo e fino em cima, levemente curvado para a frente, com núcleo branco, um eco mais fraco atrás e faíscas correndo rente ao chão; devolvida pelo parry perfeito, troca para a cor da lâmina de quem devolveu.
- **Arsenal Telecinético**: lâminas curtas de energia orbitando o corpo numa elipse (a da frente maior e opaca, a de trás menor e transparente); lançadas girando; ao segurar um projétil, partem-se em faíscas.
- **Resistido**: anel curto na cor do tier do **alvo**, como se o poder batesse numa parede.
- **Bloqueado / absorvido**: partículas e anel na cor da Barreira.

> Na grade de pixels: transparências que somem (faíscas, anéis, rastros, flashes) caem em 3 degraus de opacidade (`EffectsConfig.fade_steps`), sem degradê contínuo; o golpe forte acende uma estrela de 4 pontas na ponta da lâmina durante a preparação (aviso de golpe perigoso); a disputa de lâminas solta faíscas contínuas nas duas cores e um pulso em anel alternando as cores no ponto de contato.

> Implementado em `PowerView` (brilhos, na camada aditiva), `DebrisLayer` (o que é sólido: poeira, pedras do Arremesso subindo na preparação e voando, meteoro, pedaços da chuva, fragmentos de impacto; na camada normal do mundo, escurecida pela arena) e `StormSky` (céu da Tempestade). Números em `data/balance/power_vfx_config.tres`. Regra: **cinemáticas e efeitos de invocação só começam no evento ativo do poder**; na preparação, que ainda pode ser interrompida, só existe o aviso (brilho na mão e pose). Exceção legível: as pedras do Arremesso sobem na preparação (é o aviso) e caem de volta, com fragmentos, se o lançamento for interrompido. Poeira também no empurrão, na Repulsão, na Fratura e nos raios da Tempestade. Cores dos tiers: `#9cc4ff`, `#5d8dff`, `#b26bff`, `#ff2b45` (`UiPalette.flow_tiers`).

## Técnicas de lâmina

Usam o rastro, o som e o impacto dos golpes fortes. O **choque entre técnicas** é o maior choque do jogo: clarão, tremor forte, anel e faíscas nas duas cores, os dois recuando visivelmente.

## Arena

Poeira no knockback (Salinas), cristais e fungos que pegam a cor da lâmina, vapor nas lâminas sob a chuva, ondulações na água, vento nas capas: tudo como apresentação, sem mudar a simulação.

## Receitas e implementação provisória

As contagens de faíscas, tremor, flash e punch-in deste catálogo estão em `data/balance/effects_config.tres`, uma receita por evento. Nas fases 1 e 2 a lâmina é desenhada em três camadas aditivas (glow externo, glow interno, núcleo branco) com rastro de ~0,12 s e uma `PointLight2D` na cor da lâmina; o glow de tela do `WorldEnvironment` é sutil (ver ARCHITECTURE, verificação do renderer). Letterbox e câmera lenta já funcionam; a dessaturação do parry perfeito entra na fase 3.

## Efeitos reduzidos

Opção de acessibilidade: tremor e punch-in a 25%, flash e hit flash desligados, menos partículas. Hit stop, câmera lenta e dessaturação continuam (não piscam nem tremem).

## Limites de referência

| Parâmetro | Limite |
| --- | --- |
| Tremor de câmera | amplitude ~12 u, duração ≤ 0,3 s |
| Flash de tela | alpha ≤ 0,35 |
| Hit stop | 0,03 a 0,1 s |
| Punch-in | ≤ 6% |
| Dessaturação | 0,15 s |

Partículas e luzes usam pools e reaproveitamento; o orçamento é medido no profiling (ver ARCHITECTURE.md), não fixado aqui.
