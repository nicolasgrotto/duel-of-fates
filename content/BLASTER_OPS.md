# Operações de blaster

Fundação de tiro em visão superior (task 16), sobre a geometria, atores e navegação da Infiltração. O duelo e as missões de Infiltração conservam suas regras. Esta entrega contém **Pátio de calibração / Calibration Yard**, treino reiniciável, sem vitória, recompensa, save de progresso ou entrada pública. Rota técnica `blaster_ops_training`, cena `screens/blaster_ops/blaster_ops_training.tscn`; pode ser executada no editor. A task 17 acrescentará as missões e Jogar › Modos especiais › Operações de blaster.

## Jogador e controles

Movimento livre normalizado em oito direções, 240 u/s, aceleração 2.200 u/s², desaceleração 2.800 u/s², corpo de raio 18 u e vida 100. Mira independente: mouse ou stick direito; ao soltar o stick, mantém a última mira. Sem mira explícita, o primeiro movimento define a direção inicial. Sem pulo, furtividade, abate silencioso ou interação nesta etapa.

| Ação | Teclado e mouse padrão | Controle padrão |
| --- | --- | --- |
| Mover | WASD / setas | stick esquerdo / D-pad |
| Mirar | mouse | stick direito |
| Disparar | botão esquerdo / Espaço | botão oeste (Rápido) |
| Guarda / parry | botão direito / Q | botão de guarda do J1 |
| Esquivar | Shift | botão de esquiva do J1 |
| Poder equipado | E | gatilho de poder do J1 |
| Pausa | ação de pausa do J1 | Start |

Ações `blaster_ops_*` próprias pelo InputMap. Teclas e botões são remapeáveis em **Teclas e botões › Operações de blaster**; mouse e eixos de mira permanecem disponíveis. Botões padrão copiam os bindings do J1, sem alterar o duelo. A tela Controles tem uma página do modo e as dicas vêm de ControlHints. Na pausa do treino é possível reiniciar com outro personagem (Corsária, Lince, Coldre ou Guardião) e outro poder; toda troca reinicia, sem mudar recurso compartilhado ou campanha.

## Tiro e calor

Armas usam `BlasterData` e `BoltData`. O conjunto do modo define escala de dano, cadência e calor; não modifica as armas do duelo.

| Conjunto | Dano | Velocidade / alcance | Cadência | Calor por tiro |
| --- | --- | --- | --- | --- |
| Pistola (Corsária e Coldre) | 10 (4 × 2,5) | 900 / 1.100 u | 0,16 s | 20 |
| Emissor (Lince) | 10 (4 × 2,5) | 900 / 1.100 u | 0,16 s | 20 |
| Rifle de dorso (conjunto explícito da futura Saga) | 20 (8 × 2,5) | 650 / 1.500 u | 0,42 s | 30 |
| Pistola temporária (personagem só de lâmina) | 6 | 850 / 1.000 u | 0,22 s | 25 |

Capacidade de calor 100, resfriamento 30/s após 0,25 s sem tiro. Atingir 100 trava a arma por **ao menos 1 s e até chegar a 40**, com resfriamento imediato durante a trava. Soltar e reapertar não limpa a trava. Guarda, esquiva, preparação do poder e tranco impedem tiro. Pool cheio ou saída dentro da parede recusa sem cobrar calor/cadência; não sobrescreve disparos. Sem munição, recarga manual, itens ou dano de contato.

Disparos são varridos contra paredes, caixas e corpos; só acertam o primeiro obstáculo. Inimigos não se acertam. O dano de um disparo devolvido continua o do projétil original. Guarda frontal cobre 140° e gasta o Vigor do BoltData; Vigor 100, regeneração 25/s após 0,6 s. Janela de parry/recarga vem do CombatConfig (0,20 / 0,40 s); perfeito nos primeiros 0,08 s aumenta velocidade a 125%, mas a direção continua sendo **a mira do jogador**. Não há mira automática no emissor. Todos os personagens com lâmina podem desviar; os sem blaster pagam com primária mais fraca. Guarda reduz movimento a 60% e exclui tiro.

## Esquiva e poderes

Esquiva: novo toque, duração 0,26 s, velocidade 720 u/s e recarga 0,90 s desde a ativação. Direção do movimento, ou da mira se parado, travada durante o dash. Colide com paredes, caixas e corpos. Invulnerável com idade de **3 a 11 ticks**; precisão de **3 a 8 ticks**, intervalos de fim exclusivos 12 e 9. Disparo que cruza a precisão zera a recarga uma vez por esquiva. Outra passagem invulnerável não restitui recarga. O projétil continua voando e não pode ferir o jogador até ser devolvido; não há devolução automática. Preparação e cauda são vulneráveis; dano não cancela o trajeto. Recarga zerada só permite outro dash depois de acabar o atual.

Um poder equipado, sem acorde ou barra de Fluxo. Preparação vem de PowerData, movimento a 60% e sem tiro; esquiva cancela a preparação e mantém a recarga gasta. Dano que causa tranco também interrompe a preparação. O efeito só começa quando a preparação termina. Paredes/caixas bloqueiam os poderes direcionais.

| Poder | Adaptação | Recarga |
| --- | --- | --- |
| Repulsão | cone de 100°, alcance 320 u, dano 6, tranco 0,40 s e impulso de 950 u/s por 0,16 s, limitados pela colisão | 6 s |
| Puxão | alvo mais próximo no cone de 60°, alcance 320 u, dano 4, tranco 0,45 s e aproximação a 330 u/s por 0,24 s | 7 s |
| Barreira | absorve até 95 de dano de disparos por 1,5 s, excedente fere; sem proteção contra corpo a corpo | 8 s |

Alcance, dano, preparação, tranco, potência e duração reutilizam os PowerData existentes quando aplicáveis; ângulos, duração dos impulsos e recargas são dados da adaptação. Sem mortes cinematográficas ou membros cortados no plano superior.

## Inimigos e cobertura

Arquétipos próprios em `data/blaster_ops/enemies/` estendem os da Infiltração, com percepção e controlador por intenção. Dano revela só a origem do tiro e provoca investigação/alerta; não há visão através das paredes. No treino, os guardas começam alertados para praticar os padrões.

| Arquétipo | Vida / velocidade | Ataque | Preparação antes de cada ataque |
| --- | --- | --- | --- |
| Soldado | 24 / 110 u/s | um tiro, dano 7, recarga 1,1 s | 0,20 s, ponto na boca da arma |
| Atirador | 18 / parado | tiro de dano 14, velocidade 1.100 u/s, recarga 1,8 s | 0,65 s, linha de mira travada |
| Pesado | 48 / 70 u/s | três tiros de dano 7, pausa 0,12 s entre preparações, recarga 1,5 s | 0,12 s por tiro; armadura frontal de 120° recebe 35% do dano |
| Investidor | 28 / 200 u/s | corpo a corpo, alcance 48 u, dano 12, recarga 0,8 s | 0,25 s, arco curto travado; guarda gasta 14 de Vigor, parry causa tranco |

Mira trava durante a preparação de cada ataque. Perder intenção de ataque cancela a preparação; um tiro preparado só sai com linha livre e alvo ainda vivo. Corpo a corpo verifica alcance, setor e parede na resolução, e pode ser evitado saindo do arco. Armadura não depende de cor: placa/contorno frontal e faísca de impacto mostram a redução.

Caixas destrutíveis ocupam tiles marcados, têm 30 de vida e três estados visuais (íntegra, amassada até 20, rachada até 10); com zero viram destroço baixo passável. Paredes e caixas sem marca continuam indestrutíveis. Disparo que destrói a caixa se encerra nela; o próximo pode atravessar. Navegação e percepção passam a usar a abertura no próximo tick, inclusive após restaurar snapshot. O mapa original e seus recursos nunca são alterados. Sem reaparecimento automático nesta etapa; reiniciar restaura corpos, caixas, tiros, calor e recargas.
