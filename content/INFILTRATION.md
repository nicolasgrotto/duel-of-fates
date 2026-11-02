# Infiltração

Seis operações independentes, disponíveis desde o início em Jogar, com **resgate de prisioneiros como foco**: toda missão tem ao menos um prisioneiro para libertar e levar vivo à saída, pensando na união das fases numa História. A primeira também ensina o modo e é repetível. Nenhuma concede moeda, atributos ou cosméticos nesta etapa. Poderes do Fluxo ficam desligados: a ação de interação é exclusiva, preservando a leitura de guarda, abate e cobertura. O duelo não muda.

Duração-alvo de uma primeira jogada cuidadosa: **3 a 6 minutos**. O percurso mínimo andando, sem esperar patrulha, é medido em teste. Mapas têm de 66×36 a 96×64 tiles, com alas ligadas por passagens estreitas, e início e extração são distantes. A dica de objetivo segue o caminho real, não a linha reta, e aponta para o objetivo pendente mais próximo.

Painel como objetivo tem função: onde a missão marca `panels_unlock_prisoners`, ele trava as celas, e o prisioneiro só pode ser recrutado depois de todos os painéis desativados. Nas demais missões o painel é só o alarme opcional. O marcador do prisioneiro travado fica vermelho e com um X, e perto dele a dica pede os painéis. Prisioneiros recrutados seguem em fila a 215 u/s, abaixo dos 240 u/s da caminhada do jogador: cada um segue o anterior, e o primeiro segue o jogador. Cada missão tem um **mínimo de prisioneiros**: ela falha quando os vivos ficam abaixo dele, e sair com todos dá o bônus **Todos resgatados**. Prisioneiros têm 60 de vida.

Inimigos veem prisioneiros recrutados como veem o jogador, ganham alerta e atiram neles, preferindo o alvo mais próximo; atiradores e drones preferem o prisioneiro. Prisioneiro ainda na cela não é alvo, e quem já alcançou a saída fica a salvo. Tudo continua por intenção e sem cura.

## Inimigos

Disparos próprios do modo, sem alterar o disparo do duelo. Comum: 9 de dano e 12 de Vigor na guarda.

| Inimigo | Papel | Vida | Como lidar |
| --- | --- | --- | --- |
| Soldado | Patrulha e chama alarme | 20 | Abate por trás ou combate |
| Sentinela | Fixo, cone giratório | 16 | Passar na janela do giro |
| Pesado | Rajada de três, 8 de dano cada | 36 | Guarda e aproximação |
| Atirador | Fixo, alcance de 680 u em cone estreito, 22 de dano, com linha de mira visível | 14 | Sair da linha ou devolver o disparo |
| Drone | Rápido e sem arma, 12 de dano de perto e 16 de Vigor na guarda | 12 | Um golpe e meio; parry devolve dano |
| Escudeiro | Escudo frontal anula corte e disparo de frente; gira 150°/s | 30 | Contornar, ou abate por trás |
| Andador blindado | Corpo grande, canhão duplo de 16, frente reduz o dano a 25%, gira 60°/s, sem abate silencioso | 160 | Atacar por trás ou evitar |

Escudeiro, atirador, drone e andador não correm até o painel; soldados e pesados chamam o alarme.

| Missão | Mapa e foco | Objetivos obrigatórios | Guardas | Bônus de tempo |
| --- | --- | --- | --- | --- |
| Primeiro acesso | Galpões em duas alas; aprender a libertar | Libertar o prisioneiro e sair (mínimo 1 de 1) | 5 + 1 reforço | 180 s |
| Rede silenciosa | Três níveis; painéis destravam a cela | Desativar três painéis, libertar informantes e sair (mínimo 1 de 2) | 11 + 2 reforços | 360 s |
| Arquivo frio | Quatro arquivos com estantes; informação leva ao preso | Copiar dois terminais, libertar arquivistas e sair (mínimo 1 de 2) | 12 + 2 reforços | 390 s |
| Caminho de volta | Três níveis, ida e volta com escolta | Libertar prisioneiros e sair (mínimo 1 de 2) | 12 + 2 reforços | 480 s |
| Bloco de celas | Corredor central e oito blocos; só resgate | Libertar prisioneiros e sair (mínimo 2 de 4) | 12 + 2 reforços | 480 s |
| Coração da base | Complexo de três níveis; todos os verbos | Desativar três painéis, copiar o terminal, libertar prisioneiros e sair (mínimo 2 de 3) | 16 + 3 reforços | 660 s |

