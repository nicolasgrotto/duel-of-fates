# Duel of Fates

Jogo de duelo de lâminas de energia em visão lateral, feito na **Godot 4.7** com **GDScript**. Duelos rápidos, acrobáticos e coreografados, inspirados nos duelos de sabre da trilogia prequel de Star Wars, com peso em cada golpe, leitura do oponente e poderes de uma energia chamada **Fluxo**.

> **Aviso legal.** Projeto acadêmico e de portfólio, sem fins lucrativos. A inspiração vem da franquia Star Wars, de propriedade da Lucasfilm Ltd. e da Walt Disney Company. Não é um produto oficial, não tem afiliação com elas e não usa nenhum nome, personagem, arte, música ou som oficial. Todo o conteúdo é original (ver [DESIGN.md](DESIGN.md#propriedade-intelectual)).

**[Jogar no navegador](https://nicolasgrotto.github.io/duel-of-fates/)** · [Releases](https://github.com/nicolasgrotto/duel-of-fates/releases)

## Situação

**Versão 1.0.0.** Duelo completo com o elenco inteiro, o Fluxo (poderes e técnicas), as dez arenas, a História com quatro finais, Duelar, Batalhas, Infiltração e Combate de naves, em português e inglês. O detalhe de cada entrega fica em [ROADMAP.md](ROADMAP.md).

**Branches:** o desenvolvimento acontece na `1.x`. A `main` recebe só o que está pronto para publicar: cada push nela atualiza o site, e cada tag `v*` cria uma release.

## O jogo em uma página

- **Duelo 1 contra 1** numa arena lateral, melhor de 3 rounds.
- **Combate de timing**: ataque rápido em sequência, ataque forte, bloqueio, **parry por timing** com contra-ataque, empurrão, esquiva, esquiva de precisão, pulo duplo, dash aéreo, choque de lâminas e **disputa de lâminas** cara a cara.
- **Consequências**: Vigor (stamina) que se esgota, exaustão, ferimentos de braço e perna e finalizações estilizadas no K.O.
- **O Fluxo**: 21 poderes em três categorias (Fluxo comum, Aurora e Eclipse) e 7 técnicas de lâmina, com potência definida pelo nível de Fluxo de cada lutador.
- **11 personagens**, um chefe e três secretos, cada um com estilo, habilidade, traço e IA próprios.
- **10 arenas** com identidade visual forte, em que as lâminas são a principal fonte de luz.
- **Modos**: História (protagonista criado pelo jogador, pontos de habilidade, árvores de Poderes e Lâmina, duas rotas e quatro finais), Duelar (1 Jogador, 2 Jogadores local e CPU vs CPU), Batalhas (Arcade, Sobrevivência, Caçada a chefes com três missões de fases e condições especiais), Modos especiais (Operações: seis missões de Infiltração; Combate de naves: cinco missões e oficina), Tutorial, Treinos guiados, Desafio de parry, Treino, Desafios e Galerias.
- Português e inglês, teclado e gamepad.
- **Operações** em Jogar › Modos especiais: seis missões de Infiltração com resgate em visão superior, furtividade, sete tipos de inimigo, prisioneiros que precisam ser protegidos e personagem à escolha. Controles compartilhados com as futuras Incursões: `WASD` move, `Shift` corre, `Ctrl/C` anda furtivamente, `Espaço` esquiva, `E` interage, `F` corta ou abate, `R` lança poder, mouse mira, botão esquerdo dispara com blaster ou corta sem ele, botão direito/`Q` defende. Na Infiltração, esquiva e tiros fazem ruído e poderes têm recarga tripla.

**Combate de naves:** Jogar › Modos especiais › Combate de naves. Seis missões, quatro naves no Hangar e oficina de melhorias. A/D giram, W propulsiona, S dá ré, J dispara, K lança o míssil e Shift inicia o impulso.

## Abrir o projeto

1. Instale a Godot 4.7 (versão padrão, GDScript).
2. Abra a Godot, escolha **Importar** e selecione `project.godot` desta pasta.

Controles padrão (J1): `A`/`D` ou setas para andar, `W`/`Espaço` pula, `J` rápido, `K` forte, `L` guarda (tocar apara), `L`+`J` empurrão, `I` habilidade, `Shift` esquiva, `S` esquiva de precisão, `Esc` pausa, `F3` debug. Na seleção: `←`/`→` cor da lâmina, `C` visual, `V` variante. No Treino: `F5` boneco, `F6` gravar, `F7` reproduzir.

Testes e simulador (ver [ARCHITECTURE.md](ARCHITECTURE.md#testes)):

```
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/simulate.gd -- --duels 100 --difficulty normal
godot --headless --path . --script res://tools/simulate.gd -- --matrix all --duels 10 --difficulty hard
```

Build Web (GitHub Pages), ver [ARCHITECTURE.md](ARCHITECTURE.md#exportação-web-github-pages):

```
godot --headless --path . --export-release "Web" build/web/index.html
python -m http.server 8000 --directory build/web
```

Depois abra `http://localhost:8000` no navegador. A build é sem threads e não precisa de cabeçalhos especiais.

Publicação: o workflow `.github/workflows/web.yml` (a cada push na `main` ou em Actions › Web build › Run workflow) importa, roda os testes, exporta e publica `build/web` no GitHub Pages. No repositório, ative Settings › Pages › Source: GitHub Actions.

Arte e áudio são gerados por ferramentas offline (Python 3 com numpy e Pillow): `python tools/art/paint_fighters.py` e `python tools/audio/synth_audio.py`. O jogo não depende delas.

## Documentação

| Arquivo | Conteúdo |
| --- | --- |
| [AGENTS.md.example](AGENTS.md.example) | Modelo das regras para agentes de código; copie para `AGENTS.md` (local, fora do git) e personalize |
| [DESIGN.md](DESIGN.md) | Briefing: conceito, pilares, sensação, o que não fazer, identidade |
| [GAME_DESIGN.md](GAME_DESIGN.md) | Regras de gameplay, números de calibração, IA, modos e progressão |
| [content/CHARACTERS.md](content/CHARACTERS.md) | Elenco: estilo, atributos, golpes, habilidades, poderes, visual |
| [content/POWERS.md](content/POWERS.md) | O Fluxo: níveis, interações, poderes e técnicas de lâmina |
| [content/STORY.md](content/STORY.md) | Mundo, campanha, rotas, diálogos (PT-BR e EN) e finais |
| [content/ARENAS.md](content/ARENAS.md) | As arenas e suas assinaturas visuais |
| [content/INFILTRATION.md](content/INFILTRATION.md) | Missões, escolta, extração e bônus da Infiltração |
| [content/BLASTER_OPS.md](content/BLASTER_OPS.md) | Núcleo de tiro superior, calor, esquiva, poderes e treino técnico de Operações de blaster |
| [content/HUNTS.md](content/HUNTS.md) | As três caçadas, recompensas e falas nos dois idiomas |
| [design/ART_DIRECTION.md](design/ART_DIRECTION.md) | Identidade visual, personagens, lâminas, luz e animação |
| [design/VFX.md](design/VFX.md) | Efeitos, impacto, câmera lenta e efeitos dos poderes |
| [design/UI_UX.md](design/UI_UX.md) | HUD, menus, telas, idiomas e acessibilidade |
| [design/AUDIO.md](design/AUDIO.md) | Som das lâminas, efeitos, música dinâmica |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Organização do projeto Godot |
| [ROADMAP.md](ROADMAP.md) | Fases de construção e ponto de continuidade |
| [PLAYTEST.md](PLAYTEST.md) | Roteiro de validação jogando: o que testar, o que esperar e onde ajustar |
| [ASSETS.md](ASSETS.md) | Origem e licença de cada asset |
