# Operações de blaster

Núcleo superior de Operações, iniciado na task 16 e compartilhado com Infiltração na task 17. **Pátio de calibração / Calibration Yard** permanece treino reiniciável, sem vitória, recompensa, save de progresso ou entrada pública; a cena `screens/blaster_ops/blaster_ops_training.tscn` pode ser executada no editor, sem rota no roteador. As seis Infiltrações e sete Incursões usam o mesmo núcleo em Jogar › Modos especiais › Operações. O duelo não muda.

**Operações (tasks 17–18):** o núcleo atende Infiltração e Incursão no menu único Operações; o Pátio continua treino técnico, com o mesmo moveset das missões. Espaço esquiva, Shift alterna corrida, C alterna furtivo, E interage, F corta ou abate, 1/2/3 lançam poderes (R também o primeiro), X troca de arma, mouse esquerdo ou V dispara/corta e direito/Q guarda. Nenhum personagem recebe arma temporária. Armas explícitas da História mantêm shot_count, shot_interval e vigor_multiplier (escala de calor); preço não tem função neste modo. As seções históricas abaixo da task 16 são substituídas por GAME_DESIGN, "Operações: Infiltração e Incursão", nestes pontos.

## Jogador e controles

## Missões de Incursão (task 18)

Todas disponíveis em Operações, com personagem livre e possíveis só com lâmina. Ciclo: entrada → ondas/objetivo → última onda → extração → resultado. A última onda tem rótulo próprio; a extração só abre quando objetivos e ondas terminam. Morte do jogador ou do protegido prevalece sobre vitória no mesmo tick. Inimigos e tiros continuam vivos durante o banner, sem dano posterior ao resultado.

| Missão | Objetivo | Variação |
| --- | --- | --- |
| Pátio cercado | Vencer três ondas | Arena aberta, soldados, investidor e pesado |
| Linha de ruptura | Destruir três torres e resistir ao reforço | Assalto em corredor largo, coberturas destrutíveis |
| Nó de defesa | Proteger terminal durante três ondas | Até duas barreiras implantáveis por tentativa |
| Janela de extração | Resistir 45 s e vencer a última onda | Início da onda final espera o relógio, sem exigir eliminar antes todos os inimigos |
| Corredor dos aliados | Escoltar aliado vivo à saída e resistir ao reforço | Aliado anda a 90 u/s enquanto acompanhado a até 320 u |
| Vetor de recuo | Vencer rival e sua guarda final | Rival com tiro dirigido, leque e avanço corpo a corpo |
| Núcleo de cerco | Vencer chefe em três fases e sua última guarda | Limiar inclusivo em 65% e 30%, sem cura ou retorno de fase |

Ondas têm slots fixos pré-alocados; ponto ocupado adia entrada, nunca teleporta um corpo sobre outro. Intervalo de montagem de 6 s antes da primeira onda e entre ondas, configurável. Defesa permite E/Interagir para implantar barreira 96 u à frente da mira somente nesse intervalo: tile vazio, quatro vizinhos livres, sem corpo no local, no máximo duas implantações por tentativa. Cada barreira absorve 60 de dano, bloqueia movimento/tiros dos dois lados e não concede reembolso; sua destruição reabre a navegação.

Defesa usa terminal de 240 de vida; Escolta usa aliado de 180. Prisioneiros secundários têm 60 e não são exigidos para vencer. E liberta antes de tentar construir. Aliados usam o controlador de escolta existente e intenção de tiro simples contra alvo visível a até 480 u: dano 4, intervalo 1,2 s. Não disparam por conta própria na simulação; não ferem jogador ou outros aliados. Nenhum ataque do jogador fere aliados. Precisão conta cortes conectados e tiros do jogador que atingem inimigo; leques/rajadas contam cada projétil, sem incluir tiros aliados ou devoluções. Sem ataques, precisão é zero.

Rival e chefe têm fases por Resource: configuração de ataque, limiar e título. Cada ataque prepara antes de sair, inclusive leques. Troca de fase interrompe preparação antiga, preserva projéteis já disparados e processa limiares vivos em ordem; não muda vida. A IA só produz intenção, incluindo aproximação e passos laterais do rival. Torres são inimigos imóveis, vulneráveis ao corte e ao disparo.

Avaliação de sucesso: 1 ponto por tempo até o limite inclusivo da missão, dano recebido até 25, precisão de pelo menos 50% e bônus de missão (todos os prisioneiros secundários vivos e libertados, ou protegido com pelo menos metade da vida; sem secundário, destruir todas as defesas). S = 4 pontos, A = 3, B = 2, C = 0–1; derrota não recebe nota ou recompensa. Save conserva menor tempo, melhor nota e união de bônus por ID, com migração por ausência. Primeira vitória concede cor do Arcade do Guardião; completar as sete concede traje Viajante do Guardião, sem duplicar recompensas. Nada cobra ou concede moeda no modo avulso.

API externa: missão + personagem + conjunto explícitos; resultado contém objetivo, ticks, dano, acertos/tentativas, bônus e nota. O modo externo emite resultado uma vez, não escreve SaveService e não troca de tela; saída na pausa emite pedido de saída. A futura Saga controla créditos e próxima cena.

Movimento livre normalizado em oito direções, 240 u/s, aceleração 2.200 u/s², desaceleração 2.800 u/s², corpo de raio 18 u e vida 100. Mira independente: mouse ou stick direito; ao soltar o stick, mantém a última mira. Sem mira explícita, o primeiro movimento define a direção inicial. Corrida, furtivo, abate e interação seguem a Infiltração; sem pulo.

| Ação | Teclado e mouse padrão | Controle padrão |
| --- | --- | --- |
| Mover | WASD / setas | stick esquerdo / D-pad |
| Mirar | mouse | stick direito |
| Disparar / cortar sem blaster | botão esquerdo / V | botão oeste (Rápido) |
| Guarda / parry | botão direito / Q | gatilho de guarda do J1 |
| Esquivar | Espaço | botão de esquiva do J1 |
| Correr (alterna) | Shift | stick esquerdo pressionado |
| Furtivo (alterna) | C | habilidade do J1 |
| Corte / abate | F | forte do J1 |
| Interagir | E | A/Cruz |
| Poder 1 | 1 / R | gatilho de poder do J1 |
| Poder 2 | 2 | ombro esquerdo |
| Poder 3 | 3 | stick direito pressionado |
| Trocar arma | X | Back/Select |
| Pausa | ação de pausa do J1 | Start |

Correr e furtivo são alternâncias no controlador: um toque liga, outro desliga, e ligar um desliga o outro; a pausa conserva a postura e reiniciar a limpa. Nenhuma ação usa Ctrl, Alt ou Meta, e a tela de teclas recusa essas teclas, porque o navegador reserva combinações como Ctrl+W. Teclas salvas no layout anterior são migradas sem perder personalizações: sai só Ctrl, e teclas novas entram apenas se estiverem livres. Ações `blaster_ops_*` próprias pelo InputMap, com aliases `infiltration_*` para compatibilidade. Teclas e botões são remapeáveis em **Teclas e botões › Operações**; mouse e eixos de mira permanecem disponíveis. Botões padrão copiam os bindings do J1, sem alterar o duelo. A tela Controles tem uma página do modo e as dicas vêm de ControlHints. Na pausa do treino é possível reiniciar com outro personagem (Corsária, Lince, Coldre ou Guardião) e outro poder; toda troca reinicia, sem mudar recurso compartilhado ou campanha.

## Arsenal nas Operações

Dano é o do BoltData vezes a escala da arma; calor por tiro é o da tabela vezes o `vigor_multiplier` do BlasterData. Rajadas e saque vêm do mesmo BlasterData do duelo e da História.

| Arma | Classe | Uso | Dano | Tiros | Intervalo | Calor por tiro |
| --- | --- | --- | --- | --- | --- | --- |
| Pistola | Curta | uma mão | 10 | 1 | 0,16 s | 20 |
| Revólver pesado | Curta | uma mão | 24 | 1 | 0,55 s | 36 |
| Carabina | Média | duas mãos | 12 | 2 | 0,36 s | 15,4 |
| Rifle | Longa | duas mãos | 12 | 3 | 0,42 s | 15 |
| Rifle de precisão | Longa | duas mãos | 44 | 1 | 1,1 s | 64 |

| Treino | Calor | Intervalo | Dispersão | Tempo de troca |
| --- | --- | --- | --- | --- |
| Treinado | × 1 | × 1 | 0° | × 1 |
| Familiar | × 1,15 | × 1,1 | 2° | × 1,2 |
| Sem treino | × 1,35 | × 1,25 | 5° | × 1,5 |

Dispersão segue um padrão fixo por tiro, sem sorteio, para a reexecução continuar determinística.

| Personagem | Curta | Média | Longa | Por quê |
| --- | --- | --- | --- | --- |
| Guardião | Familiar | Familiar | Sem treino | fundamentos, prefere a lâmina |
| Sombra | Familiar | Familiar | Sem treino | pressão de perto |
| Bastião | Sem treino | Treinado | Familiar | mãos pesadas, arma firme |
| Vespa | Familiar | Sem treino | Sem treino | duas lâminas, velocidade |
| Espelho | Familiar | Sem treino | Familiar | paciente, precisa |
| Haste | Sem treino | Familiar | Treinado | luta à distância |
| Brasa | Familiar | Familiar | Sem treino | resposta curta |
| Forja | Sem treino | Treinado | Familiar | peso e carga |
| Garça | Treinado | Sem treino | Sem treino | acrobata, arma leve |
| Ceifador | Familiar | Sem treino | Sem treino | lâmina dupla |
| Eco | Treinado | Familiar | Familiar | truques |
| Corsária | Treinado | Familiar | Familiar | versátil |
| Lince | Treinado | Familiar | Familiar | versátil |
| Soberano | Sem treino | Sem treino | Sem treino | desdenha armas |
| Ancião | Sem treino | Sem treino | Sem treino | só a lâmina |
| Predestinado | Familiar | Familiar | Familiar | talento geral |

Vespa, Brasa, Haste e Ceifador usam as duas mãos na lâmina: para eles, todo blaster é de troca. A Corsária e o Lince começam com a própria arma e podem escolher outra.

## Tiro e calor

Armas usam `BlasterData` e `BoltData`. O conjunto do modo define escala de dano, cadência e calor; não modifica as armas do duelo.

| Conjunto | Dano | Velocidade / alcance | Cadência | Calor por tiro |
| --- | --- | --- | --- | --- |
| Pistola (Corsária e Coldre) | 10 (4 × 2,5) | 900 / 1.100 u | 0,16 s | 20 |
| Emissor (Lince) | 10 (4 × 2,5) | 900 / 1.100 u | 0,16 s | 20 |
| Rifle de dorso (conjunto explícito da futura Saga) | 15 por tiro (6 × 2,5), rajada de 3 | 650 / 1.500 u | 0,12 s entre tiros; 0,42 s entre rajadas | 37,5 (30 × 1,25) |
| Personagem só de lâmina | corte 10 | alcance 88 u | ciclo 0,40 s | sem calor |

Capacidade de calor 100, resfriamento 30/s após 0,25 s sem tiro. Atingir 100 trava a arma por **ao menos 1 s e até chegar a 40**, com resfriamento imediato durante a trava. Soltar e reapertar não limpa a trava. Guarda, esquiva, preparação do poder e tranco impedem tiro. Pool cheio ou saída dentro da parede recusa sem cobrar calor/cadência; não sobrescreve disparos. Sem munição, recarga manual, itens ou dano de contato.

Disparos são varridos contra paredes, caixas, corpos e prisioneiros; só acertam o primeiro obstáculo. Não há fogo amigo: disparos do jogador, dos aliados e devolvidos não ferem aliados, prisioneiros nem barreiras implantadas, e atravessam essas barreiras; inimigos não se acertam. Prisioneiro na cela não sofre dano de ninguém. Áreas e explosões seguem a mesma regra e param em paredes. O dano de um disparo devolvido continua o do projétil original. Guarda frontal cobre 140° e gasta o Vigor do BoltData; Vigor 100, regeneração 25/s após 0,6 s. Janela de parry/recarga vem do CombatConfig (0,20 / 0,40 s); perfeito nos primeiros 0,08 s aumenta velocidade a 125%, mas a direção continua sendo **a mira do jogador**. Não há mira automática no emissor. Todos os personagens com lâmina podem desviar. Guarda reduz movimento a 60% e exclui tiro.

## Esquiva e poderes

Esquiva: novo toque, duração 0,26 s, velocidade 720 u/s e recarga 0,90 s desde a ativação. Direção do movimento, ou da mira se parado, travada durante o dash. Colide com paredes, caixas e corpos. Invulnerável com idade de **3 a 11 ticks**; precisão de **3 a 8 ticks**, intervalos de fim exclusivos 12 e 9. Disparo que cruza a precisão zera a recarga uma vez por esquiva. Outra passagem invulnerável não restitui recarga. O projétil continua voando e não pode ferir o jogador até ser devolvido; não há devolução automática. Preparação e cauda são vulneráveis; dano não cancela o trajeto. Recarga zerada só permite outro dash depois de acabar o atual.

Até três poderes, os do conjunto do personagem no duelo, cada um em sua tecla, sem acorde ou barra de Fluxo. Um lançamento por vez, com recargas independentes. Preparação vem de PowerData, movimento a 60% e sem tiro; esquiva cancela a preparação e mantém a recarga gasta. Dano que causa tranco também interrompe a preparação. O efeito só começa quando a preparação termina. Paredes/caixas bloqueiam os poderes direcionais.

| Poder | Adaptação | Recarga |
| --- | --- | --- |
| Repulsão | cone de 100°, alcance 320 u, dano 6, tranco 0,40 s e impulso de 950 u/s por 0,16 s, limitados pela colisão | 6 s |
| Puxão | alvo mais próximo no cone de 60°, alcance 320 u, dano 4, tranco 0,45 s e aproximação a 330 u/s por 0,24 s | 7 s |
| Barreira | absorve até 95 de dano de disparos por 1,5 s, excedente fere; sem proteção contra corpo a corpo | 8 s |
| Arremesso | lança destroços na mira: projétil de 16 de dano e 700 u de alcance, sem calor | 7 s |
| Cura | recupera 28 de vida em 2 s; dano recebido interrompe | 14 s |
| Absorção | por 1,5 s, disparos que chegam somem sem dano e cada um adianta 1 s das outras recargas; sem proteção contra corpo a corpo e explosões | 10 s |
| Raio | canal de 1 s: 2,2 de dano a cada 0,1 s e tranco no alvo mais próximo do cone de 40°, alcance 480 u; mira acompanha, esquiva e tranco cortam | 9 s |
| Estrangular | canal de 1,8 s: prende o alvo mais próximo do cone de 60°, alcance 240 u, 3 de dano a cada 0,3 s | 10 s |
| Congelar | prende o alvo mais próximo do cone de 60° por 1,1 s, alcance 340 u | 9 s |
| Ira | por 5 s, dano causado × 1,2 e recebido × 0,85 | 18 s |
| Tempestade | por 5 s, a cada 1 s cai um raio no inimigo mais próximo, até 640 u: 5 de dano em 96 u de raio, sem atravessar paredes; não fere aliados | 20 s |

Nome, ícone, alcance, dano, preparação, tranco, potência e duração reutilizam os PowerData do duelo quando aplicáveis, e Ira usa os multiplicadores do FlowConfig. Um único catálogo liga cada PowerData à sua forma no plano superior; ângulos, duração dos impulsos e recargas são dados da adaptação. Sem mortes cinematográficas ou membros cortados no plano superior.

## Inimigos e cobertura

Arquétipos próprios em `data/blaster_ops/enemies/` estendem os da Infiltração, com percepção e controlador por intenção. Dano revela só a origem do tiro e provoca investigação/alerta; não há visão através das paredes. No treino, os guardas começam alertados para praticar os padrões.

| Arquétipo | Vida / velocidade | Ataque | Preparação antes de cada ataque |
| --- | --- | --- | --- |
| Soldado | 24 / 110 u/s | um tiro, dano 7, recarga 1,1 s | 0,20 s, ponto na boca da arma |
| Atirador | 18 / parado | tiro de dano 14, velocidade 1.100 u/s, recarga 1,8 s | 0,65 s, linha de mira travada |
| Pesado | 48 / 70 u/s | três tiros de dano 7, pausa 0,12 s entre preparações, recarga 1,5 s | 0,12 s por tiro; armadura frontal de 120° recebe 35% do dano |
| Investidor | 28 / 200 u/s | corpo a corpo, alcance 48 u, dano 12, recarga 0,8 s | 0,25 s, arco curto travado; guarda gasta 14 de Vigor, parry causa tranco |

Versão 1.1, arquétipos originais em `data/blaster_ops/enemies/`, cada um com um papel que muda como se luta, não só os números:

| Arquétipo | Vida / velocidade | Papel | Como lidar |
| --- | --- | --- | --- |
| Guarda de campo / Field warden | 40 / 85 u/s | Campo que reduz à metade o dano de disparos e cortes em aliados a até 170 u; atira pouco | Derrubar primeiro; poderes atravessam o campo |
| Sapador / Sapper | 14 / 230 u/s | Corre até o alvo, arma 0,6 s com o círculo de explosão à vista e detona: 28 de dano em 120 u, também nas barreiras. Morto, explode onde estiver | Abater de longe ou sair do círculo; a esquiva invulnerável atravessa |
| Reparador / Repairer | 26 / 110 u/s | Mantém distância, recua a menos de 260 u e repara 3 de vida por segundo em aliados a até 200 u; nunca o chefe | Caçar com disparos ou poderes |
| Passo de Ferro / Ironstride | 280 / 55 u/s | Andador bípede original, grande e de giro lento (50°/s). Canhão com 0,9 s de linha de mira travada: projétil de 24 de dano e explosão de 18 em 110 u. De perto, pisão de 16 em 96 u. Frente com 35% do dano; sem abate silencioso | Flanquear, ficar fora da linha, devolver o projétil no tempo |

As explosões e áreas seguem a regra de facções: as inimigas não ferem inimigos, quebram caixas e barreiras e param em paredes.

Mira trava durante a preparação de cada ataque. Perder intenção de ataque cancela a preparação; um tiro preparado só sai com linha livre e alvo ainda vivo. Corpo a corpo verifica alcance, setor e parede na resolução, e pode ser evitado saindo do arco. Armadura não depende de cor: placa/contorno frontal e faísca de impacto mostram a redução.

Caixas destrutíveis ocupam tiles marcados, têm 30 de vida e três estados visuais (íntegra, amassada até 20, rachada até 10); com zero viram destroço baixo passável. Paredes e caixas sem marca continuam indestrutíveis. Disparo que destrói a caixa se encerra nela; o próximo pode atravessar. Navegação e percepção passam a usar a abertura no próximo tick, inclusive após restaurar snapshot. O mapa original e seus recursos nunca são alterados. Sem reaparecimento automático nesta etapa; reiniciar restaura corpos, caixas, tiros, calor e recargas.
