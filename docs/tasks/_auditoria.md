# Auditoria visual e sonora

Estado do projeto em 2026-11-06, branch `1.2`. Lido no código e nos dados, não em suposição. Serve de base para todas as tasks desta pasta.

## Resolução e filtros

| Item | Estado atual | Onde |
| --- | --- | --- |
| Base do projeto | 1920×1080, `stretch canvas_items`, aspecto `expand` | `project.godot` |
| Janela padrão | 1280×720, encolhe para caber na tela | `project.godot`, `core/settings.gd` |
| Renderer | `gl_compatibility`, também na Web | `project.godot` |
| Mundo | `SubViewport` em grade, filtro nearest, snap de transformações e vértices | `presentation/camera/pixel_stage.gd` |
| Grade | **1 px = 2 u**, cerca de 480×270 no enquadramento neutro. O tamanho varia com a câmera | `EffectsConfig.units_per_pixel`, `PixelStage._process` |
| Ampliação | Não é inteira: cerca de 2,67× em 720p e 4× em 1080p. `pixel_upscale.gdshader` mantém os pixels iguais e suaviza só a borda | `presentation/camera/` |
| Câmera | Zoom **contínuo**: distância entre lutadores, recuo e punch-in | `presentation/camera/camera_rig.gd` |
| Interface | Alta resolução, Oxanium; `ART_DIRECTION` diz "só o mundo é pixel art" | `ui/theme/main_theme.tres` |

## Lutadores: não são spritesheets

**Este é o achado que mais afeta o plano.** Cada lutador é um esqueleto (`Skeleton2D`, IK de dois ossos, tecido com física) com peças pintadas por código, e a pose é **calculada** da simulação.

| Item | Estado atual |
| --- | --- |
| Altura em jogo | cerca de 75 px (150 u a 2 u/px) |
| Peças por lutador | 16 a 18, e 33 a 34 nos que têm variantes de rosto e cabelo; 716 PNGs no total, contando os mapas de normal |
| Tamanho das peças | tronco 16×27, antebraço 18×8, bota 11×6, capa 15×51, mão 6×5 |
| Formato | PNG de **material** (paleta por slot) + PNG `_n` de **normal**, compostos por `fighter_material.gdshader` e `palette_bake.gd` |
| Origem | `tools/art/fighter_specs.py`, `fighter_parts.py`, `paint_fighters.py`, `painter.py` |
| Pose | `pose_solver.gd` (1.553 linhas), `arm_geometry.gd`, `guard_tracker.gd`, `weapon_pose.gd`, dados por `MotionFamily` |

O que depende do rig, além da animação:

- Mãos presas ao cabo por IK, e a lâmina no mesmo ponto da colisão. `test_guard_tracking` exige que a guarda desenhada encontre o bloqueio real.
- Trajes: pelo menos três por lutador, a maioria por troca de paleta nos slots, e mais no Predestinado.
- Luz da lâmina no corpo, em tempo real, pelos mapas de normal.
- Peças cortadas, marcas de corte, corpo carbonizado e raio X nas execuções (`severed_piece.gd`, `cut_marks.gd`, `finisher_player.gd`).
- Reflexo, imagens residuais e silhueta (`fighter_reflection.gd`, `afterimages.gd`, `silhouette.gdshader`).
- Capas e cabelo com física (`cloth_strip.gd`), e o rosto e o cabelo escolhidos na História.

`ART_DIRECTION.md` registra a decisão: sprites quadro a quadro foram **descartados** por "volume de arte enorme" e "perda da sincronia automática". Contradizer isso exige explicar e atualizar o documento, conforme `AGENTS.md`. Ver a decisão D1 em [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Lâminas

Já existe bem mais do que parece, então a task 02 é de **melhoria**, não de criação.

| Pedido | Estado atual | Onde |
| --- | --- | --- |
| Núcleo, cor, halo | 4 polígonos: externo 7 px (alfa 0,16), glow 5, interno 3 (alfa 0,78), núcleo 1,5 px | `blade_view.gd` |
| Rastro | Sim, em faixas de opacidade, até 24 pontos | `blade_trail.gd`, `slash_streak.gd` |
| Glow e HDR | Ambiente próprio, **mas desligado na Web** (`web_glow = false`, por desempenho) | `presentation/duel_environment.tres`, `screens/duel/duel_screen.gd`, `data/balance/effects_config.gd` |
| Luz colorida | Uma `PointLight2D` por lutador, com alcance menor na Web (`web_light_scale`) | `fighter_view.gd` |
| Flicker | Só no desequilíbrio; balanço discreto em guarda | `ART_DIRECTION`, "A lâmina" |
| Faíscas | Sim, por evento | `presentation/effects/effects_director.gd` |
| Punhos | 7 tipos em `WeaponData.Hilt`, desenhados por código | `hilt_view.gd` |

Problemas para a task 02: o alfa externo é baixo e **a Web, onde o jogo é publicado, não tem glow**, por isso a lâmina lê como linha fina no site; e `GRID := 2.0` está fixo em `blade_view.gd`.

## Menus

| Tela | Estado atual | Arquivos |
| --- | --- | --- |
| Abertura | Cena própria | `screens/opening/` |
| Menu principal | Coluna de texto em `MenuList`, `MenuEmblem` com lâminas cruzadas desenhadas por código | `screens/menu/` |
| Seleção | 470 linhas, `FighterPreview` com o rig ao vivo, `AttributeBars`, poderes em texto, `ArenaThumbnail`. **Sem retratos** | `screens/select/character_select.gd` |
| Operações e naves | Família tática **aprovada pelo autor na 1.1**: painéis, chips, teclas, mapa de setor | `ui/widgets/`, `screens/infiltration/`, `screens/space/` |
| Ícones de poder | 21 glifos de **24×24**, gerados por `make_power_icons.py` | `assets/ui/powers/` |

## Arenas

Doze arenas em `arenas/`, pintadas por `tools/art/make_arenas.py`, em camadas (`scenery_layer.gd`), com dados em `data/arenas/`. Regra atual: céus em faixas, sem degradê contínuo. Luz de cenário sempre mais fraca que a lâmina.

## Elenco

Caminhos e cores vêm dos dados. Detalhes nos briefs de [../art-briefs/](../art-briefs/).

| Lutador | Caminho | Família / arma | Lâminas (padrão, Arcade, desafio) |
| --- | --- | --- | --- |
| Guardião | Aurora | técnico, duas mãos | `#7fe4ff` `#5f8bff` `#3fffc8` |
| Sombra | Eclipse | agressiva | `#ff3f9e` `#c23cff` `#ff2a3a` |
| Bastião | Aurora | tanque | `#9dff3f` `#ffe08a` `#3fd0ff` |
| Vespa | Aurora | duas lâminas | `#ffd23f` `#7cff6b` `#ff6bd5` |
| Espelho | Aurora | defensivo | `#e8eeff` `#9fd8ff` `#ffe2b0` |
| Haste | Eclipse | lâmina em haste | `#a46bff` `#6b7cff` `#ff6bff` |
| Brasa | Eclipse | longa e curta | `#ff7a2a` `#ffcf3f` `#ff3f5a` |
| Forja | Eclipse | pesada, carga | `#ff4038` `#ff9a3f` `#b0ff3f` |
| Garça | Aurora | acrobática | `#5fffc0` `#a6e8ff` `#ff8a6b` |
| Ceifador | Eclipse | lâmina dupla | `#ff2a2a` `#ff7a2e` `#c43bff` |
| Eco | Eclipse | fintas | `#ffa6e0` `#c9a6ff` `#d6dbe6` |
| Corsária | Eclipse | lâmina e blaster | `#3f6bff` `#3fe0e0` `#ffb08a` |
| Lince | Aurora | lâmina e emissor | `#e0ff3f` `#ffe68a` `#8a7bff` |
| Soberano (secreto) | Eclipse | senhor do Fluxo | `#ff3040` e ouro-velho |
| Ancião (secreto) | Aurora | mestre | `#3fd07a` |
| Predestinado (secreto) | Aurora ou Eclipse | Fluxo 10 | `#6fb2ff`, variante `#ff2b45` |
| Sombra Desperta (chefe) | Eclipse | chefe | `#ff3f9e` |
| Coldre (estilo da História) | Aurora | lâmina e coldre | as do Guardião |
| Protagonista | escolhido | criado pelo jogador, reutiliza rigs | escolhida |

Poderes: 21 em `data/powers/`, cada um com ícone próprio. Cores de energia do Fluxo são por tier (`#9cc4ff` `#5d8dff` `#b26bff` `#ff2b45`), nunca da lâmina, e nenhuma cor de lâmina significa herói ou vilão.

## Áudio

| Item | Estado atual |
| --- | --- |
| Origem | Tudo sintetizado por `tools/audio/synth_audio.py`, sem amostras |
| Volume | 104 arquivos, 16 MB em WAV |
| Música | 3 conjuntos (duelo, chefe, sagrado), cada um com camadas `base`, `percussion`, `tension` em `MusicData` |
| Música adaptativa | **Já existe em camadas**; falta reagir a vida baixa e clímax, e faltam faixas de abertura, menu, seleção, vitória e derrota |
| Buses | Master, Music, Effects, Blades, Interface, Ambience; abafar no parry perfeito e no K.O. |
| Opções | Volumes Master, Música e Efeitos em `core/settings.gd` |
| Formato | WAV; `general/default_playback_type.web=0` |

## Restrições do projeto que valem para tudo

- Sem nome, logo, arte, som ou termo de franquia. A primeira versão da imagem de carregamento trazia um emblema de franquia e precisou ser limpa: **gerador de imagem reproduz símbolos de cor**, e isso precisa de checagem em toda entrega.
- Todo asset novo entra em `ASSETS.md` no mesmo commit, com licença compatível.
- Texto vive nas tabelas de tradução; imagem não leva texto. O jogo tem português e inglês.
- A simulação não muda por causa de arte. A matriz de duelos da IA tem de continuar idêntica.
- A Web é plataforma de validação: uma thread, renderer de compatibilidade.
