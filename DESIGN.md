# DESIGN — Briefing do jogo

Este é o briefing do projeto. Ele define a **intenção**: o que o jogo deve fazer o jogador sentir e o que nunca deve parecer. Todo agente consulta este arquivo antes de criar qualquer coisa nova.

## Hierarquia dos documentos

Quando dois documentos discordarem, vale o que estiver mais acima:

```
DESIGN.md                    intenção e sensação (este arquivo)
  ↓
design/ART_DIRECTION.md      identidade visual
  ↓
design/VFX.md                efeitos
design/UI_UX.md              interface
design/AUDIO.md              som e música
  ↓
GAME_DESIGN.md               regras de gameplay
  ↓
content/                     personagens, poderes, história, arenas
  ↓
ARCHITECTURE.md              organização do projeto
  ↓
código
```

Se uma decisão importante ainda não estiver definida, **proponha e documente antes de implementar**.

---

## Conceito

Um duelo de lâminas de energia em visão lateral, cinematográfico e intenso. Dois combatentes, uma arena enorme, nenhum elemento sobrando. As trocas de golpes são rápidas, acrobáticas e coreografadas, como nos duelos de sabre da trilogia prequel: lâminas que se encontram o tempo todo, saltos, giros, empurrões de energia, rostos próximos numa disputa de lâminas. Mesmo na velocidade, cada golpe tem peso, cada defesa tem som e luz, e cada erro custa caro.

Frase-guia: **"rápido como uma coreografia, decisivo como um duelo."**

## Pilares

1. **Velocidade com leitura**: as trocas são rápidas e fluidas, mas todo golpe tem uma antecipação visível. O jogador perde por ler mal, nunca por não conseguir ver.
2. **Peso**: golpes com preparação, impacto e recuperação. Nada é instantâneo, nada é flutuante.
3. **Ritmo de duelo**: explosões curtas de ação (sequências, choques, parries) separadas por momentos de distância, estudo e aproximação. Ritmo de duelo, não de briga.
4. **Leitura do oponente**: o jogador entende o que o outro vai fazer pela silhueta, pela postura e pelo brilho da lâmina.
5. **Clareza visual**: cenário escuro, contraste forte e a luz das lâminas como protagonista da cena.

## Sensação desejada

- Duelo de cinema: coreografado, veloz, elegante e perigoso.
- O choque de lâminas faz sentir o impacto (clarão, faíscas, tremor curto, som elétrico).
- Acrobacia com propósito: pulos, giros e mergulhos servem para atravessar, reposicionar e surpreender, não para enfeitar.
- Ambiente grande e silencioso, com os combatentes pequenos diante dele.
- Momentos-assinatura: o parry perfeito que faz o mundo perder a cor enquanto só as lâminas brilham; a disputa de lâminas cara a cara; o K.O. em câmera lenta com a lâmina do derrotado se apagando.

## Público

- Jogadores de jogos de luta 2D e de ação que gostam de timing e leitura.
- Fãs de duelos de lâmina cinematográficos.
- Portfólio: demonstração de engenharia de jogos, arte e documentação claras.

## O coração do combate

O triângulo **ataque > empurrão > guarda/parry > ataque**.

- O ataque vence o empurrão (o empurrão é lento).
- O empurrão vence a guarda e o parry (atravessa os dois).
- A guarda e o parry vencem o ataque.

O **parry é a mecânica-assinatura**: o ataque forte se apara por reação; o rápido, só por leitura. Assim o duelo premia ler o oponente, e não esperar por ele. Quem só espera leva rápidos e empurrões e perde Vigor bloqueando.

O **Vigor** é o único recurso de defesa e ataque físico. Esgotá-lo é uma escolha arriscada e legível: exaustão, guarda quebrada, ferimentos.

## Consequência, não punição permanente

Exaustão e ferimento abrem uma janela de risco dentro do round e sempre têm recuperação (fim do round, Cura concluída). O jogador é estimulado a gerenciar o Vigor.

## Finalização estilizada

O K.O. por lâmina pode separar um braço ou uma perna e, no K.O. que decide a partida, às vezes a cabeça. Sempre **estilizado**: sem sangue, sem órgãos, corte cauterizado com brasa, cabeça sem rosto visível. Uma opção desliga as finalizações.

## Personagens

- Personagens são **dados**: nome, cores, lâmina, atributos, golpes, habilidade, poderes e IA ficam em recursos (ver ARCHITECTURE.md).
- Cada personagem muda **a forma de jogar**, não só os números.
- **Teste da silhueta**: pintado de preto, cada personagem continua reconhecível pela roupa, postura, cabeça e forma de segurar a lâmina.
- **Lâminas sem moral**: cada personagem tem uma cor de lâmina própria, e nenhuma cor significa "bom" ou "mau". O vermelho não é a cor do vilão.
- Os modelos são **detalhados**: rostos, tecidos, armaduras, cabos, cabelo e materiais com acabamento de jogo comercial, sem perder a leitura da silhueta. Elenco completo em [content/CHARACTERS.md](content/CHARACTERS.md).

## Arenas

Arenas são cenário: não interferem na lógica dos personagens nem matam ninguém. Profundidade com várias camadas, pouco detalhe perto da área de luta e a regra de ouro: **a lâmina é a principal fonte de luz**. Lista em [content/ARENAS.md](content/ARENAS.md).

## Identidade

- **Nome**: **Duel of Fates**.
- **O Fluxo**: a energia dos poderes. Dois caminhos: **Aurora** (luz) e **Eclipse** (sombra). As cores da energia vêm do nível de Fluxo de quem lança, nunca da lâmina.
- **Letterbox**: barras pretas que entram na intro de cada round, no K.O. e, curtas, no parry perfeito. É o motivo cinematográfico do jogo.
- **Ignição**: no começo de cada round, as lâminas acendem da base à ponta com o som de ignição.
- **Glossário** (PT-BR / EN): Vigor / Stamina; Aparar / Parry; Contra-ataque / Counterattack; Golpe de resposta / Response strike; Esquiva de precisão / Precision evade; Disputa de lâminas / Blade lock; Fluxo / Flow; Exaustão / Exhaustion; Ferimento / Wound; Aurora / Aurora; Eclipse / Eclipse; Soberano / Sovereign; Predestinado / Foretold; Ancião / Elder.

## Interface, efeitos e som

- UI minimalista, cinematográfica e pouco intrusiva: [design/UI_UX.md](design/UI_UX.md).
- Efeitos curtos e fortes, só em momentos importantes: [design/VFX.md](design/VFX.md).
- Som com peso e música original tensa, que reage à luta: [design/AUDIO.md](design/AUDIO.md).

## Animação

Toda ação tem 4 fases: **preparação → movimento → impacto → recuperação**. Ver [design/ART_DIRECTION.md](design/ART_DIRECTION.md).

## O que NÃO fazer

- Visual genérico de jogo mobile (botões coloridos, brilho em tudo, ícones cartunescos).
- Excesso de elementos na tela durante o duelo; HUD grande ou que cubra a área de luta.
- Movimentos instantâneos, robóticos ou sem antecipação; velocidade que impede a leitura.
- Efeitos longos que escondam o combate.
- Câmera lenta fora dos momentos-assinatura (K.O. e parry perfeito).
- Sangue, órgãos ou gore.
- Logos, nomes, personagens, músicas ou sons oficiais de Star Wars.
- Um estilo novo criado por um agente sem atualizar estes documentos.

Mecânicas descartadas de propósito (complexidade sem ganho):

- barra de postura separada do Vigor, barra de super;
- defesa alta/baixa, agachar e mixups de altura;
- juggles e combos no ar (um golpe aéreo por pulo);
- dano por chip no bloqueio de lâmina;
- números de dano na tela;
- XP, moeda, loja, grind ou melhoria de atributos fora do protagonista da História (decisão do autor: na História existe o Arsenal, com créditos que só vêm da primeira vitória em cada encontro e só compram blasters, sem como farmar; nas Operações existem os Suprimentos da versão 1.1, que valem só dentro de uma tentativa e nunca são salvos);
- perigos de arena que matam (ring-out).

Fora do escopo inicial, possíveis no futuro: modo online, torneio, editor de personagens.

## Além do duelo (decisão do autor, fase 9)

**Operações (task 17):** Infiltração e Incursão compartilham uma tela, um moveset e o menu Jogar › Modos especiais › Operações. O objetivo da missão muda as regras, nunca as teclas. Infiltração privilegia resgate sem ser visto; Incursão privilegia combate. Todo personagem pode concluir operações apenas com lâmina, guarda, esquiva e poderes. A versão 1.1 substitui a antiga regra de um poder só e acrescenta o conjunto opcional do Arsenal (ver Atualização 1.1); lâmina continua sendo o padrão de quem não possui blaster.

**Incursões (task 18):** sete missões independentes, sem progressão de atributos entre tentativas: Arena, Assalto, Defesa, Resistência, Escolta, Rival e Chefe. Defesa de objetivo é uma missão de Operações, substituindo seu descarte como modo separado. Resgatar é opcional fora da Escolta; aliados libertados ajudam por intenções de tiro. Recompensas avulsas são cosméticas únicas; o fluxo externo recebe resultado e decide eventuais créditos da História, sem o núcleo alterar campanha.

O duelo continua sendo o coração do jogo. O autor aprovou modos que saem do formato "dois combatentes, vista lateral", desde que cada um mantenha a mesma identidade (pixel art na grade do mundo, paleta e UI do tema, lâminas com peso, leitura antes de velocidade, sem gore, sem nada da franquia):

- **Operações**: missões em mapas **top-down 2D** dentro de bases. Objetivo Infiltração privilegia resgate, furtividade e alarmes; Incursão privilegia combate. Lâmina, blaster quando equipado, esquiva e poderes usam os mesmos controles. A lâmina **desvia e devolve disparos** (guarda e parry). Uma tela própria, não o duelo.
- **Combate de naves**: missões **top-down 2D** de pilotagem (esquadrões, mísseis, naves capitais, chefe), com melhorias de arma, escudo e velocidade entre missões. Essas melhorias valem só dentro desse modo; fora dele continua valendo a regra de não ter progressão fora do protagonista da História.
- **Caçada a chefes**: duelos contra chefes únicos com fases, padrões próprios e condições especiais de vitória, no motor do duelo.
- **Família Versáteis**: lâmina numa mão e blaster na outra ou integrado ao cabo. Disparos existem também no duelo, como projéteis que a guarda e o parry desviam.
- **Incursões** (task 18, no menu único de Operações): combate em visão superior nas bases da Infiltração, com mira independente, calor para quem tem blaster, esquiva e um poder equipado. Várias missões, incluindo defesa de objetivo; leitura de preparação, paredes e cobertura vem antes da velocidade. A task 16 entregou o treino; a 17 unificou o núcleo e os controles.

Descartados por enquanto: Exploração e Relíquias (plataforma e puzzles) e Defesa de Objetivo. A Sobrevivência já existe no menu Jogar.
Cada modo novo documenta suas regras em GAME_DESIGN e sua tela em design/UI_UX **antes** de ser implementado.

## Atualização 1.1 das Operações (decisão do autor)

Objetivo: fazer da Incursão uma operação de combate completa, sem comprometer o que já funciona. Vale para Infiltração e Incursão, na mesma tela e no mesmo menu. Regras em [GAME_DESIGN.md](GAME_DESIGN.md#atualização-11-das-operações), números e conteúdo em [content/BLASTER_OPS.md](content/BLASTER_OPS.md).

- **Sem fogo amigo.** Ataques do jogador e dos aliados nunca ferem aliados, prisioneiros, protegidos nem barreiras próprias. A regra vive na resolução de dano, por facção, e cobre disparos, devoluções, explosões e áreas. Inimigos continuam ameaçando aliados, e as condições de falha continuam valendo.
- **Vários poderes.** Cada personagem leva os poderes do seu conjunto do duelo, com nomes, ícones e valores vindos dos mesmos dados. Não há um segundo sistema de habilidades: o plano superior só tem suas próprias formas de aplicar o efeito.
- **Conjunto do Arsenal.** A linha de arma do painel de personagem oferece os cinco blasters do Arsenal, de graça e só neste modo, sem posse nem progressão. Lâmina é o padrão. Cada personagem tem seu treino com cada classe de arma: ninguém fica igualmente bom em tudo, e o Arsenal não substitui a identidade do personagem.
- **Duas formas de usar.** Arma de uma mão com lâmina de uma mão fica junto da lâmina. Arma de duas mãos, ou qualquer arma para quem luta com duas lâminas ou lâmina em haste, exige trocar entre o modo de disparo e o modo de lâmina. O sistema é modular para servir à futura História completa.
- **Suprimentos.** Ganhos e gastos dentro de uma tentativa, em terminais que só existem em algumas missões longas: cura, barreiras, resfriamento, reforços aliados. Nunca viram moeda, nada é salvo entre tentativas, e toda missão pode ser vencida sem comprar nada.
- **Aliados e barreiras.** Aliados têm papéis próprios e agem sozinhos; o jogador não dá ordens. Barreiras podem ser implantadas além da Defesa e bloqueiam fogo inimigo.
- **Duração.** Incursão comum: 5 a 8 minutos numa primeira jogada cuidadosa. Chefe ou grande operação: 8 a 10. A duração vem de objetivos, ambientes e encontros diferentes, nunca de inflar vida de inimigo ou repetir ondas. IDs, recompensas e progresso continuam os mesmos.
- **Teclas perto do WASD e nada em Ctrl.** Correr e andar furtivo alternam com um toque; o navegador reserva combinações com Ctrl, como Ctrl+W.
- **Web é plataforma de validação.** O limite de unidades, disparos e busca de caminho é medido antes de crescer, porque a build Web roda em uma só thread.

## Propriedade intelectual

- O jogo é inspirado em Star Wars e declara isso no README, sem se apresentar como produto oficial.
- O código usa termos neutros (`Fighter`, `Blade`, `flow`), nunca nomes da franquia.
- Nomes, títulos e textos ficam nas tabelas de tradução, para que a identidade possa mudar sem tocar na lógica.
- Todo asset tem origem e licença registradas em [ASSETS.md](ASSETS.md).
