# GAME DESIGN — Duel of Fates

Fonte de verdade sobre **o que** o jogo é. Personagens, poderes, história e arenas têm documentos próprios em `content/`. Para **como** o projeto é organizado, veja [ARCHITECTURE.md](ARCHITECTURE.md).

## Convenções de números

- **Tempo** em segundos. A simulação roda em passo fixo de 60 Hz (1 quadro = 0,0167 s).
- **Distância** em **u** (unidade de mundo). Referência: o lutador padrão tem **150 u de altura** e 46 u de largura de corpo; a arena padrão tem cerca de 1200 u de largura útil. O que importa é a proporção: se o mundo for escalado, escale todos os valores juntos.
- Todos os números deste documento são **valores iniciais de calibração**, já testados como ponto de partida de uma boa sensação. Ajustes entram nos recursos de configuração e, quando mudarem a regra, aqui.

---

## 1. Visão

Duelo 1 contra 1 em visão lateral. O jogador controla um lutador numa arena e enfrenta um adversário controlado por IA ou por outro jogador local. O foco é o combate de lâminas: ataque, defesa, esquiva, posicionamento e timing, com os poderes do Fluxo como camada opcional.

## 2. Partida

- **Melhor de 3 rounds** nos duelos comuns; modos podem usar 1 round (História, Sobrevivência, Desafios).
- **Intro do round**: letterbox entra, as lâminas acendem (ignição), aparece "ROUND 1", "ROUND 2" ou "ROUND FINAL", controles travados. Vida, Vigor, Fluxo e posições voltam ao início (distância inicial de 440 u entre os lutadores).
- **Introdução dos lutadores**: ligada por padrão nas Opções. No primeiro round de Duelar, Arcade, História, Sobrevivência e 2 Jogadores, cada um prepara sua arma e assenta na guarda; só depois aparece o título. INTRO total de 3,6 s, com o último segundo reservado ao título. Confirmar ou tocar um ataque de qualquer jogador adianta os dois ao título, sem atacar nem pular o título. Demais rounds e opção desligada usam a intro normal de 1,6 s. Treino, Galeria, Tutorial, Treinos guiados, Desafios e Desafio de parry não exibem as entradas individuais.
- **K.O.**: vida zero. Controles param, câmera lenta, "K.O.", queda. Depois, o próximo round ou o resultado.
- **Replay do golpe final**: depois do K.O. que decide a partida, os últimos ~3,5 s são reexibidos em câmera lenta (45%), com letterbox e o rótulo REPLAY. Confirmar pula. Pode ser desligado nas Opções.
- **Resultado**: VITÓRIA ou DERROTA, vencedor, duração, estatísticas (golpes acertados, dano causado, defesas, parries, parries perfeitos, quebras de guarda, empurrões, maior sequência). Opções: Revanche ou Menu principal.

## 3. Ações e controles

O jogo conhece **ações**, nunca teclas. Limite de **6 botões de combate** (rápido, forte, guarda, esquiva, habilidade, poder) mais direções e pulo; variedade vem de direção + botão, não de botões novos.

| Ação | Teclado (padrão) | Gamepad |
| --- | --- | --- |
| Mover | `A` / `D` ou setas | stick esquerdo / direcional |
| Pular (duas vezes no ar) | `W`, seta para cima ou `Espaço` | A / Cruz |
| Ataque rápido | `J` | X / Quadrado |
| Ataque forte | `K` | Y / Triângulo |
| Guarda (segurar) / parry (tocar) | `L` | LB ou LT |
| Empurrão | `L` + `J` | LB + X |
| Esquiva (no ar: dash aéreo) | `Shift` | B / Círculo |
| Esquiva de precisão | `S` ou seta para baixo | baixo |
| Habilidade (com direção: técnicas) | `I` | RB |
| Poder (com direção: outros espaços; segurar canaliza) | `U` | RT |
| Quarto poder (só quem tem) | `U` + `I` juntos | RT + RB |
| Pausar | `Esc` ou `P` | Start |

- Teclas e botões são remapeáveis; presets alternativos (ex.: setas + `Z X C V`).
- **Dois jogadores no mesmo teclado**: J1 com `W A S D`, `F G H` (rápido, forte, guarda), `T` (habilidade), `R` (poder), `Shift` esquerdo; J2 com setas, `J K L`, `I`, `O`, `Shift` direito ou teclado numérico. Cada jogador também pode usar um gamepad.
- **Buffer de entrada**: uma ação pedida enquanto o lutador não pode agir fica guardada por 0,15 s e sai no primeiro quadro possível. A última substitui a anterior.
- **Prioridade** de ações no mesmo quadro: esquiva > empurrão > ataque forte > ataque rápido > guarda.

## 4. Movimento

- No chão, o lutador sempre vira de frente para o oponente; no ar, só vira ao pousar.
- Andar para trás é mais lento (70–75% da velocidade para a frente). Velocidade de caminhada base 260 u/s.
- Aceleração e desaceleração dão peso (≈2200 e 2800 u/s² no chão). No ar, controle reduzido (≈900 u/s²).
- **Gravidade** 2400 u/s², queda máxima 1400 u/s. **Pulo** com velocidade inicial base de 820 u/s.
- **Pulo duplo**: um segundo pulo no ar com 70% da velocidade do primeiro (Vespa 90%). Zera ao tocar o chão. Não rearma o golpe aéreo.
- **Dash aéreo**: a esquiva no ar vira um dash curto horizontal, uma vez por salto, custa 18 de Vigor (Vespa 8), segue a direção (sem direção, para a frente), dá uma pequena elevação e atravessa o corpo do oponente. Sem invulnerabilidade.
- **Pulo na parede** (traço da Garça e do Ancião): encostado na parede no ar, pular lança para o outro lado. Um por vez; precisa tocar o chão ou a outra parede para repetir.
- Corpos não se atravessam: ao encostar, se empurram. Ninguém sai dos limites da arena.

## 5. Estados do lutador

| Estado | Descrição |
| --- | --- |
| `IDLE` | Parado em guarda |
| `WALKING` | Andando |
| `JUMPING` | No ar |
| `ATTACKING` | Ataque rápido (inclui sequência) |
| `HEAVY_ATTACK` | Ataque forte |
| `BLOCKING` | Guarda |
| `DODGING` | Esquiva, dash aéreo ou esquiva de precisão |
| `CASTING` | Preparando um poder |
| `CHANNELING` | Mantendo um poder canalizado |
| `BLADE_LOCK` | Na disputa de lâminas |
| `HIT` | Atingido (hitstun) |
| `STAGGERED` | Desequilibrado sem dano (parry perfeito num forte, empurrão, desfecho de disputa) |
| `STUNNED` | Atordoado (guarda quebrada) |
| `DEAD` | Derrotado |

Ataques de chão, guarda e esquiva só começam no chão a partir de `IDLE` ou `WALKING`. O empurrão também pode sair de dentro da guarda.

## 6. Anatomia de um golpe

Cada golpe é um dado com: startup (preparação), active (hitbox ligada), recovery (vulnerável), dano, custo de Vigor, knockback, hitstun, blockstun, custo de Vigor para quem bloqueia, empurrão no bloqueio, avanço (lunge), hitbox (alcance, faixa vertical), se pode ser interrompido, armadura, elegibilidade para ferir e qual membro uma finalização separa.

- Fases: startup → active → recovery. A hitbox só existe no active.
- No início do active, o atacante dá um passo à frente (lunge).
- Cada golpe acerta no máximo uma vez.
- A recovery é a janela de punição: quem erra fica vulnerável.
- **Hitbox**: área à frente do atacante, com alcance e faixa de altura por golpe. **Hurtbox**: o corpo. **Colisão de lâmina**: área própria, usada para o choque entre lâminas. As três são separadas.

**Valores de referência (lutador padrão)**

| Golpe | Startup | Active | Recovery | Dano | Vigor | Alcance |
| --- | --- | --- | --- | --- | --- | --- |
| Rápido | 0,10 | 0,10 | 0,20 | 10 | 8 | 100 u |
| Forte | 0,32 | 0,12 | 0,42 | 24 | 24 | 115 u |
| Contra-ataque | 0,06 | 0,10 | 0,30 | 16 | 0 | 110 u |
| Empurrão | 0,20 | 0,08 | 0,30 | 0 | 10 | 50 u |
| Aéreo | — | — | — | 12 | — | — |

Bloquear um rápido custa ~8 de Vigor ao defensor; um forte, ~30.

- **Alcance** é medido a partir da borda da frente do corpo (o lutador padrão tem 46 u de largura). O empurrão, com 50 u, só alcança quem está quase encostado.
- **Colisão de lâmina** (usada só no choque) é mais curta que o alcance do golpe: 60 u nos rápidos, 70 u nos fortes, 55 a 65 u nos aéreos. Duas lâminas se chocam quando a distância entre os corpos é menor ou igual à soma das duas.
- **Valores iniciais por golpe** (lutador padrão; os exatos de cada personagem estão nos recursos): hitstun do rápido 0,35 s, do forte 0,5 s, do contra-ataque 0,45 s; blockstun do rápido 0,24 s e do forte 0,3 s; knockback do rápido 40 u, do forte 120 u, do forte de avanço 140 u. Forte de avanço: startup 0,36 s, recovery 0,52 s, 30 de Vigor, avanço de 110 u. Aéreo rápido: startup 0,08 s, 12 de dano; aéreo forte: startup 0,16 s, 14 de dano.

## 7. Combate

### Sequência de rápidos

- Rápido apertado de novo encadeia o próximo rápido da sequência do personagem (2 a 5 golpes). Cada passo tem um arco diferente do anterior: sequências nunca repetem o mesmo movimento.
- A rota só abre se o golpe anterior **acertou, foi bloqueado, foi aparado ou chocou com outro rápido**. No golpe no vazio, não encadeia.
- Interrompem a sequência: receber um golpe, o parry perfeito num forte e o choque com um forte.

### Ataque forte, forte de avanço e aéreo

- **Forte**: caro, lento, muito dano e knockback. Pode ser aparado por reação.
- **Forte de avanço** (frente + forte): lunge maior, mais custo e mais recovery.
- **Golpe aéreo**: rápido ou forte no ar, um por pulo, mantendo a trajetória. Não altera a velocidade vertical do alvo (sem juggle).

### Guarda

- Segurar guarda mantém `BLOCKING`. Só defende golpes de frente.
- Golpe bloqueado: sem dano, o defensor perde Vigor, é empurrado um pouco e fica preso por um instante (blockstun).
- Na guarda, a regeneração de Vigor é mais lenta (40%).
- **Quebra de guarda**: sem Vigor para o bloqueio, o Vigor zera e o defensor fica `STUNNED` por 1,2 a 1,4 s (pelo personagem), tempo para o atacante reagir e conectar um forte.
- **Reserva de Defesa**: cada ponto de Defesa acima de 4 dá 4 de reserva (Defesa 7 = 12; Ancião 8 = 16; Soberano 9 = 20; `CombatConfig.defense_reserve_per_point`). Se ainda resta Vigor e o que falta para o bloqueio cabe na reserva, a guarda segura esse último bloqueio e o Vigor zera (exaustão); com o Vigor já em zero, o próximo bloqueio quebra. Defesa 4 ou menos não tem reserva.

### Parry (aparar)

Mesmo botão da guarda: **tocar** abre a janela de parry; **segurar** continua sendo guarda.

| Tempo desde o toque | Resultado se um golpe chegar pela frente |
| --- | --- |
| 0 a 0,08 s | **Parry perfeito** |
| 0,08 a 0,20 s | **Parry** |
| depois | guarda normal |

- **Parry**: nenhum dano nem custo para o defensor, que fica livre na hora. O atacante perde o Vigor que o bloqueio daquele golpe custaria, o golpe deixa de acertar e segue para a recovery, sem desequilíbrio. Num rápido, a sequência do atacante continua; num forte, sobra a recovery longa para o defensor punir.
- **Parry perfeito**: o atacante perde o dobro de Vigor e o defensor recupera 15. Contra um **forte**, o atacante perde o golpe e fica `STAGGERED` por 0,5 s, o que garante um forte ou o contra-ataque. Contra um rápido, vale como parry em tudo (custo normal, sem desequilíbrio, sem os 15 de Vigor, evento `parry`): o parry perfeito, a câmera lenta e a dessaturação ficam reservados ao forte.
- **Parry falho**: se a janela acabar sem golpe, ela não abre de novo por 0,4 s (a guarda continua funcionando).
- O toque precisa ser novo. Um toque durante o blockstun abre a janela (aparar o próximo golpe de uma sequência).
- O empurrão não pode ser aparado.
- **Por que funciona**: o forte (startup ~0,32 s) pode ser aparado por reação; o rápido (0,10 s), só por leitura.

### Contra-ataque

Ataque rápido apertado enquanto o oponente está desequilibrado por um parry perfeito vira o **contra-ataque**: startup 0,06 s, sem custo de Vigor, mais dano que o rápido. A janela dura o desequilíbrio.

### Empurrão

- Guarda + rápido. Sai parado ou de dentro da guarda (fora do blockstun).
- Startup lento (0,20 s) e alcance curto: qualquer ataque mais rápido o vence, e ele não gera choque.
- Sem dano. Atravessa guarda e parry: o alvo é empurrado, perde 20 de Vigor e fica `STAGGERED` por 0,35 s, o que garante um rápido.

### Esquiva

- Dash rápido para a direção segurada; sem direção, para trás. Custa ~20 de Vigor, dura ~0,28 s, percorre ~170 u, invulnerável nos primeiros ~0,18 s, vulnerável no fim.
- O dash aéreo dura ~0,18 s e percorre ~190 u (valores iniciais).

### Esquiva com giro

Implementada na fase 7.5 (`DodgeKind.SPIN`, números em `CombatConfig`, grupo Dodge).

- **Frente + esquiva** no chão com o oponente a até ~60 u (borda a borda): em vez do dash, o lutador gira o corpo, atravessa o oponente e troca de lado, pousando já virado para ele.
- Mais arriscada que a esquiva comum: 28 de Vigor, duração 0,34 s, invulnerável só de 0,04 a 0,14 s, recovery final de 0,16 s vulnerável.
- Sem espaço atrás do oponente (parede), vira a esquiva comum para a frente.
- Longe do oponente, frente + esquiva continua sendo o dash comum.
- Quem é atravessado pode virar normalmente no quadro seguinte; não há ataque garantido pelas costas. Um golpe que já estava no active continua acertando só pela frente.
- O pouso fica a 8 u além do corpo do oponente; os corpos se atravessam só durante o deslocamento (0,18 s). A perna ferida encarece o giro como a esquiva (× 1,2).
- **IA**: contra um forte já na preparação e colada, gira para fora quando está encurralada (parede a até 140 u atrás); longe da parede, com 30% dessa chance (`spin_dodge_chance`: Fácil 3%, Normal 20%, Difícil 45%, Chefe 60%).

### Esquiva de precisão

- Baixo (separada da esquiva). No chão, **não custa Vigor**, recua muito pouco, fica invulnerável por apenas ~0,066 s e tem recovery de até 0,4 s.
- Se um golpe cruza a hurtbox nessa janela: **sucesso**, o golpe é consumido e o defensor fica livre na hora para punir. Sem contato, a recovery fica vulnerável.
- Cada uso exige um toque novo. Sucessos seguidos formam uma sequência visível: a primeira esquiva recua o tronco; as seguintes alternam inclinações diferentes (agachada baixa, recuo profundo, meio-corpo), nunca repetindo a pose da anterior.
- **Contra disparos** (decisão do autor): um disparo que chega na janela também é um **sucesso** (inclusive no último instante, com a pose e o rastro visíveis): o defensor fica livre na hora, a sequência continua e o disparo segue reto sem acertar. Contra uma rajada, cada disparo pede um novo toque no momento certo; errar o tempo leva o disparo normalmente.

### Choque de lâminas (clash)

- Quando as lâminas se encostam, pelo menos uma já está no active e a outra está no active ou nos últimos **4 ticks de preparação** (`CombatConfig.clash_window = 0,067 s`, arredondado a 60 Hz). **Forte contra forte** tem janela maior, 9 ticks (`CombatConfig.heavy_clash_window = 0,15 s`; decisão do autor, porque 4 ticks eram curtos demais para duas pessoas acertarem a disputa de propósito). Duas preparações sozinhas não chocam. A janela acomoda golpes já comprometidos que começaram poucos quadros separados, inclusive o boneco que espelha no tick seguinte; fora dela, a vantagem de velocidade continua valendo. Alcance de lâmina, altura, orientação e golpe ainda não consumido continuam obrigatórios. O choque tem prioridade sobre o hit: ninguém leva dano.
- **Rápido contra rápido**: faíscas, som e tremor; os golpes deixam de acertar e passam à recuperação, um empurrão curto (120 u) separa os dois, ninguém entra em recuo e a sequência continua. Isso também consome o golpe capturado no fim da preparação, sem ativo atrasado nem novos acertos do mesmo golpe.
- **Com um forte envolvido**: os dois ataques são cancelados, os dois são empurrados (280 u) e ficam 0,25 s em recuo (`HIT`, sem dano).
- **Forte contra forte** elegíveis iniciam a **disputa de lâminas**.
- **Choque entre técnicas de lâmina**: as duas são interrompidas num choque grande, os dois recuam 420 u, ficam desequilibrados por 0,4 s e perdem 12 de Vigor.

### Pressão de lâminas

Implementada na fase 7.5 (`BladePress`, números no grupo Blade press do `BladeLockConfig`). Uma disputa curta que nasce da troca de rápidos, para o choque de rápidos virar um evento de vez em quando, nunca por sorte.

- **Contador de contatos**: conta os contatos de lâmina seguidos entre os dois lutadores envolvendo rápidos: um choque rápido contra rápido ou um **parry de um rápido**. Zera depois de 0,6 s sem contato e com qualquer acerto, forte, técnica, esquiva, empurrão ou poder.
- **Entrada**: no **3º contato seguido**, com os corpos a até 90 u, abre a pressão (estado `BLADE_LOCK`, variante curta). Divide a recarga de 4 s com a disputa.
- **Parry no 3º contato**: quem aparou entra na pressão com **1 pressão de vantagem**. O parry continua premiando quem lê o golpe.
- **Durante**: as mesmas regras da disputa (aperto do rápido = pressão, teto de 15 por segundo, opção "Segurar para disputar"), mas mais curta: vence quem abrir **3 de vantagem**, tempo máximo de 1,5 s.
- **Vitória**: o perdedor leva 4 de dano, perde 20 de Vigor e fica `STAGGERED` por 0,3 s; os dois se separam 300 u. Empate: só separa.
- Eventos próprios (`blade_press_started`, `blade_press_ended`) para efeitos, som e câmera mais contidos que a disputa; as pressões usam o mesmo `blade_lock_pressed`.
- O bloqueio de um rápido não conta nem zera; o choque empurra os dois 120 u, então a terceira troca exige voltar a colar dentro de 0,6 s (ou aparar, que não separa). Os lutadores entram a 70 u um do outro (centro a centro).
- **IA**: pressiona como na disputa (mesma reação e ritmo por dificuldade). **Treino guiado** da disputa: depois das três disputas, vencer uma pressão contra o boneco que repete o tipo de ataque.

### Disputa de lâminas

O momento mais físico do duelo: rostos próximos, lâminas cruzadas num X, tremor e som crescente.

- **Entrada**: dois fortes comuns ou de avanço se chocam dentro da janela acima a até ~70 u de distância. Recarga de 4 s entre disputas.
- **Durante**: cada aperto de ataque rápido é uma pressão (no máximo 15 por segundo contam). Quem abrir **5 pressões de vantagem** vence. Tempo máximo de 3 s.
- **Vitória**: o perdedor leva 8 de dano e perde 35 de Vigor uma única vez, fica `STAGGERED` por 0,35 s; o vencedor tem 0,25 s de recovery. Os dois se separam 420 u. A recuperação e a separação impedem converter a disputa num forte garantido.
- **Empate** (tempo acabou com vantagem menor que 1): só separa. Se o tempo acabar com vantagem de 1 ou mais, quem lidera vence.
- O dano da derrota na disputa (8) é fixo, não escala com Lâmina, e pode causar o K.O. (finalização de braço).
- A disputa suspende ações, movimento, regeneração, efeitos de status e recargas dos participantes.
- **Acessibilidade**: a opção "Segurar para disputar" permite segurar o rápido; conta 6 pressões por segundo, abaixo do teto, para incluir quem não pode apertar repetidamente sem empatar com quem aperta.
- A IA só começa a pressionar depois de um tempo de reação (Fácil 0,6 s, Normal 0,45 s, Difícil e chefe 0,3 s).

### Desengajamento

Implementado na fase 7.5 (`BladeLockResolver.disengage`, golpe em `data/characters/common/disengage.tres`, tipo `DISENGAGE`, números no grupo Disengage do `BladeLockConfig`). A saída técnica da disputa e da pressão, contra quem só aperta rápido.

- **Ataque forte** durante a disputa ou a pressão, depois de 0,5 s dentro dela: o lutador gira o punho, solta a própria lâmina e corta por outro ângulo. Uma tentativa por disputa.
- Custa 20 de Vigor. A disputa termina sem vencedor; os corpos se afastam só 60 u.
- O corte: startup 0,10 s, active 0,10 s, recovery 0,30 s, 11 de dano, conta como rápido para guarda e parry, não encadeia sequência.
- O rival fica preso 0,08 s na soltura e depois está livre: pode bloquear, **aparar** (tocar guarda na hora) ou esquivar. Aparado, o desengajamento segue a regra do parry de um rápido; errado, a recovery é punível.
- A IA usa conforme a dificuldade, só quando está perdendo a contagem (`disengage_chance` a cada 0,1 s depois de meio segundo: Fácil 1%, Normal 12%, Difícil 50%, Chefe 60%).
- O desengajamento divide a recarga de 4 s com a disputa e a pressão e solta o evento `disengage`. Sem Vigor, a ação é recusada e a disputa continua. **Treino guiado** da disputa: o último passo pede um desengajamento.

### Avanço com corte

- A arrancada acontece na preparação (os 220 u do avanço em 0,2 s) e o ativo é só o corte, com o lutador plantado (`MoveData.dash_in_startup`). A hitbox continua existindo só no ativo; o alcance total (avanço + 100 u) e os tempos não mudam. Assim o que se vê (arrancada, depois corte) é o que acerta.

### Habilidades e traços: valores iniciais

Os personagens em [content/CHARACTERS.md](content/CHARACTERS.md) não fixavam números; estes são os valores iniciais da fase 4 (ajustados pela matriz de equilíbrio):

| Habilidade | Valores |
| --- | --- |
| Contraguarda (Guardião) | postura 0,35 s, recovery 0,4 s se nada vier, 10 de Vigor; atacante desequilibrado 0,3 s; resposta = contra-ataque |
| Ímpeto (Sombra, Sombra Desperta) | startup 0,2 s, avanço de 140 u, 20 de dano, 18 de Vigor, armadura contra 1 golpe (preparação e active) |
| Marreta (Bastião) | startup 0,55 s, 32 de dano, 30 de Vigor, armadura contra 2 golpes recebendo metade do dano, conta como forte |
| Zumbido (Vespa) | 240 u em 0,26 s, invulnerável por 0,2 s, atravessa, 16 de Vigor |
| Postura de Espera (Espelho) | postura 0,5 s, recovery 0,5 s, 20 de Vigor; efeito de parry perfeito e contra-ataque |
| Investida da Haste (Haste, Soberano) | substitui a Varredura (removida): lunge longo com a ponta, startup 0,30 s, avanço de 160 u, alcance 60 u além do forte, 18 de dano, conta como forte, o Ponto doce vale; finalização de perna |
| Brasa Viva (Brasa) | postura 0,4 s, recovery 0,45 s, 14 de Vigor; resposta com startup 0,08 s e 13 de dano (o bônus de punição se soma) |
| Forja (Forja) | startup 0,28 s; segurar prende o golpe; nível a cada 0,3 s até 3; +35% de dano por nível; nível 3 quebra a guarda |
| Voo da Garça (Garça) | salto de 300 u/s para a frente e 1050 u/s para cima, 14 de Vigor; permite os aéreos |
| Roda Dupla (Ceifador) | startup 0,15 s, active 0,36 s, 20 de dano, acerta na frente e atrás (atrás não pode ser bloqueado) |
| Passo-reflexo (Eco, Predestinado) | 60 u em 0,14 s, invulnerável o passo todo, para trás sem direção, 8 de Vigor |
| Salto (Ancião) | salto de 240 u/s e 820 u/s; na descida, mergulho automático de 18 de dano |

- **Ponto doce** (Haste, Soberano): a distância entre os corpos no acerto dividida pelo alcance do golpe; de 2/3 para cima, ×1,5; até 1/4, ×0,6.
- **Pulo na parede**: encostado (até 6 u da parede) no ar, pular lança para o outro lado a 380 u/s. Uma vez por parede até tocar o chão.
- **Mergulho** (forte no ar da Garça e do Ancião): no active, a velocidade vertical vira 900 u/s para baixo.
- **Habilidade** entra na prioridade de entrada logo depois do empurrão. Só no chão; Habilidade com direção e no ar dispara as técnicas (fase 5, content/POWERS.md).

### Disparos e desvio

Base da família Versáteis e dos inimigos da Infiltração (decisão do autor, task 06). Um **disparo** é um projétil curto e rápido, saído de um golpe que dispara (`MoveData.bolt`, dados em `BoltData`). A lâmina o desvia.

| Valor | Disparo padrão (`data/bolts/standard_bolt.tres`) |
| --- | --- |
| Velocidade | 900 u/s (atravessa 450 u em 0,5 s: dá para reagir de meia distância) |
| Alcance | 1.100 u |
| Dano | 4 |
| Tranco | 0,12 s, sem empurrão |
| Custo na guarda | 4 de Vigor |
| Saída | 100 u de altura (peito) e 30 u à frente do corpo |

- **Acerto** (regra revista pelo autor): dano e um **tranco** de 0,25 s em quem está parado, andando, na recovery ou no **startup** de um golpe: o disparo cancela o golpe que ainda não saiu, inclusive o avanço de um Avanço com corte. Na recovery, o tranco nunca encurta a punição: vale o maior entre o tranco e o que restava. Quem está no active, com armadura, em postura, lançando um poder, no ar ou esquivando leva o dano e continua o que fazia. Depois de um tranco, o alvo fica **0,6 s imune a novos trancos**, para rajadas causarem dano sem travar ninguém. Disparo mata, mas sem finalização cinematográfica.
- **Guarda de frente**: o disparo se desfaz na lâmina; o defensor perde 4 de Vigor, sem blockstun. Disparo não quebra a guarda: com o Vigor em zero, a guarda ainda segura e o defensor entra em exaustão. Guarda de costas não segura.
- **Parry** (janela do toque, 0,08 a 0,20 s): o disparo volta **pela mesma linha**, agora do defensor. A janela não fecha ao desviar, então um toque bem colocado devolve uma rajada inteira.
- **Parry perfeito** (0 a 0,08 s): o disparo volta **mirado no peito de quem atirou**, 25% mais rápido.
- Devolvido, o disparo acerta quem atirou com as mesmas regras (dano, tranco, guarda, parry): dá para devolver de volta.
- **Outras defesas**: a esquiva invulnerável atravessa; a de precisão na janela conta como sucesso e soma à sequência (seção Esquiva de precisão); a Barreira segura sem custo extra; o Arsenal intercepta como qualquer projétil; o Santuário absorve o dano normalmente. O Instinto Superior não evita disparos. Disparos não se chocam entre si nem com lâminas em ataque.
- Disparos não geram Fluxo, para a distância não virar fonte de medidor.
- **Rajada**: `BoltData.count` disparos com `interval` entre eles, a partir do primeiro tick ativo do golpe. Golpe que só dispara (`reach` 0) não tem hitbox de lâmina.

### Disparo Tático (família Versáteis)

Os disparos da família vêm de golpes comuns com `MoveData.bolt` e seguem todas as regras de "Disparos e desvio". O que muda por personagem é **onde** o disparo aparece:

| | Corsária | Lince |
| --- | --- | --- |
| Disparo (`BoltData`) | 950 u/s · 4 de dano · 4 de Vigor na guarda · saída 104 u (braço esticado) | 1.100 u/s · 3 de dano · 3 de Vigor · saída 92 u (cabo) |
| Na sequência | passo 2 corta **e** dispara no mesmo tick ativo | — |
| Técnica de frente | Rajada Desestabilizadora: 5 disparos e avanço com corte | Tiro de guarda: prep. 0,05 s, **sai da guarda** |
| Técnica de trás | Recuo com disparo: recua 110 u e dispara no início | Corte ascendente (sem disparo) |

- **Recuo com disparo**: o golpe tem impulso negativo (`lunge` −110), então o corpo recua durante o ativo enquanto o disparo sai para a frente. É o "recuo que atira" da família, sem gancho novo na esquiva.
- **Tiro de guarda** (`MoveData.from_guard`): com a guarda segura, Direção para frente + Habilidade dispara sem soltar a guarda antes. Bom contra avanços: o disparo cancela o avanço com corte ainda no startup, mas não um já no ativo.
- **Prioridade da regra**: nenhum disparo da família interrompe o ativo de um golpe ou um golpe com armadura; o startup desarmado pode ser cancelado, uma vez a cada 0,6 s. A distância força o rival a fechar, e o fechar é que expõe.
- **Técnicas de disparo comuns** (`MoveData.required_sidearm`): Rajada Desestabilizadora, Disparo duplo e Recuo com disparo exigem blaster; o editor de técnicas e a Galeria só as dão a quem tem um. A Rajada encadeia o avanço sozinha (`MoveData.follow_up_auto`). Nenhuma desequilibra além do tranco comum, com a mesma imunidade.

### Ser atingido

- Perde vida, recebe knockback na direção do golpe e entra em `HIT`. Se estava atacando, o ataque é cancelado.
- **Armadura** (alguns golpes de habilidade): durante o startup (e o active, quando indicado) o golpe aguenta N acertos; o lutador leva o dano (às vezes reduzido) mas não é interrompido. Armadura não protege contra parry, empurrão ou quebra de guarda.

## 8. Recursos

### Vida

Base ~100, ajustada pelo atributo Vida. Zero: `DEAD`.

### Vigor

- Base 100, regenera 25 por segundo depois de um atraso de 0,6 s sem gastar.
- Gasto por ataques, esquiva, dash aéreo, técnicas e defesa (bloquear custa Vigor ao defensor).
- Ação sem Vigor suficiente é **recusada**: a barra de Vigor pisca e toca um som seco. A ação sai do buffer.
- É o único recurso físico de defesa. Não existe barra de postura.

### Fluxo

Medidor dos poderes, separado do Vigor. Regras completas em [content/POWERS.md](content/POWERS.md).

## 9. Consequências

### Exaustão

- Gastar Vigor até **5%** ou menos causa exaustão (a regeneração não a inicia). Sai com pelo menos **30%** de Vigor e 1 s de duração.
- Golpes corpo a corpo elegíveis causam **× 1,1** de dano contra exaustos.
- Leitura: respiração mais funda e guarda pendendo; barra de Vigor em vermelho apagado pulsando.

### Ferimentos

- Um **forte comum** pode ferir o **braço**; um **forte de avanço**, a **perna**. Exige dano efetivo não letal contra um oponente exausto. Uma aplicação por lutador por round.
- **Braço ferido**: bloquear custa × 1,25.
- **Perna ferida**: dash e dash aéreo custam × 1,2 e o segundo pulo some (o primeiro pulo, o pulo na parede e a esquiva de precisão continuam).
- A **Cura** remove o ferimento só se completar sem ser interrompida. O fim do round também remove.

### Foco automático

Com o poder Foco ativo, um lutador **parado em guarda, sem nenhum comando**, esquiva sozinho de golpes de lâmina corpo a corpo por 30 de Fluxo cada, até o Foco acabar ou faltar Fluxo. Defesa manual válida tem prioridade e não custa Fluxo. Empurrões, poderes e projéteis não são elegíveis.

### Regra por modo

| Modo | Poderes | Exaustão, ferimento, disputa, finalizações | Foco automático |
| --- | --- | --- | --- |
| Duelar, 2 Jogadores, Treino, Arcade, Sobrevivência | opção (ligada por padrão) | sim | com Poderes |
| História | sempre | sim | sim |
| Caçada a chefes | sempre, kit fixo | sim | sim |
| Tutorial e Treinos guiados | não | sim | — |
| Desafios | cada desafio define | sim | cada desafio define |
| Desafio de parry | não | não | — |
| Galeria de poderes | sim | — | sim |

## 10. Finalizações

- Um K.O. por **golpe de lâmina corpo a corpo** separa um membro do derrotado.
- O golpe decide o membro: **perna** no 3º rápido, forte de avanço, Avanço com corte e Investida da Haste; **braço** nos demais (inclusive na disputa). A orientação decide o lado (pela frente, o membro da frente; pelas costas, o de trás).
- **Rápidos: onde a lâmina passou** (decisão do autor). Cada tipo de corte tem uma altura de passagem, medida dos pés de quem ataca (`ConsequenceConfig.cut_heights`: descendente alto, ascendente baixo, horizontal, estocada e giro no meio). A altura em relação aos pés da vítima decide a faixa: acima de `head_line` é a **cabeça**, abaixo de `leg_line` é a **perna**, entre as duas é o **braço** do lado atingido. No chão, o rápido descendente passa pela cabeça; contra uma vítima no ar, o mesmo corte pega mais baixo. Rápidos marcados com perna nos dados continuam levando a perna.
- **A cabeça só sai no K.O. que decide a partida** (último round; em modos de um round, qualquer K.O.), porque o derrotado não volta. Nos rounds anteriores, um corte na faixa da cabeça leva o braço. Não há mais sorteio de cabeça.
- No K.O. decisivo, golpes com finalização cinematográfica (tabela abaixo: forte, forte de avanço e técnicas) usam a cinemática; golpes fortes sem cinemática própria, como as habilidades, levam a cabeça (`ConsequenceConfig.head_on_deciding_heavy`).
- Apresentação (não muda o resultado): pelas costas sai o membro de trás.
- Golpe aéreo, lâmina arremessada, empurrão, poderes e dano periódico terminam num K.O. normal.
- **Execuções sorteadas** (decisão do autor): quando o golpe forte decide a partida, a execução é sorteada entre as da **família** do lutador, com a mesma semente da partida, então o replay repete a mesma. Cada família tem a sua execução marcante e mais quatro exclusivas. Poderes, técnicas e a exibição coreografada seguem com a sua fixa. Golpe forte aéreo não tem execução.
- **Finalizações cinematográficas** (fase 8, decisão do autor): só no K.O. que decide a partida e com a opção Finalizações ligada, quando o golpe ou o poder que mata tem uma cinemática própria. Ela substitui o corte de membro. Nos rounds anteriores, o K.O. corta o membro como antes, e o lutador volta no round seguinte com a parte robótica (apresentação).

| Fonte | Finalização | Quando |
| --- | --- | --- |
| Forte parado de quem usa lâmina simples ou haste (Guardião, Sombra, Sombra Desperta, Espelho, Soberano, Haste, Brasa, Eco, Garça, Ancião, Predestinado; não Corsária e Lince) | **duas lâminas**: dois cortes rápidos levam um antebraço cada; a lâmina da vítima cai no chão; quem corta estende a mão e puxa a lâmina caída pelo Fluxo até a mão livre, que acende; as duas lâminas se abrem dos dois lados do pescoço e se fecham em X; o corpo fica de pé um instante, cai de joelhos e tomba para a frente | o golpe mata e a vítima usa lâmina simples; contra lâmina dupla, bastão ou haste vira desarme e execução. K.O. mais longo (`ConsequenceConfig.long_cinematic_ko_time`) |
| Forte parado da **Corsária** | **execução cruzada** (decisão do autor): dois cortes rápidos levam os dois antebraços; a vítima cai de joelhos; a Corsária se afasta (~70 u), aponta o blaster para baixo, no peito da vítima ajoelhada, e dispara; o impacto abre um furo em brasa e a vítima tomba **para trás**; a Corsária apaga a lâmina e volta à guarda, sem giro (ajuste do autor) | o golpe mata |
| Forte parado do **Lince** | **sentença precisa** (decisão do autor): um corte diagonal atravessa a guarda; o Lince passa para o lado e atrás da vítima com um corte curto na lateral; a vítima se vira e o Lince aponta o emissor do cabo para ela e dispara à queima-roupa; furo em brasa, ela cai de joelhos e depois para a frente; o Lince apaga a lâmina e fica imóvel por um instante | o golpe mata |
| Forte de avanço da **Garça** | **giro**: a Garça contorna a vítima girando, com um corte baixo que a desequilibra, passa para trás dela, corta na horizontal na altura do pescoço, termina com a lâmina subindo e fica composta, de costas para o corpo que cai; ela nunca para de se mover | o golpe mata; quem corta é posto atrás da vítima, virado para ela (determinístico) |
| Forte de avanço (todos, salvo abaixo) | **desarme e execução**: o forte leva os dois antebraços, a lâmina da vítima cai e apaga, ela cai de joelhos e um corte horizontal leva a cabeça | o golpe mata |
| Forte parado de Bastião e Forja | **execução por cima**: o forte empurra a vítima, que perde o equilíbrio e cai de joelhos; quem corta ergue a lâmina acima da cabeça e desce um corte vertical; as metades caem para os lados | o golpe mata |
| Forte parado do Ceifador | **giro duplo**: o primeiro giro do bastão leva os dois antebraços, o segundo passa pelo pescoço; o corpo cai de joelhos e tomba | o golpe mata |
| Forte e forte de avanço da Vespa | **tesoura**: o mesmo desarme; as duas lâminas se fecham em X no pescoço | o golpe mata |
| Forte de avanço de Espelho, Haste e Soberano | **estocada**: a lâmina atravessa o peito e fica um instante, sai e a vítima cai de joelhos e tomba para a frente | o golpe mata |
| Avanço com corte | corte na cintura passando: quem corta para atrás da vítima | o acerto do corte mata |
| Corte Projetado | corte na cintura | a onda mata |
| Investida descendente, Corte ascendente | corte vertical, as metades caem para os lados | o golpe mata |
| Arremesso da lâmina | corte diagonal na parte de cima | a lâmina mata, na ida ou na volta |
| Raio | eletrocutado (esqueleto aparece) e corpo carbonizado | um pulso do Raio mata; dano de outra fonte não conta |
| Singularidade Devastadora | massa arremessa o corpo e encerra em queda cinematográfica BLAST, sem mutilação | só a massa final mata no K.O. decisivo; extrações não executam |
| Repulsão, Repulsão Suprema | explosão de brasa, o corpo é arremessado longe | a onda mata |
| Puxão | puxado e cortado ao meio | o Puxão acerta com a vida do alvo em até 12 (`PowerData.execute_below`): a execução é garantida |
| Estrangular | estalo de energia no pescoço e queda | o estrangulamento mata |

  O K.O. com cinemática dura mais `ConsequenceConfig.cinematic_ko_time` (1,6 s). No Avanço com corte, quem corta é posto 24 u atrás da vítima no instante da morte (determinístico). No giro, a Garça é posta atrás da vítima (`dash_through_clearance`) e virada para ela. Na execução, na tesoura, na estocada, nas duas lâminas, na execução por cima e no giro duplo, os dois param no instante da morte (sem o avanço do golpe nem o recuo da vítima) e quem corta fica pelo menos `ConsequenceConfig.execution_clearance` (16 u) à frente da vítima.
- Sempre estilizado: sem sangue, corte cauterizado em brasa, cabeça sem rosto visível. A opção Finalizações desliga o desenho sem mudar nenhum resultado; o replay mostra o mesmo corte.

## 11. Atributos

Seis atributos: **Vida, Vigor, Lâmina, Defesa, Agilidade, Fluxo**.

- Escala de **1 a 7** no elenco comum. Os secretos passam disso pelo **potencial**: Ancião até 8, Soberano até 9, Predestinado até 10.
- Nota 4 tem multiplicador 1; cada nota muda 8% (1 = 0,76; 7 = 1,24; 10 = 1,48).
- **Vida**: vida máxima. **Vigor**: máximo e regeneração. **Lâmina**: todos os danos de lâmina e um pequeno bônus na janela de parry perfeito. **Defesa**: custo da guarda, recuo no bloqueio e reserva antes da quebra (não reduz dano; custo e recuo são divididos pelo multiplicador; a reserva segura o último bloqueio, ver seção 7). **Agilidade**: caminhada, pulo, avanços e janela da esquiva de precisão. **Fluxo**: nível dos poderes.
- Os atributos do elenco são fixos. Só o protagonista da História distribui pontos.

## 12. Ritmo e balanceamento

- O derrotado recebe em média **6 a 9 golpes limpos** até o K.O. Rápido ~10, forte ~24, contra-ataque ~16, com ~100 de vida.
- Um round dura cerca de 15 s de ação.
- Quem só defende tem a guarda quebrada; quem só ataca é aparado e punido; quem só espera é empurrado.
- Ordem de aplicação de dano de lâmina: dano base → bônus de punição → carga → ponto doce → exaustão → Ira de quem ataca → Ira de quem defende → armadura.
- O balanceamento é medido com simulações IA contra IA sem gráficos (ver ARCHITECTURE.md): taxa de vitória por par de personagens, golpes até o K.O., duração do round.

## 13. Sensação de impacto

Valores que fazem parte da regra porque mudam o tempo do duelo:

| Evento | Hit stop |
| --- | --- |
| Rápido acerta | 0,04 s |
| Forte acerta | 0,08 s |
| Bloqueio | 0,03 s |
| Parry / parry perfeito | 0,07 / 0,10 s |
| Quebra de guarda, clash | 0,10 s |

- **Câmera lenta** só em dois momentos: K.O. (30% da velocidade por 0,8 s) e parry perfeito (50% por 0,25 s).
- Durante o hit stop, o atingido treme 2–3 u na horizontal.
- Efeitos visuais em [design/VFX.md](design/VFX.md).

## 14. Eventos de combate

A simulação emite eventos; efeitos, câmera, som, HUD, estatísticas e tutoriais reagem a eles: `attack_started`, `hit`, `block`, `guard_break`, `parry`, `perfect_parry`, `clash`, `technique_clash`, `blade_lock_started`, `blade_lock_pressed`, `blade_lock_ended`, `blade_press_started`, `blade_press_ended`, `disengage`, `shove`, `dodge`, `evade_success`, `response`, `action_rejected`, `exhaustion`, `exhaustion_recovered`, `wound`, `feint`, `armor_absorbed`, `power_started`, `power_active`, `power_hit`, `power_blocked`, `power_resisted`, `power_absorbed`, `projectile_*`, `bolt_hit`, `bolt_blocked`, `bolt_reflected`, `death`, `round_started`, `round_ended`.

## 15. IA

A IA controla o oponente pela mesma **intenção** do jogador. Ela só pede ações.

### Como pensa

- Pensa em intervalos (`reaction_time` da dificuldade, com variação aleatória de até +40%, nunca mais rápido que o mínimo). Entre pensamentos, segue o plano atual.
- A cada pensamento lê: distância entre os corpos, estado e fase do golpe do oponente, a própria vida, Vigor e Fluxo, e a própria recarga.
- Escolhe por prioridade (a ordem e os pesos vêm do perfil de cada personagem):
  1. **Defender**: se o oponente começa um golpe que alcança, guarda ou esquiva. Contra um forte no startup pode tentar o **parry**, calculando pela pose quando o golpe fica ativo.
  2. **Punir**: oponente em recovery, atingido, desequilibrado ou atordoado e no alcance: contra-ataca (forte se houver Vigor e o oponente estiver atordoado; contra-ataque depois de um parry perfeito).
  3. **Empurrar**: oponente na guarda e perto.
  4. **Recuperar**: com pouco Vigor, recua para uma distância segura.
  5. **Atacar**: no alcance e sem recarga, rápido ou forte conforme o perfil.
  6. **Guardar**: no alcance e sem poder atacar, segura a guarda por antecipação.
  7. **Posicionar**: fora do alcance, aproxima; perto demais para o perfil, recua ou espera.
- Truque Mental só quando o oponente está andando ou recuando com pouco Vigor (inverter a direção de quem está parado não muda nada). No Difícil e no Chefe, quem tem quarto poder não gasta medidor em outro poder se isso o deixar abaixo do custo do quarto, e lança o quarto primeiro quando ele está pronto (`AiDifficultyData.save_for_fourth`).
- Usa poderes e técnicas equipados: acompanha projéteis em voo, foge das marcas da Tempestade e da Telecinese, pula a Fratura, evita Raio contra Absorção, tenta quebrar Barreira com empurrão e pune a preparação de Cura e Foco.
- **Justiça**: a IA só vê o que o jogador vê (estado e fase do golpe), nunca o input. Não reage mais rápido que o `reaction_time` e não apara um rápido por reação.
- Usa um gerador aleatório com seed; nos testes a seed é fixa e o comportamento é reproduzível.

### Perfis

| Perfil | Comportamento |
| --- | --- |
| Agressivo | ataca muito, mais fortes, defende pouco, fica perto |
| Defensivo | guarda e esquiva muito, prefere punir, mantém distância |
| Equilibrado | meio-termo |

Cada personagem tem um perfil próprio com prioridades e pesos (exemplos em [content/CHARACTERS.md](content/CHARACTERS.md)).

### Dificuldade

| | Fácil | Normal | Difícil | Chefe |
| --- | --- | --- | --- | --- |
| Reação | lenta | média | rápida (nunca abaixo de 0,15 s) | no limite humano |
| Defesa | rara | às vezes | frequente | quase sempre |
| Parry contra fortes | nunca | às vezes, quase nunca perfeito | frequente, às vezes perfeito | frequente |
| Empurrão | raro | às vezes | frequente | frequente |
| Erros | frequentes | alguns | raros | muito raros |
| Aviso antes de atacar | 0,25 s | 0,08 s | nenhum | nenhum |
| Punição inteligente (forte quando a recovery permite) | não | não | sim | sim |
| Isca de whiff (recua para o golpe errar e pune) | não | às vezes | frequente | frequente |
| Memória de hábitos | não | não | sim | sim |
| Habilidade e poderes | raros | às vezes | no momento certo | no momento certo |

A **memória de hábitos** olha só o que o jogador fez: mais parry contra quem abusa do forte, mais empurrão contra quem só guarda, mais guarda contra quem só ataca rápido. A IA continua errando às vezes.

## 16. Modos de jogo

Menu em dois níveis: **Jogar**, **Aprender**, **Extras**, **Opções**.

### Jogar

Jogar tem só História, Duelar, Batalhas e Modos especiais; os modos ficam em submenus para a lista não crescer a cada modo novo:

- **Duelar**: 1 Jogador, 2 Jogadores, CPU vs CPU.
- **Batalhas**: Arcade, Sobrevivência, Caçada a chefes.
- **Modos especiais**: Infiltração e Combate de naves (modos fora do duelo de lâminas). Planejado: **Operações de blaster** (tiro em visão de cima, várias missões: arena, assalto, defesa, resistir até a extração, escolta, duelo de blasters e chefe), reaproveitando o núcleo da Infiltração e as regras de disparo.

Avaliação das sugestões de modos (autor e Claude): entram Operações de blaster e, depois de jogadas, uma camada opcional de **operações em sequência** (rotas de salas montadas a partir dos mapas, melhorias só na partida, semente determinística). A defesa de base vira um tipo de missão das Operações. Ficam fora por ora, por exigirem um sistema novo de movimento ou de IA com pouco reaproveitamento: combate de veículos terrestres (repete o de naves), comando tático de equipe e corrida de speeder. A **aventura de plataforma** foi reavaliada a pedido do autor e entra como **Fases de ação**: os controles do duelo (dashes, pulo duplo, pulo na parede, ataques, defesas, esquiva de precisão e poderes) já formam um jogo de ação completo; muda o mundo em volta. Sem trava permanente no oponente (a frente segue o direcional, com trava suave só perto de um inimigo), vários inimigos simples, plataformas, abismos e pontos de retorno, câmera que segue o jogador, mini-chefes em duelo de verdade e **desvio de costas**: com a guarda, um toque no tempo do parry devolve um disparo que chega por trás sem virar o corpo. O duelo não muda: o núcleo ganha um provedor de alvo em vez de supor sempre o oponente, e a matriz IA × IA tem de ficar idêntica. Também planejados: um quarto estilo da História, **lâmina com as duas mãos e blaster no coldre** (saca só nas técnicas de disparo, blasters como dados para variar no futuro), e a **Saga**, campanha maior que mistura os modos; nela, o estilo com blaster leva às Operações de blaster e o estilo só de lâmina às Infiltrações.

- **1 Jogador**: escolha do lutador, do adversário (pode ser o mesmo) e da arena; dificuldade nas Opções. Conjunto de poderes **Base** ou **Personalizado** na seleção.
- **História**: campanha com protagonista criado pelo jogador. Ver [content/STORY.md](content/STORY.md).
- **Arcade**: escolha do lutador e até 6 adversários em rodízio pelo elenco, mais o **chefe**. Dificuldade crescente (2 no Fácil, 2 no Normal, o resto no Difícil). Arenas em rodízio. Perder permite tentar a mesma luta. **Chefe: Sombra Desperta**, no Difícil; abaixo de metade da vida **desperta**: mensagem "A SOMBRA DESPERTA", letterbox pulsando e a IA passa à dificuldade de chefe. Vencer mostra "ARCADE CONCLUÍDO" e registra o feito para aquele personagem.
- **Sobrevivência**: adversários em sequência até perder, um round cada. A vida não volta cheia: cada vitória devolve 30% da vida máxima. Dificuldade sobe (2 no Fácil, 3 no Normal, depois Difícil). A cada 5 vitórias, o chefe. Recorde salvo.
- **2 Jogadores** (local): cada jogador escolhe o lutador com os próprios controles; J1 escolhe a arena. Melhor de 3. Os dois podem pausar.
- **CPU vs CPU**: o jogador escolhe os dois lutadores e a arena e assiste à IA, na dificuldade das Opções, lutar dos dois lados. Melhor de 3, pausa disponível, resultado **FIM DO DUELO** com o vencedor. Não desbloqueia nada nem grava progresso.

### Aprender

- **Tutorial**: contra o boneco, sem rounds e sem morte. Uma instrução por vez, com as teclas do preset ativo; cada passo termina quando o jogador faz a ação: andar → rápido (2) → sequência → forte → guarda (2) → aparar fortes (2) → contra-ataque → empurrão → quebra de guarda → ferimento → disputa de lâminas → habilidade. No fim oferece o desafio de parry.
- **Treinos guiados**: Esquiva em sequência (esquivar no instante, três seguidas, esquivar e punir, duas esquivas com giro contra o boneco que solta fortes), Exaustão e ferimento (exaurir-se, recuperar, quebrar a guarda do boneco, feri-lo), Disputa de lâminas (provocar e vencer três disputas, depois vencer uma pressão de lâminas e desengajar de uma disputa).
- **Treino**: contra o boneco, sem limite de rounds. Comportamento do boneco (parado, guarda, atacando), gravação de até 10 s de comandos do jogador e reprodução no boneco em loop, hitboxes visíveis, **dados de quadro** do último golpe (ex.: `Forte · bloqueado · −0,30 s`; negativo = o oponente age primeiro), comandos dos dois na tela.
- **Desafio de parry**: 45 s contra o boneco, que só lança fortes em intervalos aleatórios. Parry vale 1 ponto, perfeito 2. Recorde salvo.
- **Controles**: tabela de ações e teclas atuais.

### Caçada a chefes (task 09)

Jogar › Batalhas › Caçada a chefes oferece três missões independentes, disponíveis desde o início. Cada uma usa o Guardião com Fluxo 7, Repulsão, Cura e Barreira, um round, Poderes sempre ligados e dificuldade-base Difícil. O conjunto é fixo e não altera o elenco. Não há moeda, atributos permanentes ou repetição obrigatória.

| Caçada | Chefe / arena | Fases (vida restante) e padrão | Condição especial | Recompensa única |
| --- | --- | --- | --- | --- |
| A última lição | Ancião / Santuário Alagado | 100%: fortes e distância curta, Repulsão; 65%: defesa paciente, Barreira e Repulsão; 30%: contra-ataques e Instinto Superior | Aparar perfeitamente três fortes e vencer | Traje Viajante do Guardião |
| O olho da tempestade | Soberano / Convés em Voo | 100%: pressão à distância, Raio; 65%: Tempestade e aproximação; 30%: pressão agressiva com Raio e Tempestade | Vencer em até 90 s de simulação de luta; guarda não segura Tempestade, use deslocamento, esquiva ou Barreira | Cor do Arcade do Guardião |
| O peso do vazio | Sombra Desperta / Cidadela do Eclipse | 100%: avanços e Puxão; 65%: Singularidade Devastadora e reposicionamento; 30%: ofensiva curta, Singularidade e Repulsão | Sobreviver ao ciclo completo de uma Singularidade (massa lançada e encerrada, ambos vivos), depois vencer | Cor do desafio da Sombra |

Cada fase é um recurso com limiar inclusivo, perfil de IA, conjunto de poderes, nível de Fluxo, reserva inicial de medidor e poder de abertura opcional. Limiares só avançam, uma vez por fase, sem curar nem reviver o chefe. Um golpe que cruza vários limiares vivos processa-os em ordem. O poder de abertura usa comandos normais da IA: pode ser interrompido e volta a ser tentado enquanto não ativar. A mudança de conjunto espera o fim de uma invocação/canal/campo anterior para preservar sua resolução. Não há armadura nem perigo novo de arena.

O cronômetro conta ticks em FIGHT, incluindo hit stop, cinemáticas determinísticas e o tick letal que inicia o K.O.; exclui intro, pausa, tempo posterior de K.O. e replay. A condição é avaliada junto da vitória: matar antes dos três parries ou antes de sobreviver à massa encerra a missão sem sucesso. A morte do lançador durante o campo não conta como sobrevivência. Uma derrota nunca grava conclusão ou recorde. Repetir com sucesso só melhora o menor tempo; recompensas são idempotentes. Falas curtas antes e depois contextualizam as missões. A lista permite rever o epílogo depois da primeira conclusão.

### Extras

- **Desafios**: duelos fixos de um round, com recorde de menor tempo:
  - *Salinas sem Fluxo*: Guardião contra Sombra, Salinas de Vidro, Difícil, sem Poderes. "Vença só com a lâmina."
  - *Tempestade no convés*: Vespa contra Soberano, Convés em Voo, Normal, com Poderes. "Sobreviva à Tempestade e vença."
  - *Último fôlego*: Bastião contra Forja, Cume Nevado, Normal, sem Poderes, começando com 35% de vida.
  - *Sob o eclipse*: Ceifador contra Espelho, Cidadela do Eclipse, Difícil, com Poderes. "Duas lâminas contra o reflexo, no escuro."
- **Galeria de poderes**: cena de duelo sem rounds para ver cada poder e técnica em cada tier, contra alvos diferentes (parado, em guarda, com Barreira, com Absorção, no ar, atacando com Raio), com repetição automática e troca de lançador. Um botão liga a demonstração da finalização cinematográfica dos poderes e técnicas que a têm (regra `MatchRules.endless_finishers`: no modo sem fim o golpe pode matar, todo K.O. conta como decisivo e o round recomeça sem placar).
- **Galeria da História**: encontros vencidos e finais alcançados, revistos com as falas; o que não foi visto aparece como `???`.
- **Sequência de exibição** (decisão do autor): três duelos coreografados em sequência, como uma vitrine do jogo, sem controle do jogador. Cada duelo roda na simulação de verdade, com um roteiro de comandos por tick para os dois lutadores (determinístico: sai igual toda vez), e termina numa finalização cinematográfica:
  1. **Lâminas** · Guardião contra Sombra: trocas de rápidos, guarda, choque, disputa de lâminas, esquivas e parry perfeito; termina nas duas lâminas.
  2. **Fluxo** · Ancião contra Sombra Desperta: poderes dos dois caminhos (Raio contra Barreira, Repulsão, Puxão, Telecinese em Massa…); termina numa finalização de poder.
  3. **Dança** · Garça contra Vespa: acrobacias, pulo duplo, esquiva com giro, as duas lâminas da Vespa e choque de fortes; termina no giro da Garça.
  Valem Poderes com Fluxo sempre cheio (`free_powers`), finalizações, disputa e as entradas dos lutadores; a vida inicial de cada um vem do roteiro (`start_health`). Não há replay do golpe final nem tela de resultado: o duelo seguinte entra com o fade do roteador. Confirmar pula para o próximo; pausar permite sair. No fim, volta aos Extras.
- **Duelo de exibição** (pedido do autor): um único duelo coreografado mais longo, com as mesmas regras da Sequência (simulação real, roteiro por tick, `free_powers`, entradas, sem replay nem resultado). **Reflexo** · Corsária contra Espelho no Santuário Alagado, cerca de 21 s de luta antes da finalização: pingue-pongue de disparos devolvidos por parry, Rajada Desestabilizadora com os cinco disparos evitados pelo Espelho, um a um, com a esquiva de precisão (sem custo de Vigor; o avanço final fica curto), troca de rápidos com parries e choques, disputa de lâminas encerrada pelo Espelho se desvencilhando, **Instinto Superior** da Corsária com três esquivas automáticas (estocada, rápido, corte ascendente) e três contra-ataques, Repulsão que encerra o Instinto, pulo duplo sobre o Arremesso, esquiva com giro por trás do forte de avanço, disparo de recuo nas costas, esquiva de precisão punida, Postura de Espera com parry perfeito e contra-ataque, choque de rápidos, Puxão e o forte parado da Corsária na **execução cruzada**. O roteiro pode subir o nível de Fluxo de cada lutador (`ExhibitionBout.flow_levels`) para liberar poderes de tier alto; aqui Corsária 8 e Espelho 7. Confirmar pula o duelo e volta aos Extras.

## 17. Progressão e desbloqueios

Progressão cosmética nos modos de duelo; nada muda os atributos do elenco.

- **Cores de lâmina**: cada personagem tem a cor padrão e duas alternativas. A **cor do Arcade** libera ao vencer o Arcade com ele; a **cor do desafio**, ao vencer um duelo contra a IA cumprindo o desafio do personagem (lista em [content/CHARACTERS.md](content/CHARACTERS.md)).
- **Trajes**: elenco com Original, Viajante (vencer o Arcade com o lutador) e Sentinela (concluir qualquer final da História). Secretos têm trajes próprios (ver CHARACTERS).
- **Personagens secretos**: liberados pela História (ver STORY) ou pelo segredo da abertura.
- **Segredos da tela de abertura** (sem pista na tela; janela de 2,5 s entre entradas):
  - *O Equilíbrio*: ← ← → → ↑ ↓ ↑ ↓ libera os três secretos e as duas variantes do Predestinado, com som grave e a frase "O EQUILÍBRIO DESPERTA".
  - *O Guarda-roupa*: ↓ ↓ ↑ ↑ → ← → ←, ou cinco toques na frase abaixo do título, libera todos os trajes e cores, com um arpejo claro e a frase "TODOS OS TRAJES REVELADOS".
- Tudo salvo localmente.
- Implementado na fase 6 (`core/unlocks.gd` sobre o `SaveService`): cor do Arcade e traje Viajante ao vencer o Arcade; cor do desafio pelo `CharacterData.challenge_stat`/`challenge_target` (lido das estatísticas do duelo contra a IA); secretos pelo Equilíbrio; tudo pelo Guarda-roupa. Sentinela e os trajes de final só existem com a História (fase 7); até lá, só o Guarda-roupa os libera.

## 18. Opções

Idioma (Português/English), dificuldade, efeitos (Completos/Reduzidos), som, música, preset de teclado e remapeamento, replay do golpe final, finalizações, Poderes, segurar para disputar (por jogador), vibração do gamepad. Configurações de vídeo (resolução, tela cheia, V-Sync) e volumes separados.

## Operações de blaster (tasks 16–18)

Modo de tiro top-down que estende a fundação da Infiltração, com regras próprias e sem alterar o duelo. Regras, números e arquétipos em [content/BLASTER_OPS.md](content/BLASTER_OPS.md). A task 16 entrega um treino por rota técnica, sem missões, menu público ou progresso; a 17 colocará a seleção em **Jogar › Modos especiais › Operações de blaster**.

Defesa de base é um tipo de missão deste modo, não outro modo. Veículos terrestres repetem a pilotagem das naves; comando de esquadrão, corrida e aventura lateral com motor próprio exigiriam movimento ou IA novos com pouco reaproveitamento, e ficam descartados. A decisão posterior do autor sobre **Fases de ação** (tasks 21–22), reaproveitando os controles e o núcleo do duelo, continua válida; não é implementada nesta tarefa.

Primária usa calor, nunca munição ou itens. Esquiva curta tem janela invulnerável interna; cruzar um disparo no começo dessa janela devolve a recarga. Guarda mira com a lâmina: toque no tempo devolve **na direção da mira**, inclusive no perfeito; guarda tardia só desfaz o tiro e gasta Vigor. Paredes bloqueiam tiros, e caixas marcadas podem ser destruídas. Um único poder equipado por vez (Repulsão, Puxão ou Barreira), com recarga; sem barra adicional de Fluxo neste modo. Personagens sem arma usam pistola temporária mais fraca. Cada tiro inimigo avisa antes, e o atirador trava uma linha de mira legível.

## Infiltração (tasks 10–12)

Modo próprio de ação e furtividade em bases vistas de cima, autorizado em DESIGN, "Além do duelo". Usa simulação separada do duelo, em 60 Hz. A task 10 entrega apenas o **Treino de infiltração**, em Aprender: uma sala navegável com paredes, caixas, boneco e emissores de disparos, sem progressão ou recompensas. Não há patrulhas, alarmes funcionais ou missões nesta etapa.

### Movimento, mira e combate

- Movimento livre em dois eixos, diagonal normalizada: andar 240 u/s, correr 360 u/s, mover-se furtivamente 120 u/s, aceleração 2.200 u/s² e desaceleração 2.800 u/s². Furtivo significa passos curtos e corpo recolhido, sem agachar para esquivar de ataques nem defesa alta/baixa. Correr e furtivo não consomem Vigor; furtivo tem prioridade. Corpo com meia extensão de 18 u, colisão determinística por eixo contra grade e alvos sólidos, sem atravessar paredes/cantos.
- Teclado próprio e fixo, com tudo ao alcance da mão esquerda (a direita fica no mouse): WASD ou setas movem, Shift corre, Ctrl (ou C) agacha em furtivo; o controle usa stick esquerdo/D-pad e os botões do duelo. Correr usa a ação Esquiva, furtivo usa Habilidade. O mouse mira sem exigir clique; stick direito mira independentemente do movimento. Sem mouse/stick direito, a última direção de movimento define a mira. Ataque e guarda usam as ações do J1 e também botões do mouse registrados no InputMap. Nenhuma regra lê teclas físicas. Não há pulo neste plano.
- Um golpe curto cobre **120°**, alcance **88 u**, com preparação 0,10 s, ativo 0,10 s e recuperação 0,20 s; dano 10, custo 8 de Vigor. Direção travada ao iniciar, cada alvo recebe no máximo um acerto por golpe. Parede bloqueia o corte. Guarda não pode coexistir com golpe; novo ataque toma prioridade, sem cancelar a preparação/ativo ao receber um disparo. No ativo a lâmina percorre o arco; cada tick resolve só a fatia varrida até sua amostra atual, para não atingir o centro enquanto a lâmina ainda prepara o lado oposto. Corpo e empunhadura conservam a direção travada do golpe; a arte só lê essa fase.
- Guarda cobre **140°** à frente da mira, movimento limitado a 60% da caminhada e sem corrida; furtivo conserva seu limite menor de 120 u/s e seu ruído. Tocar abre parry por 0,20 s; os primeiros 0,08 s são perfeitos; nova janela exige soltar e respeitar 0,40 s de recarga após falhar/expirar. Segurar além da janela mantém guarda. A janela não fecha ao devolver um disparo, permitindo aparar uma rajada, como no duelo.
- Reutiliza `data/bolts/standard_bolt.tres`: 900 u/s, alcance 1.100 u, dano 4, tranco 0,12 s, custo 4 na guarda, saída 30 u à frente, perfeito a 125% da velocidade. A altura do disparo lateral não se aplica. Guarda frontal desfaz o disparo sem blockstun e drena Vigor, funcionando mesmo com medidor vazio; pelas costas, acerta. Parry devolve pela linha inversa; perfeito mira o centro de quem emitiu, preservando a velocidade base × 1,25. Disparo encontra parede/corpo por percurso varrido, sem saltar a colisão entre ticks. A devolução passa a pertencer ao jogador e pode destruir o emissor. Disparos não geram Fluxo.
- Vida 100, Vigor 100 com regeneração 25/s após 0,6 s sem gastar; sem ferimentos, finalizações ou exaustão especial nesta etapa. Disparo causa tranco somente em repouso/movimento/recuperação, nunca cancela preparação ou ativo. Vida zero encerra o controle e oferece reiniciar ou voltar. Bonecos/emissores destruídos reaparecem após 3 s para repetir a prática; não dão recompensas.

### Próximas etapas já delimitadas

Task 11 entrega patrulhas, sentinelas que giram sobre a posição inicial e pesados com rajadas. Recursos de arquétipo definem velocidade (110/0/75 u/s), vida (20/16/36), cone (80/100/75°), alcance (400/440/360 u), cadência e disparo. Posições, rotas e reforços são dados do mapa. Inimigos abatidos não reaparecem; boneco e emissor de treino conservam seu reaparecimento.

Detecção exige cone e linha livre contra paredes e caixas. Visão acumula 1 ponto/s até alerta em 1; a partir de 0,25 há suspeita. Sem visão decai 0,20/s; alerta conserva a última posição por 5 s antes de voltar à busca. Furtivo acumula visão a 60%, sem invisibilidade. Suspeitos investigam a última posição vista/ouvida e retomam a rota após perder a suspeita. A IA não conhece a posição atual escondida. Ruído tem raio de 40/220/16 u para passos andando/correndo/furtivo, 300 u para corte, tiro e defesa de disparo, 240 u para disparo devolvido que bate na parede. Audição usa raio euclidiano (paredes não isolam som), eleva a suspeita até 0,45 e nunca alerta sozinha. Sem sombras com bônus nem distração arremessável nesta etapa; coberturas e movimento já permitem abordagem furtiva.

Ataque forte no treino pede **abate silencioso**: exige alvo despercebido (suspeita abaixo de 0,25), jogador no setor traseiro de 100°, até 72 u, mira dentro de 120° e linha livre. Mata instantaneamente sem ruído; alvo suspeito/alertado recusa, sem converter em ataque comum. Corte normal e disparos devolvidos causam dano e alertam o sobrevivente. Não há sangue ou finalização de membros.

Ao alertar, inimigo móvel corre até o painel disponível mais próximo a 150% da sua velocidade de patrulha, navegando pela grade; sentinela permanece fixa. Dentro de 56 u, pede ativação durante 0,75 s. O painel aceso chama uma única onda fixa após 2 s; reforços entram por pontos de acesso marcados e livres do mapa, nunca perto do jogador por sorteio. Acesso ocupado adia entrada; desligar todos os alarmes cancela chamadas pendentes. Interação do jogador (ação Poder do J1 no treino), dentro de 80 u e com linha livre, inutiliza permanentemente o painel e interrompe sua sirene. Alarme não derrota o jogador, não ressuscita inimigos e não concede percepção através de paredes. Desligá-lo não apaga a memória dos inimigos nem remove reforços já entrados. Mapa admite vários painéis; uma só onda por tentativa limita pressão. Reinício restaura tudo.

Todos os temporizadores e limites vêm de configuração; controladores só produzem intenção, a simulação resolve percepção, navegação física, tiro, interação e alarme. Cones são informação de leitura, nunca luz que esconde disparos. Missões, extração e recompensas continuam na task 12.

Task 12: missões em recursos descrevem mapa, objetivos (desativar alarme, resgatar, obter informação), extração, falas e recompensa única. Vencer exige cumprir os objetivos obrigatórios e alcançar a extração; perder por morte ou falha explícita de objetivo, jamais por perigos visuais. Abordagem furtiva ou agressiva chega ao mesmo objetivo, sem moeda/grind. Alarme aumenta pressão e não encerra a missão sozinho. Poderes permanecem desligados no treino inicial; a task 12 decide um subconjunto pequeno de Repulsão/Puxão e seus custos, sem importar automaticamente todas as supremas do duelo. Menu definitivo e resultados pertencem à task 12.

### Missões e extração (task 12)

Jogar › Modos especiais › Infiltração substitui a entrada temporária de Aprender. Seis missões longas (3 a 6 minutos), todas com resgate de prisioneiros como foco, sete tipos de inimigo que também atacam os prisioneiros e mínimo de resgates por missão, e regras completas em [content/INFILTRATION.md](content/INFILTRATION.md): tutorial curto, sabotagem de dois painéis, cópia de informação e escolta de prisioneiro. Dados definem mapa, spawn, guardas, painéis, terminais, prisioneiros, saída e briefing. Poderes permanecem desligados; Poder interage. Objetivos e relógio avançam apenas no tick fixo. Derrota por jogador/prisioneiro abatido precede extração. Bônus: nenhum alarme na tentativa, nenhum inimigo abatido e tempo inclusivo. Abordagem Furtivo/Direto depende do histórico de alarme. Conclusão, menor tempo e união dos bônus são salvos apenas nas vitórias; sem recompensa adicional ou grind.

### Mapa do treino

`InfiltrationMapData` guarda linhas de tiles de **64 u** (32 px nativos), spawn do jogador e recursos de alvo/emissor. Símbolos: chão `.`, parede `#`, caixa sólida `C`, faixa de piso `=`. Fora da grade é sólido. A mesma grade é a fonte de colisão e desenho; sem TileMap físico paralelo. O mapa original de teste é um setor industrial com corredor de tiro horizontal e uma área protegida para testar o arco. Coordenadas de spawn usam centros de células livres. Nenhum perigo de cenário causa dano.

## Combate de naves (tasks 13–14)

Modo próprio top-down de arenas espaciais em **Jogar › Modos especiais › Combate de naves**, junto da Infiltração. A task 13 estabeleceu o treino de fundação; a task 14 o substitui no fluxo por cinco missões, resultados e oficina. A rota técnica foi removida. Simulação independente em 60 Hz, sem mudar o duelo ou seus números. Recursos de treino continuam como fixtures, sem recompensa.

### Pilotagem e combate básico

- Modelo de propulsão e rotação, sem mira desacoplada: esquerda/direita do J1 giram; Pulo propulsiona para a frente, Esquiva de precisão dá ré. No padrão: A/D e W/S; stick esquerdo/D-pad no gamepad. Ações próprias `space_*` copiam bindings atuais e são removidas ao sair; não alteram ações de outros modos. Não há pulo no espaço.
- Rotação de 210°/s, propulsão de 600 u/s², ré a 55% dessa aceleração, arrasto linear de 100 u/s², velocidade máxima 360 u/s. Em cada tick: girar, somar aceleração na direção da nave, aplicar arrasto e limitar velocidade, então mover. Soltar propulsão conserva inércia até o arrasto parar; diagonais do stick não amplificam a potência. A frente da nave é sua direção de tiro. Câmera acompanha sem girar o mundo.
- Armas: Rápido do J1 dispara a primária enquanto segurado; Forte aciona a secundária. No treino a secundária está indisponível e mostra aviso curto, sem gastar recurso. Primária: 10 de dano, 1.000 u/s, alcance 1.400 u, raio de 3 u, cadência de 0,18 s. Projéteis vêm de pool fixo, colidem pelo percurso relativo entre círculos móveis e não atravessam alvos entre ticks. Aliados não se atingem; um disparo acerta só a primeira vítima e se encerra ao sair da arena. Pool cheio recusa o tiro sem cobrar recarga; não recicla projétil em voo.
- Impulso evasivo: Esquiva do J1 (Shift / botão leste). Novo toque inicia 0,30 s a 720 u/s, recarga de 1,50 s desde a ativação. Vai na direção da proa, ou para trás se segurando ré; direção travada. Invulnerável apenas de 0,05 s inclusive a 0,20 s exclusive, deixando preparação e cauda vulneráveis. Durante o impulso não gira nem dispara; ao terminar volta ao limite de velocidade normal. Sem energia ou medidor adicional. Dano não cancela o deslocamento. Não há rolagem 3D: a silhueta comprime e deixa ecos curtos no plano superior.
- Nave de treino **Trama**: casco 100, escudo 40 (28 nas missões, ver [content/SPACE.md](content/SPACE.md)), corpo circular de raio 26 u. O dano consome primeiro o escudo e o excedente chega ao casco no mesmo acerto; casco nunca fica negativo. Todo acerto válido reinicia o atraso de regeneração de 2 s; depois regenera 12 de escudo por segundo. Esquiva bem-sucedida consome o disparo que cruzou a janela, sem consumir escudo nem reiniciar o atraso. Casco não regenera em voo. Casco zero trava controle e oferece reiniciar/voltar.
- Limites da arena são sólidos sem dano, sem teleporte e sem rebote: centro fica pelo menos um raio para dentro; a componente de velocidade contra a borda zera. Corpos de naves vivas também não se atravessam; resolvem separação por ordem estável de índice, sem dano de contato. Obstáculos visuais não existem como regras nesta etapa.
- Um arquétipo de **drone-alvo**: estacionário, casco 30, sem escudo, raio 24 u. Controlador externo gira até o jogador e só produz intenção. Sua arma avisa por 0,45 s antes de disparar, causa 10, velocidade 460 u/s, alcance 1.200 u e recarga 1,4 s. A preparação exige manter a intenção; soltar a interrompe. Fora de alcance ou desalinhado, o controlador não pede tiro. Saída do tiro é dado da arma: 44 u à frente na Trama, 32 u à frente e 14 u para o lado no emissor do drone. Três acertos de primária destroem o drone; reaparece após 3 s no treino, aguardando se o ponto estiver ocupado. Arena de teste 2.800×1.800 u, três drones em posições fixas e jogador ao centro. Nenhuma morte dá moeda ou desbloqueio.

### Conteúdo e melhorias planejados para a task 14

Arquétipos por recursos e controladores: caça em esquadrilha/formação; interceptador perseguidor rápido e frágil; canhoneira lenta de rajadas abertas; torre fixa com aviso; seções de nave capital (torres, gerador e motores independentes); chefe de fases por limiar e pontos fracos. Mísseis telegrafados poderão perseguir e ser destruídos ou evitados pelo impulso. Detritos terão formas originais e colisão explícita, sem morte instantânea. Nada disso é implementado pela task 13.

Seis missões vão de esquadrões a ataque/proteção de capital e campo de destroços, e terminam em chefe. Recursos descrevem ondas, objetivos, aliado, limite e briefing. Fluxo: seleção → briefing → missão → resultado → melhorias/próxima. Casco do aliado em zero falha a missão de proteção. Cada missão aceitará conjunto explícito de nave/armas/melhorias e devolverá resultado para um fluxo externo, preparando a futura Saga.

Economia fechada no modo: um ponto por primeira conclusão de cada missão, sem recompensa por repetir; cinco pontos no total. Arma, escudo e velocidade têm dois níveis opcionais de um ponto cada, efeitos em configuração e compra entre missões; escolhas podem ser redistribuídas sem custo na oficina. Não há moeda universal, loja, XP, bônus por abates ou repetição obrigatória. Nenhuma melhoria afeta duelo, História ou Infiltração. Save próprio dentro do SaveService guardará missões, pontos e escolhas na task 14; o treino não lê nem grava esse progresso.

### Missões e melhorias implementadas (task 14)

Revisão do autor: fases de 3 a 5 minutos, sexta missão, quatro naves no Hangar, escudo menor, colisão com outra nave custando escudo e caças que atacam de perto. Valores em [content/SPACE.md](content/SPACE.md).

Modo completo em Jogar › Modos especiais › Combate de naves; a rota técnica temporária deixa o roteador. [content/SPACE.md](content/SPACE.md) define as cinco operações, formações, inimigos, mísseis interceptáveis, detritos, capitais por seções, chefe de três fases, avaliação e melhorias. A secundária passa a ser um míssil por toque. Regras de propulsão, escudo e impulso da task 13 permanecem. Slots de ondas e projéteis são pools; nenhum controlador resolve dano, fase ou objetivo. Resultados e progresso são selados, separados do núcleo; conjunto e resultado explícitos permitem fluxo externo sem salvar ou navegar automaticamente.

## Saga: premissa decidida pelo autor

A campanha completa parte de dois pressupostos opostos. No **Eclipse**, a hierarquia é Soberano, Sombra Desperta como subordinada direta dele, e o protagonista como subordinado dela; a ordem de destruir os cavaleiros da Aurora desce por essa cadeia, e os prisioneiros a resgatar são agentes do Eclipse capturados pela ordem. Na **Aurora**, o Ancião envia o protagonista, cavaleiro da ordem, para derrubar o império do Soberano. Detalhes ficam para a task 19 do Codex.

## Operações: Infiltração e Incursão (decisão do autor)

Infiltração e Operações de blaster viram um menu só, **Operações**, com rótulo de objetivo em cada missão. O personagem controla igual em todas, e a regra da missão muda o jogo: na Infiltração a esquiva e o blaster fazem barulho, e o poder tem recarga longa; na Incursão o objetivo é eliminar, destruir bases ou chefes, e prisioneiros libertos são secundários e ajudam. Toda missão pode ser concluída só com o sabre. Blaster de uma mão deixa o sabre aceso na outra. Implementação nas tasks 17 e 18.

## Arsenal da História

Decisão do autor. Tela **Arsenal** no hub, para qualquer estilo. **Créditos** vêm só da primeira vitória em cada encontro: repetir não rende nada, e saves antigos recebem pelos encontros já vencidos. Compram só blasters; não valem fora da História. O elenco do duelo não muda.

Cada arma tem seu **padrão de disparo**, usado pelas técnicas de saque e pela habilidade:

| Blaster | Mãos e porte | Tiros | Dano | Tranco | Saque | Preço |
|---|---|---|---|---|---|---|
| Pistola | 1, quadril | conforme a técnica (1 a 3) | 4 | 0,25 s | 0,15 s | grátis |
| Revólver pesado | 1, coxa | 1 | 12 | 0,40 s | 0,22 s | 150 |
| Carabina | 2, lombar | 2 | 6 | 0,25 s | 0,28 s | 200 |
| Rifle | 2, costas | 3 | 6 | 0,20 s | 0,40 s | 300 |
| Rifle de precisão | 2, costas | 1 | 22 | 0,50 s | 0,60 s | 450 |

Disparo devolvido segue valendo: errar com o Rifle de precisão contra quem sabe aparar custa caro. O Vigor gasto e o tamanho do disparo sobem com a arma.

**Estilos sem blaster:** quem tem um blaster equipado escolhe um dos espaços de técnica (Frente ou Trás) para o saque. Ele **substitui** a técnica daquele espaço, e essa é a contrapartida. Sem blaster equipado, nada muda. O estilo Coldre mantém seu kit e a habilidade Fogo de cobertura, que usa o padrão da arma equipada.

## Estilo Coldre da História (task 15)

Quarto estilo, **Coldre / Holster**, exclusivo do protagonista: família Guardião, guarda e sequência de duas mãos, dano de lâmina 10% abaixo de Técnica nos mesmos atributos. Não entra no elenco nem na matriz. Não muda botões, regras dos disparos nem os estilos Versáteis.

| Espaço | Golpe | Preparação / ativo / recuperação sem saque | Vigor | Tiros |
| --- | --- | --- | --- | --- |
| Trás | Saque de recuo / Retreat Draw | 0,10 / 0,12 / 0,20 s | 12 | 1, recua 90 u durante a preparação completa |
| Frente | Saque duplo / Double Draw | 0,12 / 0,24 / 0,20 s | 16 | 2, intervalo 0,12 s |
| Habilidade | Fogo de cobertura / Covering Fire | 0,20 / 0,36 / 0,24 s | 22 | 3, intervalo 0,12 s |
| Ar | Investida descendente | recurso existente | existente | só lâmina |

O saque da arma soma à preparação e o retorno soma à recuperação; ambos arredondados para ticks de 60 Hz. Pistola de quadril: saque 0,15 s, retorno 0,15 s, disparo de 4 de dano a 900 u/s, alcance 1.100 u. Rifle de dorso: saque 0,40 s, retorno 0,30 s, disparo de 8 de dano a 650 u/s, alcance 1.500 u. A arma define o projétil, o golpe define quantos tiros usa. A rajada da habilidade prepara por mais tempo; nenhum disparo aéreo.

Após o primeiro tiro, guarda ou esquiva de precisão cancelam os tiros restantes e a recuperação. O cancelamento recolhe a arma imediatamente; na guarda a mão auxiliar leva o tempo de retorno para reassumir o cabo, pagando +25% de Vigor nos bloqueios desse intervalo (inclusive contra disparos). Parry conserva a regra normal. Durante saque, mira e retorno, a lâmina tem só uma mão; não há guarda simultânea ao ataque. `sidearm_out` indica arma sacada entre o fim do saque e o começo do retorno, nunca em repouso, guarda, esquiva, disputa ou finalização. Interrupções recolhem a arma, sem permitir disparos atrasados. O rifle usa as duas mãos ao mirar, com a lâmina baixa na mão principal, e o mesmo custo transitório de guarda.

## 19. Fora do escopo inicial

Online, torneio, editor de personagens, perigos de arena que afetam o combate. A arquitetura deixa espaço para eles (simulação determinística, arena que reage a eventos).

### Instinto Superior

Suprema da Aurora (POWERS.md), com esquiva automática de acertos de lâmina corpo a corpo, exceto golpes em volta do corpo. Empurrões, projéteis, áreas, agarrões e poderes passam pelas regras normais. Choque/disputa têm prioridade e não são evitados. Cada esquiva interrompe a ação do usuário, preserva posição/altura e abre 0,35 s para o rápido iniciar o contra-ataque existente (sem multiplicador adicional); não existe bônus de punição da esquiva de precisão para reaplicar. A janela não garante acerto nem desliga a defesa rival. Dano efetivo de poder encerra status, movimento visual e janela; absorção total não encerra. Duração e janela são dados do PowerData.

### Singularidade Devastadora

Suprema Eclipse de Fluxo 7, custo 80: criação interrompível → suspensão → marcas e extrações → formação com mira fixa → arremesso físico. A sequência dura cerca de 4,5 s. Corrida lateral vence a atração no chão e deixa os avisos para trás; pular expõe à atração mais forte e as extrações levantam quem fica parado. Guarda, Barreira, Absorção e Arsenal não param o arremesso; Santuário protege a vida sem anular o deslocamento. Esquiva invulnerável e sair da trajetória funcionam. O Instinto não evita extração nem massa. Números e tempos em content/POWERS.md e singularity.tres.
