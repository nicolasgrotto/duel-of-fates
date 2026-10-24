# UI / UX — Interface

Segue [ART_DIRECTION.md](ART_DIRECTION.md). Regras de jogo em [GAME_DESIGN.md](../GAME_DESIGN.md).

## Princípios

- **Minimalista**: só o que o jogador precisa agora.
- **Cinematográfica**: muito espaço vazio, texto centralizado, letras espaçadas nos títulos, transições suaves (fades curtos, letterbox).
- **Legível**: contraste alto, texto de dica com no mínimo ~18 px em 720p.
- **Pouco intrusiva**: durante o duelo, a UI fica nas bordas e nunca cobre a área de luta. HUD com no máximo ~10% da altura da tela.
- **Uma fonte**: Oxanium. As setas das dicas (← ↑ → ↓), que a Oxanium não tem, vêm de `DuelArrows`, fallback mínimo desenhado no traço e nas medidas dela (não é uma segunda família: só quatro glifos). Cores do tema: fundo `#05070d`, texto `#e8ecf5`, secundário `#8a94ab`, destaque `#9fb4d9`, perigo `#e5484d`, Aurora `#5aa2ff`, Eclipse `#ff4458`.
- **Sem números de dano** na tela. Números ficam no debug (F3).

## Idiomas

Português (padrão) e inglês, escolhidos nas Opções e salvos. Todo texto de tela vem das tabelas de tradução por chave, com marcadores (`{name}`, `{light}`). Frase nova entra nos dois idiomas no mesmo commit; o inglês não pode cortar rodapés, listas ou linhas da HUD. Glossário em [DESIGN.md](../DESIGN.md#identidade).

## Navegação

- Listas verticais e centralizadas. Cima/baixo mudam a opção; a lista dá a volta. Confirmar entra; voltar sai.
- Opção selecionada: cor de texto principal com um traço curto de destaque à esquerda; as outras em cor secundária.
- Teclado, gamepad e mouse navegam igual. Dicas de controle no rodapé no formato `Tecla  ação`, separadas por `·`, sempre geradas a partir dos bindings atuais e do tipo de controle em uso (ícones do gamepad quando for o caso).
- O menu lembra de onde o jogador saiu.

## Telas

### Abertura

Fundo preto; uma lâmina horizontal acende do centro para as pontas (ciano-gelo), com núcleo branco e glow; o título **DUEL OF FATES** e a frase **UM DUELO DE LÂMINAS DE ENERGIA** entram em fade; depois "Pressione Enter" piscando devagar. Confirmar pula a animação. Direcionais não pulam nada: ali se digitam os segredos. Ao revelar um segredo, um brilho grande vermelho-Ápice atrás da lâmina e a frase do segredo por ~3 s.

> Implementada na fase 6 (`screens/opening/`, cena inicial do projeto): a lâmina em pixel art na mesma grade do emblema do menu, título e frase abaixo dela, segredos com janela de 2,5 s entre entradas e cinco cliques na frase para o Guarda-roupa.

### Menu

> Implementado na fase 6 com os dois níveis: raiz Jogar, Aprender, Extras, Opções e Sair; cada grupo lista só o que já existe (hoje Jogar › Duelar, Aprender › Treino, Extras › Galeria de poderes) e termina em Voltar. A Dificuldade foi para as Opções. O menu lembra o grupo e a opção de onde o jogador saiu. Na build Web não existe Sair: fechar o jogo congelaria a página, e a aba do navegador já cumpre esse papel.

**Visual final (decidido na segunda etapa da pixel art, explorado no Claude Design entre três direções: emblema, choque no horizonte e letterbox):** o **emblema das lâminas cruzadas**. Ao fundo, acima do título, duas lâminas em X (ciano-gelo `#7fe4ff` e âmbar `#ffb34a`, cores sem moral, do `UiPalette`) com os cabos nas pontas de baixo, desenhadas em **pixel art na mesma grade do mundo** e ampliadas sem suavização; no cruzamento, uma estrela de faíscas de 4 pontas que pulsa, e faíscas soltas que caem de vez em quando. Ao abrir o menu, as lâminas acendem do cabo à ponta (como a ignição do round) e o cruzamento dá um clarão curto. O glow tremula de leve, como o zumbido. Duas linhas finas de horizonte (a plataforma) cruzam a tela abaixo do emblema, e poeira fina sobe devagar. Título, frase e lista ficam em alta resolução (Oxanium), centralizados sob o cruzamento: título com letras bem espaçadas, frase no destaque, lista com o traço curto de destaque à esquerda da opção selecionada. Nada de painéis, molduras ou botões: o emblema é a única imagem. No menu principal cada linha da lista é centralizada (com um espaço à direita do tamanho do traço, para o traço não empurrar o texto); nas listas das outras telas o texto continua alinhado à esquerda do bloco.

Título centralizado, maiúsculas espaçadas, frase de apoio em destaque. Dois níveis na mesma tela: **Jogar** (Duelar, História, Arcade, Sobrevivência, 2 Jogadores), **Aprender** (Tutorial, Treinos guiados, Treino, Desafio de parry, Controles), **Extras** (Desafios, Galeria de poderes, Galeria da História), **Opções**. O nome do grupo aparece entre a frase e a lista; Voltar ou `Esc` volta à raiz.

### Seleção de personagem

> Implementada na fase 4 (`screens/select/`): lista com Aleatório e os secretos no fim, coluna central com estilo, caminho na cor do lado, traço, habilidade e as seis barras (potencial em dourado `#d9b45a`), lutador animado à direita com Visual, Lâmina e Variante. ← → trocam a cor da lâmina, `C` troca o visual, `V` a variante. Na fase 5 entraram as linhas de **Poderes** e técnicas, `Conjunto: Base/Personalizado` e o editor de poderes (`P`): três linhas `‹ Poder ›`, Voltar ao conjunto base e Pronto; Voltar ou `P` fecham. A Galeria de poderes segue a descrição abaixo, com o painel no topo e a barra de Fluxo só de quem lança. Bloqueio real (fase 6): os secretos só entram na lista depois de liberados; ← → e `C` percorrem só cores e visuais liberados; a linha "Libera:" mostra o próximo requisito pendente (traje ou cor). Avisos de desbloqueio aparecem no resultado em dourado. Ainda falta a miniatura da arena.

Três colunas:

- **Esquerda**: lista de lutadores, começando com **Aleatório**; rola com setas quando passa do espaço. Secretos liberados no fim.
- **Centro**: estilo, caminho (na cor do lado), traço, habilidade, título **Poderes** com uma linha por espaço (`Poder · Repulsão`, `Frente + Poder · Cura`, `Trás + Poder · Barreira`, `Poder + Habilidade · …`), uma linha por técnica, `Conjunto: Base/Personalizado`, e as seis barras de atributo (segmentos cheios em destaque; segmentos de potencial dos secretos em dourado).
- **Direita**: o personagem em guarda com a lâmina acesa, numa pose de apresentação; abaixo, **Variante** (Predestinado), **Visual** e o requisito pendente, **Lâmina** (`Lâmina: Nome (n/3)`) e o próximo desafio bloqueado.
- Esquerda/direita trocam a cor da lâmina; botões dedicados trocam o visual e a variante.
- **Editor de poderes** (Duelar, 2 Jogadores, Treino): substitui a coluna central; uma linha por espaço, esquerda/direita percorrem o catálogo permitido, escolher um poder que já está em outro espaço troca os dois.
- Duelar segue: **ESCOLHA SEU LUTADOR → ESCOLHA O ADVERSÁRIO → ESCOLHA A ARENA** (arena com frase e miniatura). Voltar recua uma etapa. Cada modo lembra a última escolha.
- 2 Jogadores: "JOGADOR 1 · ESCOLHA" e "JOGADOR 2 · ESCOLHA", cada um com seus controles.

> 2 Jogadores implementado na fase 6: Jogar › 2 Jogadores, seleção em três passos (J1, J2, arena) navegada pelos controles de menu, HUD `J1 · Nome` e `J2 · Nome`, resultado **JOGADOR N VENCE**.

### HUD do duelo

```
NOME ESQUERDA                                          NOME DIREITA
████████████░░░░░░                          ░░░░░░████████████   vida
▬▬▬▬▬▬▬▬▬▬                                          ▬▬▬▬▬▬▬▬▬▬   Vigor
───────                                                ───────   Fluxo
■ □                                                          □ ■ rounds
```

- Barras finas no topo, espelhadas; a parte cheia presa à borda da tela, esvaziando para o centro.
- **Vida**: cor clara neutra; abaixo de 25% vira vermelho de perigo e **pisca devagar** (não depende só da cor). Dano recente fica como barra fantasma que encolhe depois de um atraso.
- **Vigor**: barra mais fina, na cor de destaque `#9fb4d9`. Ação recusada: a barra fica vermelha e pisca ~0,3 s. **Exausto**: a parte cheia fica num vermelho apagado (`#7a2a2e`) com contorno, pulsando devagar.
- Medidas em 1080p: barras com 36% da largura da tela e margem lateral de 56 px; vida com 10 px de altura, Vigor com 5 px; fundo das barras no texto principal a 10% de opacidade, barra fantasma a 35%. Tudo ocupa menos de 10% da altura.
- **Fluxo** (com Poderes): barra ainda mais fina, na cor do lado (Aurora azul, Eclipse vermelho). Poder recusado pisca a barra. **Marcas de custo alto**: traço fino no ponto do custo de cada poder caro equipado, apagado até dar para lançar, aceso na cor própria do poder com um pulso único ao acender — Tempestade âmbar `#ffd76a`, Repulsão Suprema água `#7ff0e0`, Fratura lima `#a6ff6a`, Telecinese em Massa laranja `#ff9a4a`, Santuário marfim `#f4f1d0`, Ira laranja forte `#ff8c1a`.
- **Ferimento**: marca curta ao lado do nome ("Braço ferido" / "Perna ferida") em vermelho.
- **Rounds**: quadrados pequenos, cheios para rounds vencidos.
- Centro da tela vazio, exceto mensagens curtas: **ROUND 1 / ROUND 2 / ROUND FINAL**, **K.O.**, "A SOMBRA DESPERTA" (até 1,5 s).
- Faixa do modo no topo quando há (Arcade `ARCADE · LUTA 2 DE 7 · BASTIÃO`, Sobrevivência `SOBREVIVÊNCIA · VITÓRIAS 3 · RECORDE 7`, História `CAPÍTULO N · TÍTULO`, Desafios com o tempo). Implementada na fase 6 para Arcade e Sobrevivência.
- 2 Jogadores: "J1 · Nome" e "J2 · Nome".
- Rodapé discreto com a dica de pausa.

### Pausa

Overlay escuro sobre o duelo congelado. **PAUSADO**: Continuar, Lista de golpes (no 2 Jogadores, uma por jogador), Reiniciar duelo, Sair para o menu.

### Lista de golpes

Tela opaca, título `GOLPES · NOME`. Duas colunas: comando (do preset ativo) e descrição. Inclui a sequência de rápidos (com o tamanho do personagem), forte, forte de avanço, aéreo, aparar, contra-ataque, empurrão, esquiva, esquiva de precisão, disputa, habilidade, traço passivo, cada poder do conjunto (marcando os segurados) e cada técnica.

### Resultado

Por cima do duelo congelado, depois do K.O. e da queda (e do replay). Título **VITÓRIA** / **DERROTA** (ou "JOGADOR 1 VENCE"), frase "<nome> venceu o duelo", duração, tabela comparativa (golpes acertados, dano causado, defesas, parries, parries perfeitos, quebras de guarda, empurrões, maior sequência) com o nome de cada lutador no topo da coluna. Avisos de desbloqueio (cor, traje, personagem) em destaque. Opções conforme o modo: Revanche / Menu principal; Próxima luta / Tentar de novo; Próximo adversário.

### Replay

Tela cheia sem HUD, letterbox fechado, "REPLAY" à esquerda na barra de baixo e a dica de pular à direita.

### História

- **Hub** `HISTÓRIA`: menu à esquerda (Continuar · Capítulo N: título, Evoluir atributos / Ver atributos, Poderes, Nova/Recomeçar campanha, Voltar); à direita, nome, caminho, estilo, poderes, atributos e o protagonista em guarda. Linha de status (dificuldade e duelos vencidos, ou "Campanha concluída").
- **Novo duelista**: mesma composição; o subtítulo mostra o passo (`2/6 · Caminho do Fluxo`) e a prévia muda com a opção destacada. Campo de texto para o nome digitado.
- **Atributos**: lista centralizada com as seis notas (`Vida · 3`) e Pronto; subtítulo com pontos livres e total (`Pontos livres: 4 · total 22`); aviso fixo "Pontos investidos são definitivos" na cor de perigo. Sem pontos ou com a nota em 7, o som de recusa. Logo depois da criação, a tela abre para distribuir os pontos iniciais.
- **Poderes**: uma linha por espaço (`Poder · ‹ Repulsão ›`, `Trás + Poder · fechado · abre no capítulo 6`); ← → ou Enter trocam o poder sem repetir; descrição e custo do poder destacado embaixo.
- **Diálogo**: arena do encontro ao fundo, escurecida, com os dois duelistas; título do capítulo no alto; faixa escura embaixo com o nome de quem fala (destaque, espaçado) e a fala, com fade a cada linha. Narração sem nome.
- **Final**: barras de letterbox, título do final em destaque e as falas do narrador surgindo uma a uma (1,6 s); confirmar adianta e depois volta ao hub.

### Treino, Tutorial e desafios

- **Treino (fases 1 e 2)**: teclas de ferramenta F5 (comportamento do boneco: parado, em guarda, atacando, reproduzindo), F6 (gravar até 10 s dos comandos do jogador), F7 (reproduzir a gravação no boneco em loop) e F3 (caixas e estado). O rodapé mostra os comandos dos dois, os dados de quadro do último golpe do jogador (`Forte · bloqueado · −0,30 s`), o comportamento do boneco e o estado da gravação.

- **Tutorial / treinos guiados**: uma instrução no topo, abaixo das barras, com as teclas do preset ativo, e o progresso embaixo (`Passo 3 de 12 · 1 / 2`). Sem quadrados de round.
- **Desafio de parry**: tempo restante e pontos no topo.
- **Treino**: linha de rodapé com os comandos do jogador e do boneco, os dados de quadro do último golpe e o estado da gravação.
- **Fim**: título, uma frase e um resumo em uma linha; a primeira opção leva ao próximo passo.

### Listas (Treinos guiados, Desafios, Galeria da História)

Título no alto, lista à esquerda, detalhe à direita (nome e até seis linhas). Desafios mostram o recorde. Itens não vistos da galeria aparecem como `???` com a dica de onde se liberam, sem nomes. A Galeria da História tem duas colunas: encontros (`1 · O Teste`, `5A`, `9E` para os secretos) e finais; ← → troca de coluna e a dica fica sob os finais.

### Galeria de poderes

Cena de duelo sem rounds nem barras de vida; só o medidor de Fluxo de quem lança. Painel no topo: nome do poder entre `‹ ›` (na cor do lado), descrição curta, linha do lado ("Aurora · lado da luz"), tier, alvo e repetição; tiers como quatro chips sublinhados na cor do tier. Comandos no rodapé.

### Opções

Idioma, dificuldade, efeitos, som, música, volumes, teclado (preset e Configurar teclas), Poderes, replay do golpe final, finalizações, segurar para disputar (J1 e J2), vibração, vídeo. Valores salvos.

> Implementada na fase 6 (`screens/options/`): título OPÇÕES, lista centralizada `Opção · valor` (← → ajustam, Confirmar avança, Voltar ou `Esc` voltam ao menu), com Idioma, Dificuldade, Efeitos, Replay do golpe final, Finalizações, Poderes, Segurar para disputar J1 e J2, Volume geral, Música, Efeitos sonoros (passos de 10%), Tela cheia e V-Sync (fora da Web). Tudo aplica na hora e é salvo. Faltam o teclado (Configurar teclas) e a vibração, que entram com o remapeamento.

### Configurar teclas

Lista "Ação: teclas", Restaurar padrão, Voltar. Confirmar escolhe a ação e pede a nova tecla; tecla repetida troca de lugar; teclas reservadas avisam. Qualquer mudança ativa o preset Personalizado.

> Implementada na fase 6 (`screens/controls/key_config_screen.gd`), para o teclado do J1: linhas `Ação · teclas` (a nova tecla vira a principal e as secundárias ficam), `Esc` cancela a espera, Enter, `Esc` e F3/F5/F6/F7 são reservadas (aviso em vermelho de perigo). Presets nas Opções: Padrão, Setas (setas + `Z X C V`, habilidade `A`, poder `S`) e Personalizado (só aparece depois de uma troca). Gamepad e teclado do J2 ficam com o modo 2 Jogadores.

### Controles

Tabela de duas colunas (ação e teclas atuais). Combinações com `+`; ações que usam a mesma tecla de outro jeito (aparar = tocar a guarda) em linha própria.

> Implementada na fase 6 (`screens/controls/controls_screen.gd`, em Aprender › Controles), lida do InputMap atual: ações à direita alinhadas em cor secundária, teclas à esquerda em cor principal, com Aparar (tocar), Empurrão, Técnicas e Outros poderes (frente ou trás +), Quarto poder.

## Acessibilidade

- Não depender só de cor: vida baixa pisca; o desequilíbrio aparece na lâmina e na pose.
- **Efeitos reduzidos** (ver VFX).
- **Segurar para disputar** na disputa de lâminas.
- Remapeamento completo de teclado e gamepad.
- Legendas sempre ativas nas falas (o jogo é todo em texto; se houver voz, legendas continuam).

## Toque (futuro)

Se houver versão para celular: joystick flutuante à esquerda, seis botões circulares à direita (habilidade, forte, pulo, esquiva, guarda, rápido) mais Poder, arrastar para baixo para a esquiva de precisão, botão contextual "Poder 4" só para quem tem quarto poder. Botões discretos (fundo escuro translúcido, borda de destaque), sem cores novas nem glow. Em retrato, pedir para girar o aparelho.

## Não fazer

- Botões coloridos, gradientes chamativos, ícones cartunescos.
- Barras grossas ou HUD cobrindo a luta.
- Mais de uma fonte.
- Texto escrito no código.
