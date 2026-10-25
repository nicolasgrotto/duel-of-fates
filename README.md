# Duel of Fates

Jogo de duelo de lâminas de energia em visão lateral, feito na **Godot 4.7** com **GDScript**. Duelos rápidos, acrobáticos e coreografados, inspirados nos duelos de sabre da trilogia prequel de Star Wars, com peso em cada golpe, leitura do oponente e poderes de uma energia chamada **Fluxo**.

> **Aviso legal.** Projeto acadêmico e de portfólio, sem fins lucrativos. A inspiração vem da franquia Star Wars, de propriedade da Lucasfilm Ltd. e da Walt Disney Company. Não é um produto oficial, não tem afiliação com elas e não usa nenhum nome, personagem, arte, música ou som oficial. Todo o conteúdo é original (ver [DESIGN.md](DESIGN.md#propriedade-intelectual)).

## Situação

Fases 0 a 7.5 concluídas, na branch `pixel-art`: duelo completo com o elenco inteiro, o Fluxo (poderes e técnicas), as dez arenas, todos os modos, a História com quatro finais, a revisão de combate e animação (Esquiva com giro, Pressão de lâminas, Desengajamento) e, da fase 8, ambiências e temas por arena, remapeamento do gamepad e a revisão do inglês. Agora é a fase de acabamento e de validação jogando: o roteiro está em [PLAYTEST.md](PLAYTEST.md). Detalhes em [ROADMAP.md](ROADMAP.md).

## O jogo em uma página

- **Duelo 1 contra 1** numa arena lateral, melhor de 3 rounds.
- **Combate de timing**: ataque rápido em sequência, ataque forte, bloqueio, **parry por timing** com contra-ataque, empurrão, esquiva, esquiva de precisão, pulo duplo, dash aéreo, choque de lâminas e **disputa de lâminas** cara a cara.
- **Consequências**: Vigor (stamina) que se esgota, exaustão, ferimentos de braço e perna e finalizações estilizadas no K.O.
- **O Fluxo**: 20 poderes em três categorias (Fluxo comum, Aurora e Eclipse) e 7 técnicas de lâmina, com potência definida pelo nível de Fluxo de cada lutador.
- **11 personagens**, um chefe e três secretos, cada um com estilo, habilidade, traço e IA próprios.
- **10 arenas** com identidade visual forte, em que as lâminas são a principal fonte de luz.
- **Modos**: História (protagonista criado pelo jogador, pontos de habilidade, árvores de Poderes e Lâmina, duas rotas e quatro finais), Duelar, Arcade, Sobrevivência, 2 Jogadores local, Tutorial, Treinos guiados, Desafio de parry, Treino, Desafios e Galerias.
- Português e inglês, teclado e gamepad.

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

Publicação: o workflow `.github/workflows/web.yml` (disparo manual em Actions › Web build › Run workflow) importa, roda os testes, exporta e publica `build/web` no GitHub Pages. No repositório, ative Settings › Pages › Source: GitHub Actions.

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
| [design/ART_DIRECTION.md](design/ART_DIRECTION.md) | Identidade visual, personagens, lâminas, luz e animação |
| [design/VFX.md](design/VFX.md) | Efeitos, impacto, câmera lenta e efeitos dos poderes |
| [design/UI_UX.md](design/UI_UX.md) | HUD, menus, telas, idiomas e acessibilidade |
| [design/AUDIO.md](design/AUDIO.md) | Som das lâminas, efeitos, música dinâmica |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Organização do projeto Godot |
| [ROADMAP.md](ROADMAP.md) | Fases de construção e ponto de continuidade |
| [PLAYTEST.md](PLAYTEST.md) | Roteiro de validação jogando: o que testar, o que esperar e onde ajustar |
| [ASSETS.md](ASSETS.md) | Origem e licença de cada asset |
