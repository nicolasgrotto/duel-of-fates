# Combate de naves

Cinco operações independentes e repetíveis em Jogar › Modos especiais › Combate de naves. Todas estão disponíveis desde o início e podem ser concluídas com a nave base. O conjunto explícito de nave e melhorias pertence à tentativa; não altera recursos compartilhados nem outros modos.

| Missão | Objetivo | Composição | Tempo de referência |
| --- | --- | --- | --- |
| Corredor aberto | Eliminar duas ondas | Três caças em cunha, depois dois interceptadores; detritos laterais | 60 s |
| Rastro de cinza | Eliminar lançadores e escolta | Lançadores de mísseis, canhoneira de leque e caças; passagem entre detritos | 75 s |
| Última escolta | Eliminar ondas mantendo a capital aliada viva | Capital com gerador, motor e duas torres; caças e canhoneira miram o casco aliado | 90 s |
| Cortar a rede | Destruir gerador, motor e casco da capital inimiga | Capital modular, duas torres opcionais, caças e canhoneira de proteção | 90 s |
| Ferro de maré | Destruir o chefe | Três fases e três pontos de ataque em sequência; mísseis e leques | 105 s |

O limite de cada missão é 180 s de simulação; briefing, pausa e resultado não contam. Uma onda entra após o atraso fixo do dado e só avança quando seus membros obrigatórios foram abatidos. Slots e formações são pré-alocados. Acesso ocupado adia a entrada; ninguém surge sobre outra nave ou detrito. Não há sorteio de inimigo nem recompensa por abate. Posições, offsets e ordem de entrada vêm de recursos.

Caças mantêm formação até a aproximação e depois circulam o alvo; interceptadores perseguem; canhoneiras mantêm distância e abrem três disparos; lançadores e torres são fixos e giram antes de preparar o tiro. Toda IA só produz intenção. Capitais aliadas e inimigas usam as mesmas regras. Torres deixam de disparar quando destruídas; destruir gerador remove o escudo do casco e sua regeneração; destruir motor reduz o giro do casco para 45%. Seções têm vida e colisão próprias; dano numa seção não destrói automaticamente as demais. Detritos são sólidos e bloqueiam tiros, sem dano de contato ou morte instantânea.

Mísseis têm corpo sólido, raio 6 u, vida 2, velocidade inicial de 300 u/s e giro de até 65°/s; alvo fixado no disparo. Não readquirem outro alvo ao perdê-lo. Primárias hostis podem interceptá-los pelo percurso varrido; alvo dentro da janela invulnerável do impulso consome o míssil sem dano. A secundária da Trama dispara um míssil por toque, com 20 de dano, 500 u/s, giro de 100°/s e recarga de 3,5 s; não exige munição. Armas de leque reservam o grupo inteiro de projéteis antes de disparar; pool cheio não apaga tiros nem cobra recarga. Cada projétil conserva os dados da arma que o criou, mesmo após troca de fase.

Quando a intenção não informa alvo, a secundária do jogador fixa o objetivo ativo indicado no HUD; a IA informa seu alvo pela intenção. Isso permite guiar o míssil até o núcleo aberto do chefe em vez de escolher automaticamente o casco central fechado. Ainda é necessário disparar na direção adequada e respeitar a janela de abertura.

## Ferro de maré

Casco agregado 240. Na fase 1, abre o núcleo lateral superior de 80 de vida e usa leque lento de três tiros. A 67% de casco agregado, entra uma única vez na fase 2: núcleo inferior de 80 e lançamentos de mísseis. A 34%, fase 3: o núcleo central restante fica exposto e o leque passa a cinco tiros. Dano real nos núcleos laterais também reduz o casco agregado, sem duplicar dano; o núcleo central só aceita dano na fase 3. Não há cura ou ressurreição na transição. Limiar cruzado por um acerto é processado em ordem, uma vez por fase.

Cada fase tem ciclo fixo de abertura: preparação de 0,6 s, janela de 2 s e fechamento até completar 3,2 s. Contorno partido e texto mostram fechado/aberto; linha/leque progressivo antecede disparos perigosos. Disparar contra proteção consome o tiro sem dano. O chefe nunca fica vulnerável por animação ou efeito sonoro. Os números, armas, limiares e índices de núcleo são recursos.

## Resultado e progressão

Morte do jogador, capital aliada destruída ou tempo esgotado têm prioridade sobre vitória no mesmo tick. Vitória exige todas as ondas obrigatórias e seções exigidas; o chefe exige casco agregado zero. O resultado é selado uma vez e congela o núcleo. Guarda missão, motivo, ticks, casco restante, objetivo, fases e avaliação: três marcas com casco ≥75% e tempo dentro da referência; duas com uma dessas condições; uma no restante das vitórias; zero na derrota.

Primeira vitória em cada missão concede um ponto, cinco no total. Arma, Escudo e Velocidade têm dois níveis de custo 1, configurados em recurso: Arma acrescenta 2 de dano e reduz o intervalo em 0,02 s por nível; Escudo acrescenta 20 de capacidade e 3/s de regeneração; Velocidade acrescenta 35 u/s e 60 u/s². Redistribuição gratuita zera os níveis, sem apagar conclusões. Repetir pode melhorar tempo e avaliação, nunca duplica pontos. Saves antigos começam vazios e mantêm seus outros modos.

O modo pode ser iniciado por fluxo externo com `SpaceMissionData` e `SpaceLoadout` explícitos. O resultado é entregue como objeto e sinal, inclusive na derrota; uma tentativa externa não escreve progresso local nem presume tela seguinte. Voltar na pausa de uma tentativa externa emite `exit_requested`, para o dono do fluxo decidir a saída. Isso prepara a Saga sem implementá-la nesta tarefa.
