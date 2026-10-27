# Infiltração

Quatro operações independentes, disponíveis desde o início em Jogar. O treino curto também é uma missão repetível. Nenhuma concede moeda, atributos ou cosméticos nesta etapa. Poderes do Fluxo ficam desligados: a ação Poder é exclusivamente interação, preservando a leitura de guarda, abate e cobertura. O duelo não muda.

| Missão | Mapa e verbo principal | Objetivos obrigatórios | Bônus de tempo |
| --- | --- | --- | --- |
| Primeiro acesso | Pátio curto com cobertura e uma sentinela; aprender a interagir | Desativar o painel e sair | 45 s |
| Rede silenciosa | Duas alas separadas por corredor de serviço; sabotar | Desativar dois painéis e sair | 90 s |
| Arquivo frio | Arquivo dividido por estantes e pátio de vigilância; obter informação | Copiar o terminal e sair | 90 s |
| Caminho de volta | Detenção com corredor de escolta e cobertura; resgatar | Recrutar o prisioneiro, levá-lo vivo à saída e extrair | 120 s |

Todos os mapas permitem contornar ou enfrentar os guardas. Abater patrulhas nunca é obrigatório. Cada missão oferece os bônus independentes **Sem alarme**, **Sem abates** (qualquer inimigo neutralizado conta, inclusive por disparo devolvido) e **Dentro do tempo** (limite inclusivo). A abordagem do resultado é **Furtivo** se nenhum painel ativou na tentativa; caso contrário **Direto**, mesmo após desligar a sirene.

Interação usa a ação remapeada de Poder, até 80 u e com linha livre. Um toque interage com um único objeto: painel próximo tem prioridade, depois terminal, depois prisioneiro. Terminal copia imediatamente; prisioneiro recrutado segue as intenções de seu controlador pela grade a 180 u/s, parando a 56 u do jogador. Não teleporta, não atravessa paredes e não precisa permanecer junto ao jogador após alcançar a extração. É possível voltar para buscá-lo. Não luta nem recebe dano da lâmina do jogador; disparos de qualquer lado podem atingi-lo (40 de vida). A IA continua mirando apenas o jogador, tornando a posição da escolta uma responsabilidade legível.

Extração é uma área de raio 96 u, marcada desde o início. Vencer exige todos os painéis/terminais obrigatórios e todos os prisioneiros recrutados e vivos dentro dela, além do jogador na área. A derrota por jogador ou prisioneiro abatido tem prioridade sobre extração no mesmo tick. O relógio conta todos os ticks da missão, inclusive o último, e exclui briefing, pausa e resultado. Um resultado congela a simulação e é selado uma vez. Reiniciar cria estado novo.

O save registra conclusão, menor tempo em ticks e união dos bônus obtidos em vitórias; repetir mais devagar pode melhorar bônus sem piorar o tempo. Derrotas não escrevem progresso. Saves antigos começam com o registro vazio. Retry abre a mesma missão; Próxima abre o briefing seguinte, e a última retorna à lista.
