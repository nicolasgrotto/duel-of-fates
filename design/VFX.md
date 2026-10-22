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
- **Cura que fecha ferimento**: luz suave na cor do tier sobre o corpo; a sombra do membro some.

## Poderes

Sempre na cor do tier de quem lança. Tiers mais altos mudam a **forma** (mais feixes, ondas maiores, mais pedras), nunca o alcance real.

- **Preparação de qualquer poder**: brilho na mão da frente que cresce até o instante ativo. É o aviso para o oponente.
- **Repulsão**: três ondas em forma de chevron ">" saem da mão em sequência e viajam até o alcance real, como cunhas de ar comprimido, com poeira subindo do chão.
- **Repulsão Suprema**: as ondas da Repulsão para os dois lados, com anel completo e poeira; como fuga, só um estouro curto e claro.
- **Puxão**: anel que nasce no alcance e se fecha na mão.
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
- **Tempestade**: na invocação, arcos pelo corpo e raios subindo da mão ao céu (1, 2, 3 pelo tier); a arena escurece (lâminas e efeitos com cor total); escudo de arcos girando em volta do corpo; marcas no chão que fecham até o impacto, com uma coluna fraca subindo; cada raio cai do céu com faíscas, luz, tremor pequeno e clarão curto. No Ápice, fissuras correm pelo chão a partir de cada raio.
- **Dreno**: fio de partículas do alvo até a mão (sentido inverso do Raio), que afina e esmaece perto do alcance máximo, para o alvo ler que pode romper.
- **Telecinese em Massa**: mini-cinemática (câmera recua e sobe, letterbox entra, asteroide desce e racha), depois pedras caindo em diagonal sobre as marcas, com rastro e fragmentos.
- **Corte de Fluxo**: meia-lua de energia na cor da lâmina, nascendo do rastro do corte; devolvida pelo parry perfeito, troca para a cor da lâmina de quem devolveu.
- **Arsenal Telecinético**: lâminas curtas de energia orbitando o corpo numa elipse (a da frente maior e opaca, a de trás menor e transparente); lançadas girando; ao segurar um projétil, partem-se em faíscas.
- **Resistido**: anel curto na cor do tier do **alvo**, como se o poder batesse numa parede.
- **Bloqueado / absorvido**: partículas e anel na cor da Barreira.

> Na grade de pixels: transparências que somem (faíscas, anéis, rastros, flashes) caem em 3 degraus de opacidade (`EffectsConfig.fade_steps`), sem degradê contínuo; o golpe forte acende uma estrela de 4 pontas na ponta da lâmina durante a preparação (aviso de golpe perigoso); a disputa de lâminas solta faíscas contínuas nas duas cores e um pulso em anel alternando as cores no ponto de contato.

> Implementado na fase 5 em `PowerView` (ver ARCHITECTURE), com formas vetoriais na camada aditiva. Ainda não entraram: poeira, o asteroide da Telecinese em Massa (a cinemática tem letterbox e recuo de câmera, depois a chuva sobre as marcas), pedras subindo na preparação do Arremesso e fragmentos de impacto. Cores dos tiers: `#9cc4ff`, `#5d8dff`, `#b26bff`, `#ff2b45` (`UiPalette.flow_tiers`).

## Técnicas de lâmina

Usam o rastro, o som e o impacto dos golpes fortes. O Giro desenha o círculo completo do rastro. O **choque entre técnicas** é o maior choque do jogo: clarão, tremor forte, anel e faíscas nas duas cores, os dois recuando visivelmente.

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
