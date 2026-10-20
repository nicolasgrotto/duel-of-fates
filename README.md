# Duel of Fates

Jogo de duelo de lâminas de energia em visão lateral, feito na **Godot 4.7** com **GDScript**. Duelos rápidos, acrobáticos e coreografados, inspirados nos duelos de sabre da trilogia prequel de Star Wars, com peso em cada golpe, leitura do oponente e poderes de uma energia chamada **Fluxo**.

> **Aviso legal.** Projeto acadêmico e de portfólio, sem fins lucrativos. A inspiração vem da franquia Star Wars, de propriedade da Lucasfilm Ltd. e da Walt Disney Company. Não é um produto oficial, não tem afiliação com elas e não usa nenhum nome, personagem, arte, música ou som oficial. Todo o conteúdo é original (ver [DESIGN.md](DESIGN.md#propriedade-intelectual)).

## Situação

Fase de planejamento. A documentação abaixo descreve o jogo completo; a ordem de construção está em [ROADMAP.md](ROADMAP.md).

## O jogo em uma página

- **Duelo 1 contra 1** numa arena lateral, melhor de 3 rounds.
- **Combate de timing**: ataque rápido em sequência, ataque forte, bloqueio, **parry por timing** com contra-ataque, empurrão, esquiva, esquiva de precisão, pulo duplo, dash aéreo, choque de lâminas e **disputa de lâminas** cara a cara.
- **Consequências**: Vigor (stamina) que se esgota, exaustão, ferimentos de braço e perna e finalizações estilizadas no K.O.
- **O Fluxo**: 20 poderes em três categorias (Fluxo comum, Aurora e Eclipse) e 8 técnicas de lâmina, com potência definida pelo nível de Fluxo de cada lutador.
- **11 personagens**, um chefe e três secretos, cada um com estilo, habilidade, traço e IA próprios.
- **10 arenas** com identidade visual forte, em que as lâminas são a principal fonte de luz.
- **Modos**: História (protagonista criado pelo jogador, duas rotas e quatro finais), Duelar, Arcade, Sobrevivência, 2 Jogadores local, Tutorial, Treinos guiados, Desafio de parry, Treino, Desafios e Galerias.
- Português e inglês, teclado e gamepad.

## Abrir o projeto

1. Instale a Godot 4.7 (versão padrão, GDScript).
2. Abra a Godot, escolha **Importar** e selecione `project.godot` desta pasta.

Ferramentas de teste e de exportação entram na fase 0 do [ROADMAP.md](ROADMAP.md).

## Documentação

| Arquivo | Conteúdo |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Regras para agentes de código (Claude Code, Codex e outros) |
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
| [ASSETS.md](ASSETS.md) | Origem e licença de cada asset |
