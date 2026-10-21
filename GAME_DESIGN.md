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

### Esquiva de precisão

- Baixo (separada da esquiva). No chão, **não custa Vigor**, recua muito pouco, fica invulnerável por apenas ~0,066 s e tem recovery de até 0,4 s.
- Se um golpe cruza a hurtbox nessa janela: **sucesso**, o golpe é consumido e o defensor fica livre na hora para punir. Sem contato, a recovery fica vulnerável.
- Cada uso exige um toque novo. Sucessos seguidos formam uma sequência visível (luz curta, pose alternada).

### Choque de lâminas (clash)

- Quando os dois estão no active ao mesmo tempo e as lâminas se encostam. O choque tem prioridade sobre o hit: ninguém leva dano.
- **Rápido contra rápido**: faíscas, som e tremor; os golpes deixam de acertar, um empurrão curto (120 u) separa os dois, ninguém entra em recuo e a sequência continua.
- **Com um forte envolvido**: os dois ataques são cancelados, os dois são empurrados (280 u) e ficam 0,25 s em recuo (`HIT`, sem dano).
- **Forte contra forte** elegíveis iniciam a **disputa de lâminas**.
- **Choque entre técnicas de lâmina**: as duas são interrompidas num choque grande, os dois recuam 420 u, ficam desequilibrados por 0,4 s e perdem 12 de Vigor.

### Disputa de lâminas

O momento mais físico do duelo: rostos próximos, lâminas cruzadas num X, tremor e som crescente.

- **Entrada**: dois fortes comuns ou de avanço se chocam no active a até ~70 u de distância. Recarga de 4 s entre disputas.
- **Durante**: cada aperto de ataque rápido é uma pressão (no máximo 15 por segundo contam). Quem abrir **5 pressões de vantagem** vence. Tempo máximo de 3 s.
- **Vitória**: o perdedor leva 8 de dano e perde 35 de Vigor uma única vez, fica `STAGGERED` por 0,35 s; o vencedor tem 0,25 s de recovery. Os dois se separam 420 u. A recuperação e a separação impedem converter a disputa num forte garantido.
- **Empate** (tempo acabou com vantagem menor que 1): só separa. Se o tempo acabar com vantagem de 1 ou mais, quem lidera vence.
- O dano da derrota na disputa (8) é fixo, não escala com Lâmina, e pode causar o K.O. (finalização de braço).
- A disputa suspende ações, movimento, regeneração, efeitos de status e recargas dos participantes.
- **Acessibilidade**: a opção "Segurar para disputar" permite segurar o rápido; conta 6 pressões por segundo, abaixo do teto, para incluir quem não pode apertar repetidamente sem empatar com quem aperta.
- A IA só começa a pressionar depois de um tempo de reação (Fácil 0,6 s, Normal 0,45 s, Difícil e chefe 0,3 s).

### Habilidades e traços: valores iniciais

Os personagens em [content/CHARACTERS.md](content/CHARACTERS.md) não fixavam números; estes são os valores iniciais da fase 4 (ajustados pela matriz de equilíbrio):

| Habilidade | Valores |
| --- | --- |
| Contraguarda (Guardião) | postura 0,35 s, recovery 0,4 s se nada vier, 10 de Vigor; atacante desequilibrado 0,3 s; resposta = contra-ataque |
| Ímpeto (Sombra, Sombra Desperta) | startup 0,2 s, avanço de 140 u, 20 de dano, 18 de Vigor, armadura contra 1 golpe (preparação e active) |
| Marreta (Bastião) | startup 0,55 s, 32 de dano, 30 de Vigor, armadura contra 2 golpes recebendo metade do dano, conta como forte |
| Zumbido (Vespa) | 240 u em 0,26 s, invulnerável por 0,2 s, atravessa, 16 de Vigor |
| Postura de Espera (Espelho) | postura 0,5 s, recovery 0,5 s, 20 de Vigor; efeito de parry perfeito e contra-ataque |
| Varredura (Haste, Soberano) | startup 0,42 s, alcance 190 u rente ao chão, 20 de dano, conta como forte, finalização de perna |
| Brasa Viva (Brasa) | postura 0,4 s, recovery 0,45 s, 14 de Vigor; resposta com startup 0,08 s e 13 de dano (o bônus de punição se soma) |
| Forja (Forja) | startup 0,28 s; segurar prende o golpe; nível a cada 0,3 s até 3; +35% de dano por nível; nível 3 quebra a guarda |
| Voo da Garça (Garça) | salto de 300 u/s para a frente e 1050 u/s para cima, 14 de Vigor; permite os aéreos |
| Roda Dupla (Ceifador) | startup 0,15 s, active 0,36 s, 20 de dano, acerta na frente e atrás (atrás não pode ser bloqueado) |
| Passo-reflexo (Eco, Predestinado) | 60 u em 0,14 s, invulnerável o passo todo, para trás sem direção, 8 de Vigor |
| Salto (Ancião) | salto de 240 u/s e 820 u/s; na descida, mergulho automático de 18 de dano |

- **Ponto doce** (Haste, Soberano): a distância entre os corpos no acerto dividida pelo alcance do golpe; de 2/3 para cima, ×1,5; até 1/4, ×0,6.
- **Pulo na parede**: encostado (até 6 u da parede) no ar, pular lança para o outro lado a 380 u/s. Uma vez por parede até tocar o chão.
- **Mergulho** (forte no ar da Garça e do Ancião): no active, a velocidade vertical vira 900 u/s para baixo.
- **Habilidade** entra na prioridade de entrada logo depois do empurrão. Só no chão; Habilidade com direção e no ar fica para as técnicas (fase 5).

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
| Tutorial e Treinos guiados | não | sim | — |
| Desafios | cada desafio define | sim | cada desafio define |
| Desafio de parry | não | não | — |
| Galeria de poderes | sim | — | sim |

## 10. Finalizações

- Um K.O. por **golpe de lâmina corpo a corpo** separa um membro do derrotado.
- O golpe decide o membro: **perna** no 3º rápido, forte de avanço, Giro, Avanço com corte e Varredura; **braço** nos demais (inclusive na disputa). A orientação decide o lado (pela frente, o membro da frente; pelas costas, o de trás).
- No K.O. que decide a partida (último round; em modos de um round, qualquer K.O.), **30%** de chance de a cabeça sair no lugar do membro.
- Golpe aéreo, lâmina arremessada, empurrão, poderes e dano periódico terminam num K.O. normal.
- Sempre estilizado: sem sangue, corte cauterizado em brasa, cabeça sem rosto visível. A opção Finalizações desliga o desenho sem mudar nenhum resultado; o replay mostra o mesmo corte.

## 11. Atributos

Seis atributos: **Vida, Vigor, Lâmina, Defesa, Agilidade, Fluxo**.

- Escala de **1 a 7** no elenco comum. Os secretos passam disso pelo **potencial**: Ancião até 8, Soberano até 9, Predestinado até 10.
- Nota 4 tem multiplicador 1; cada nota muda 8% (1 = 0,76; 7 = 1,24; 10 = 1,48).
- **Vida**: vida máxima. **Vigor**: máximo e regeneração. **Lâmina**: todos os danos de lâmina e um pequeno bônus na janela de parry perfeito. **Defesa**: custo da guarda, recuo no bloqueio e reserva antes da quebra (não reduz dano; custo e recuo são divididos pelo multiplicador; a reserva ainda não está implementada). **Agilidade**: caminhada, pulo, avanços e janela da esquiva de precisão. **Fluxo**: nível dos poderes.
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

A simulação emite eventos; efeitos, câmera, som, HUD, estatísticas e tutoriais reagem a eles: `attack_started`, `hit`, `block`, `guard_break`, `parry`, `perfect_parry`, `clash`, `technique_clash`, `blade_lock_started`, `blade_lock_pressed`, `blade_lock_ended`, `shove`, `dodge`, `evade_success`, `response`, `action_rejected`, `exhaustion`, `exhaustion_recovered`, `wound`, `feint`, `armor_absorbed`, `power_started`, `power_active`, `power_hit`, `power_blocked`, `power_resisted`, `power_absorbed`, `projectile_*`, `death`, `round_started`, `round_ended`.

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

- **Duelar**: escolha do lutador, do adversário (pode ser o mesmo) e da arena; dificuldade nas Opções. Conjunto de poderes **Base** ou **Personalizado** na seleção.
- **História**: campanha com protagonista criado pelo jogador. Ver [content/STORY.md](content/STORY.md).
- **Arcade**: escolha do lutador e até 6 adversários em rodízio pelo elenco, mais o **chefe**. Dificuldade crescente (2 no Fácil, 2 no Normal, o resto no Difícil). Arenas em rodízio. Perder permite tentar a mesma luta. **Chefe: Sombra Desperta**, no Difícil; abaixo de metade da vida **desperta**: mensagem "A SOMBRA DESPERTA", letterbox pulsando e a IA passa à dificuldade de chefe. Vencer mostra "ARCADE CONCLUÍDO" e registra o feito para aquele personagem.
- **Sobrevivência**: adversários em sequência até perder, um round cada. A vida não volta cheia: cada vitória devolve 30% da vida máxima. Dificuldade sobe (2 no Fácil, 3 no Normal, depois Difícil). A cada 5 vitórias, o chefe. Recorde salvo.
- **2 Jogadores** (local): cada jogador escolhe o lutador com os próprios controles; J1 escolhe a arena. Melhor de 3. Os dois podem pausar.

### Aprender

- **Tutorial**: contra o boneco, sem rounds e sem morte. Uma instrução por vez, com as teclas do preset ativo; cada passo termina quando o jogador faz a ação: andar → rápido (2) → sequência → forte → guarda (2) → aparar fortes (2) → contra-ataque → empurrão → quebra de guarda → ferimento → disputa de lâminas → habilidade. No fim oferece o desafio de parry.
- **Treinos guiados**: Esquiva em sequência (esquivar no instante, três seguidas, esquivar e punir), Exaustão e ferimento (exaurir-se, recuperar, quebrar a guarda do boneco, feri-lo), Disputa de lâminas (provocar e vencer três disputas).
- **Treino**: contra o boneco, sem limite de rounds. Comportamento do boneco (parado, guarda, atacando), gravação de até 10 s de comandos do jogador e reprodução no boneco em loop, hitboxes visíveis, **dados de quadro** do último golpe (ex.: `Forte · bloqueado · −0,30 s`; negativo = o oponente age primeiro), comandos dos dois na tela.
- **Desafio de parry**: 45 s contra o boneco, que só lança fortes em intervalos aleatórios. Parry vale 1 ponto, perfeito 2. Recorde salvo.
- **Controles**: tabela de ações e teclas atuais.

### Extras

- **Desafios**: duelos fixos de um round, com recorde de menor tempo:
  - *Salinas sem Fluxo*: Guardião contra Sombra, Salinas de Vidro, Difícil, sem Poderes. "Vença só com a lâmina."
  - *Tempestade no convés*: Vespa contra Soberano, Convés em Voo, Normal, com Poderes. "Sobreviva à Tempestade e vença."
  - *Último fôlego*: Bastião contra Forja, Cume Nevado, Normal, sem Poderes, começando com 35% de vida.
  - *Sob o eclipse*: Ceifador contra Espelho, Cidadela do Eclipse, Difícil, com Poderes. "Duas lâminas contra o reflexo, no escuro."
- **Galeria de poderes**: cena de duelo sem rounds para ver cada poder e técnica em cada tier, contra alvos diferentes (parado, em guarda, com Barreira, com Absorção, no ar, atacando com Raio), com repetição automática e troca de lançador.
- **Galeria da História**: encontros vencidos e finais alcançados, revistos com as falas; o que não foi visto aparece como `???`.

## 17. Progressão e desbloqueios

Progressão cosmética nos modos de duelo; nada muda os atributos do elenco.

- **Cores de lâmina**: cada personagem tem a cor padrão e duas alternativas. A **cor do Arcade** libera ao vencer o Arcade com ele; a **cor do desafio**, ao vencer um duelo contra a IA cumprindo o desafio do personagem (lista em [content/CHARACTERS.md](content/CHARACTERS.md)).
- **Trajes**: elenco com Original, Viajante (vencer o Arcade com o lutador) e Sentinela (concluir qualquer final da História). Secretos têm trajes próprios (ver CHARACTERS).
- **Personagens secretos**: liberados pela História (ver STORY) ou pelo segredo da abertura.
- **Segredos da tela de abertura** (sem pista na tela; janela de 2,5 s entre entradas):
  - *O Equilíbrio*: ← ← → → ↑ ↓ ↑ ↓ libera os três secretos e as duas variantes do Predestinado, com som grave e a frase "O EQUILÍBRIO DESPERTA".
  - *O Guarda-roupa*: ↓ ↓ ↑ ↑ → ← → ←, ou cinco toques na frase abaixo do título, libera todos os trajes e cores, com um arpejo claro e a frase "TODOS OS TRAJES REVELADOS".
- Tudo salvo localmente.

## 18. Opções

Idioma (Português/English), dificuldade, efeitos (Completos/Reduzidos), som, música, preset de teclado e remapeamento, replay do golpe final, finalizações, Poderes, segurar para disputar (por jogador), vibração do gamepad. Configurações de vídeo (resolução, tela cheia, V-Sync) e volumes separados.

## 19. Fora do escopo inicial

Online, torneio, editor de personagens, perigos de arena que afetam o combate. A arquitetura deixa espaço para eles (simulação determinística, arena que reage a eventos).
