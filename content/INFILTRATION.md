# Infiltração

**Operações (task 17):** a Infiltração integra Jogar › Modos especiais › Operações, com rótulo de objetivo Infiltração e controles compartilhados com Incursão. Esquiva faz ruído; poderes têm recarga tripla, fazem ruído ao sair e alertam quem vê o jogador. Não ferem prisioneiros, mas mortes inimigas contam contra Sem abates. Blaster depende do personagem/conjunto explícito; todos podem jogar só de lâmina. Esta decisão substitui as restrições históricas de poderes e aparência abaixo. Ver GAME_DESIGN, "Operações: Infiltração e Incursão".

Seis operações independentes, disponíveis desde o início em Jogar › Modos especiais › Operações, com **resgate de prisioneiros como foco**: toda missão tem ao menos um prisioneiro para libertar e levar vivo à saída, pensando na união das fases numa História. A primeira também ensina o modo e é repetível. Nenhuma concede moeda, atributos ou cosméticos nesta etapa. Repulsão, Puxão e Barreira usam o núcleo comum, com recarga tripla; interação tem ação própria. O duelo não muda.

Duração-alvo de uma primeira jogada cuidadosa: **3 a 6 minutos**. O percurso mínimo andando, sem esperar patrulha, é medido em teste. Mapas têm de 66×36 a 96×64 tiles, com alas ligadas por passagens estreitas, e início e extração são distantes. A dica de objetivo segue o caminho real, não a linha reta, e aponta para o objetivo pendente mais próximo.

Painel como objetivo tem função: onde a missão marca `panels_unlock_prisoners`, ele trava as celas, e o prisioneiro só pode ser recrutado depois de todos os painéis desativados. Nas demais missões o painel é só o alarme opcional. O marcador do prisioneiro travado fica vermelho e com um X, e perto dele a dica pede os painéis. Prisioneiros recrutados seguem em fila a 215 u/s, abaixo dos 240 u/s da caminhada do jogador: cada um segue o anterior, e o primeiro segue o jogador. Cada missão tem um **mínimo de prisioneiros**: ela falha quando os vivos ficam abaixo dele, e sair com todos dá o bônus **Todos resgatados**. Prisioneiros têm 60 de vida.

Inimigos veem prisioneiros recrutados como veem o jogador, ganham alerta e atiram neles, preferindo o alvo mais próximo; atiradores e drones preferem o prisioneiro. Prisioneiro ainda na cela não é alvo, e quem já alcançou a saída fica a salvo. Tudo continua por intenção e sem cura.

## Inimigos

Disparos próprios do modo, sem alterar o disparo do duelo. Comum: 7 de dano e 11 de Vigor na guarda (antes 4 e 4).

| Inimigo | Papel | Vida | Como lidar |
| --- | --- | --- | --- |
| Soldado | Patrulha e chama alarme | 20 | Abate por trás ou combate |
| Sentinela | Fixo, cone giratório | 16 | Passar na janela do giro |
| Pesado | Rajada de três, 6 de dano cada | 36 | Guarda e aproximação |
| Atirador | Fixo, alcance de 680 u em cone estreito, 18 de dano, com linha de mira visível | 14 | Sair da linha ou devolver o disparo |
| Drone | Rápido e sem arma, 8 de dano de perto e 14 de Vigor na guarda | 12 | Um golpe e meio; parry devolve dano |
| Escudeiro | Escudo frontal anula corte e disparo de frente; gira 120°/s | 30 | Contornar, ou abate por trás |
| Andador blindado | Corpo grande, canhão duplo de 12, frente reduz o dano a 25%, gira 60°/s, sem abate silencioso | 160 | Atacar por trás ou evitar |

Escudeiro, atirador, drone e andador não correm até o painel; soldados e pesados chamam o alarme.

| Missão | Mapa e foco | Objetivos obrigatórios | Guardas | Bônus de tempo |
| --- | --- | --- | --- | --- |
| Primeiro acesso | Galpões em duas alas; aprender a libertar | Libertar o prisioneiro e sair (mínimo 1 de 1) | 5 + 1 reforço | 180 s |
| Rede silenciosa | Três níveis; painéis destravam a cela | Desativar três painéis, libertar informantes e sair (mínimo 1 de 2) | 11 + 2 reforços | 360 s |
| Arquivo frio | Quatro arquivos com estantes; informação leva ao preso | Copiar dois terminais, libertar arquivistas e sair (mínimo 1 de 2) | 12 + 2 reforços | 390 s |
| Caminho de volta | Três níveis, ida e volta com escolta | Libertar prisioneiros e sair (mínimo 1 de 2) | 12 + 2 reforços | 480 s |
| Bloco de celas | Corredor central e oito blocos; só resgate | Libertar prisioneiros e sair (mínimo 2 de 4) | 12 + 2 reforços | 480 s |
| Coração da base | Complexo de três níveis; todos os verbos | Desativar três painéis, copiar o terminal, libertar prisioneiros e sair (mínimo 2 de 3) | 16 + 3 reforços | 660 s |

## Controles e personagem

Os controles são compartilhados e remapeáveis em Operações: mover **WASD** ou setas, correr **Shift** (alterna), furtivo **C** (alterna), esquivar **Espaço**, interagir **E**, corte/abate **F**, poderes **1/2/3** (R também o primeiro), trocar arma **X**, atacar **botão esquerdo/V** (dispara com blaster; corta sem ele), guarda **botão direito/Q**. O controle conserva os botões do duelo, com interação em A/Cruz e corrida no stick esquerdo pressionado.

A linha **Personagem** do menu escolhe entre personagens e trajes liberados, e a escolha fica salva. Preserva silhueta vista de cima, cores do traje e cor e tipo da lâmina; possuir blaster muda a primária para tiro. Vida, alcance da lâmina e regras de resgate são iguais para todos. Conjunto explícito pode fornecer protagonista e arma da História sem alterar sua campanha. Peças opcionais de traje (como capuz) não mudam a silhueta vista de cima.

## Regras

Todos os mapas permitem contornar ou enfrentar os guardas. Abater patrulhas nunca é obrigatório. Cada missão oferece os bônus independentes **Sem alarme**, **Sem abates** (qualquer inimigo neutralizado conta, inclusive por disparo devolvido), **Dentro do tempo** (limite inclusivo) e **Todos resgatados**. A abordagem do resultado é **Furtivo** se nenhum painel ativou na tentativa; caso contrário **Direto**, mesmo após desligar a sirene.

Interação usa a ação de interagir, até 80 u e com linha livre. Um toque interage com um único objeto: painel próximo tem prioridade, depois terminal, depois prisioneiro. Terminal copia imediatamente; prisioneiro recrutado segue as intenções de seu controlador pela grade a 215 u/s, parando a 56 u do jogador. Não teleporta, não atravessa paredes e não precisa permanecer junto ao jogador após alcançar a extração. É possível voltar para buscá-lo. Não luta nem recebe dano da lâmina do jogador; disparos de qualquer lado podem atingi-lo, e a IA também mira nele, tornando a posição da escolta uma responsabilidade legível.

Extração é uma área de raio 96 u, marcada desde o início. Vencer exige todos os painéis/terminais obrigatórios, o mínimo de prisioneiros na área, todo prisioneiro recrutado e vivo já dentro dela e o jogador na área. A derrota por jogador abatido ou por prisioneiros abaixo do mínimo tem prioridade sobre extração no mesmo tick. Ao terminar, sucesso ou derrota, o resultado é selado, o mundo segue vivo ao fundo sem ferir o jogador e o encerramento mostra Missão concluída ou Missão falhou com o motivo, por cerca de 2,5 s ou até confirmar, antes da tela de resultado. O relógio conta todos os ticks da missão, inclusive o último, e exclui briefing, pausa e resultado. Um resultado congela a simulação e é selado uma vez. Reiniciar cria estado novo.

O save registra conclusão, menor tempo em ticks e união dos bônus obtidos em vitórias; repetir mais devagar pode melhorar bônus sem piorar o tempo. Derrotas não escrevem progresso. Saves antigos começam com o registro vazio. Retry abre a mesma missão; Próxima abre o briefing seguinte, e a última retorna à lista.
