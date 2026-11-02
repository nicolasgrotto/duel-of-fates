# Infiltração

Cinco operações independentes, disponíveis desde o início em Jogar. A primeira também ensina o modo e é repetível. Nenhuma concede moeda, atributos ou cosméticos nesta etapa. Poderes do Fluxo ficam desligados: a ação de interação é exclusiva, preservando a leitura de guarda, abate e cobertura. O duelo não muda.

Duração-alvo de uma primeira jogada cuidadosa: **3 a 6 minutos**. O percurso mínimo andando, sem esperar patrulha, é medido em teste. Mapas têm de 66×36 a 96×64 tiles, com alas ligadas por passagens estreitas, e início e extração são distantes. A dica de objetivo segue o caminho real, não a linha reta, e aponta para o objetivo pendente mais próximo.

| Missão | Mapa e verbo principal | Objetivos obrigatórios | Guardas | Percurso mínimo andando | Bônus de tempo |
| --- | --- | --- | --- | --- | --- |
| Primeiro acesso | Galpões em duas alas; aprender a interagir | Desativar o painel e sair | 5 + 1 reforço | 37 s | 150 s |
| Rede silenciosa | Três níveis de alas; sabotar | Desativar três painéis e sair | 11 + 2 reforços | 100 s | 300 s |
| Arquivo frio | Quatro arquivos verticais com estantes; obter informação | Copiar dois terminais e sair | 12 + 2 reforços | 81 s | 330 s |
| Caminho de volta | Três níveis, ida e volta com escolta; resgatar | Recrutar o prisioneiro, levá-lo vivo à saída e extrair | 12 + 2 reforços | 133 s | 420 s |
| Coração da base | Complexo de três níveis; todos os verbos | Desativar três painéis, copiar o terminal, recrutar o prisioneiro e extrair | 16 + 3 reforços | 127 s | 480 s |

## Controles e personagem

O teclado do modo é próprio e fixo, porque a mão direita fica no mouse: mover **WASD** ou setas, correr **Shift**, furtivo **C**, interagir **E**, abate silencioso **F**, golpe **botão esquerdo** ou **Espaço**, guarda **botão direito** ou **Q**. Não acompanha o remapeamento do duelo; o controle continua copiando os botões do duelo.

A linha **Personagem** do menu escolhe entre personagens e trajes liberados, e a escolha fica salva. Muda só a aparência: silhueta vista de cima, cores do traje e cor e tipo da lâmina. Atributos, alcance e regras da simulação são iguais para todos. Peças opcionais de traje (como capuz) não mudam a silhueta vista de cima.

## Regras

Todos os mapas permitem contornar ou enfrentar os guardas. Abater patrulhas nunca é obrigatório. Cada missão oferece os bônus independentes **Sem alarme**, **Sem abates** (qualquer inimigo neutralizado conta, inclusive por disparo devolvido) e **Dentro do tempo** (limite inclusivo). A abordagem do resultado é **Furtivo** se nenhum painel ativou na tentativa; caso contrário **Direto**, mesmo após desligar a sirene.

Interação usa a ação de interagir, até 80 u e com linha livre. Um toque interage com um único objeto: painel próximo tem prioridade, depois terminal, depois prisioneiro. Terminal copia imediatamente; prisioneiro recrutado segue as intenções de seu controlador pela grade a 180 u/s, parando a 56 u do jogador. Não teleporta, não atravessa paredes e não precisa permanecer junto ao jogador após alcançar a extração. É possível voltar para buscá-lo. Não luta nem recebe dano da lâmina do jogador; disparos de qualquer lado podem atingi-lo (40 de vida). A IA continua mirando apenas o jogador, tornando a posição da escolta uma responsabilidade legível.

Extração é uma área de raio 96 u, marcada desde o início. Vencer exige todos os painéis/terminais obrigatórios e todos os prisioneiros recrutados e vivos dentro dela, além do jogador na área. A derrota por jogador ou prisioneiro abatido tem prioridade sobre extração no mesmo tick. O relógio conta todos os ticks da missão, inclusive o último, e exclui briefing, pausa e resultado. Um resultado congela a simulação e é selado uma vez. Reiniciar cria estado novo.

O save registra conclusão, menor tempo em ticks e união dos bônus obtidos em vitórias; repetir mais devagar pode melhorar bônus sem piorar o tempo. Derrotas não escrevem progresso. Saves antigos começam com o registro vazio. Retry abre a mesma missão; Próxima abre o briefing seguinte, e a última retorna à lista.
