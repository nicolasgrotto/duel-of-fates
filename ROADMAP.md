# ROADMAP

Ordem de construção do jogo. Cada fase termina jogável e testada. Marque `[x]` ao concluir e atualize o ponto de continuidade.

## Ponto de continuidade

- **Fase atual**: migração para pixel art (branch `pixel-art`). Fases 0 a 5 concluídas.
- **Próximo passo**: grade de pixels do mundo e prova de conceito com o Guardião; depois a fase 6 já em pixel art.
- **Pendências conhecidas**:
  - Equilíbrio com Poderes: no Normal, Guardião 63% contra Sombra 37% (100 duelos), rounds de ~10,5 s; o Raio responde por boa parte dos acertos. Rodar a matriz com Poderes e ajustar custos, `power_chance` da IA e o Raio.
  - Efeitos de poder simplificados em relação à VFX.md: sem poeira, sem o asteroide da Telecinese em Massa (só a chuva sobre as marcas), sem pedras subindo do chão na preparação do Arremesso e sem fragmentos no impacto.
  - A IA não usa o Truque Mental de forma tática (lança quando está ao alcance) e não guarda medidor para o quarto poder.
  - Equilíbrio do elenco pela matriz (10 duelos por par, lados alternados): no Difícil, todos entre 38% e 65%; no Normal, entre 33% e 62%. Os personagens defensivos (Guardião, Espelho) rendem mais no Difícil, porque dependem da defesa reativa da IA. Rounds de ~10–11 s (alvo ~15 s).
  - Trajes, cores e secretos selecionáveis sem bloqueio até os saves da fase 6.
  - A IA quase não usa o empurrão contra IA (o oponente raramente fica parado em guarda); revisar junto com o equilíbrio.
  - Reserva de Defesa antes da quebra de guarda (GAME_DESIGN, seção 11) ainda não implementada.
  - Preset de teclado de 2 jogadores e tela de Opções (inclui "segurar para disputar", hoje só no arquivo de configurações) na fase 6.
  - Mudar `application/config/name` desloca a pasta `user://`: depois disso o editor precisa ser reaberto para o addon MCP voltar a autenticar o runtime.

## Fase 0 — Fundação

- [x] Inicializar o repositório git com `.gitignore` da Godot
- [x] Addon de MCP para os agentes (Godot MCP Toolkit) e `.mcp.json`
- [x] Decisão: testes automatizados com executor próprio mínimo
- [x] Executor de testes `tools/run_tests.gd` rodando headless
- [x] Estrutura de pastas de ARCHITECTURE.md
- [x] Resolução base 1920×1080, janela e escala
- [x] Autoloads vazios só quando forem usados: `Settings`, `SceneRouter`
- [x] InputMap com as ações de GAME_DESIGN (P1 e P2, teclado e gamepad)
- [x] Fonte Oxanium registrada em ASSETS.md e tema base da UI
- [x] Verificação técnica: glow/HDR 2D, luzes 2D com mapa de normal, reflexos no renderer Compatibility (glow em LDR e `PointLight2D` verificados; mapa de normal e reflexo com o protótipo de arte da fase 3)

## Fase 1 — O duelo mínimo

Arte provisória (formas simples), sensação final.

- [x] `MatchSimulation` com tick fixo, `FighterState`, `Intent`, `PlayerController`
- [x] Movimento: caminhada, aceleração, pulo, pulo duplo, colisão de corpos, paredes
- [x] Rápido (com sequência), forte, guarda, parry e parry perfeito, contra-ataque
- [x] Vida, Vigor, ação recusada, quebra de guarda
- [x] Hit stop, câmera de enquadramento, HUD mínima, rounds e K.O.
- [x] Debug F3 com hitboxes
- [x] Testes de regra e de determinismo

## Fase 2 — Combate completo

- [x] Empurrão, esquiva, esquiva de precisão, dash aéreo, forte de avanço, golpe aéreo
- [x] Choque de lâminas, disputa de lâminas (com "segurar para disputar")
- [x] Exaustão, ferimentos, finalizações (lógica)
- [x] IA: pensamento, prioridades, perfis, dificuldades, memória de hábitos
- [x] Boneco de treino, modo Treino com gravação e dados de quadro
- [x] Replay do golpe final por re-simulação
- [x] Simulador headless IA × IA

## Fase 3 — Pipeline de arte

- [x] Decisão: técnica de apresentação — 2D em alta definição com esqueleto e mapas de normal
- [x] Pipeline de arte (pintura, rig, formato das peças) fechado com o protótipo de um personagem
- [x] Guardião completo (família Guardião) e Sombra completa (família Agressor): modelo, todas as animações, lâmina, luz
- [x] Sincronia animação × simulação e validação lâmina × hitbox
- [x] Efeitos da VFX.md para o combate de lâmina, dessaturação do parry perfeito, letterbox, câmera lenta (faíscas, anel, flash, tremor, punch-in, letterbox e câmera lenta já existem em versão provisória)
- [x] Plataforma de Refino completa
- [x] Áudio das lâminas e do combate; primeira música dinâmica

## Fase 4 — Elenco

- [x] Dados e jogabilidade de cada personagem (traço, habilidade, sequência, IA)
- [x] Famílias de movimento restantes e arte de cada personagem
- [x] Seleção de personagem completa, cores de lâmina, trajes
- [x] Matriz de equilíbrio no simulador

## Fase 5 — O Fluxo

- [x] Medidor, tiers, recarga, comandos com direção, tabela de interação
- [x] Poderes do Fluxo comum, Aurora e Eclipse; técnicas de lâmina; choque entre técnicas
- [x] Quarto poder do Predestinado
- [x] Conjuntos personalizados e Galeria de poderes
- [x] IA com poderes

## Migração para pixel art (branch `pixel-art`)

Decisão do autor depois da fase 5: o jogo passa a ser pixel art sci-fi (ART_DIRECTION, "Técnica de apresentação"). A versão em alta definição fica na tag `phase-5-hd`; se o resultado não agradar, o desenvolvimento volta a partir dela. A simulação, as regras e os testes não mudam.

- [x] Grade de pixels do mundo (`PixelStage`): mundo renderizado em baixa resolução, zoom uniforme, câmera em pixels inteiros com deslize suave
- [ ] Prova de conceito: Guardião pintado na grade, golpe com rastro e impacto, Plataforma de Refino
- [x] Todos os lutadores pintados na grade; prévia da seleção na grade
- [x] Lâminas, rastros, faíscas, poderes e disputa ajustados à grade
- [ ] Arenas na grade
- [ ] Revisão de desempenho e testes

## Fase 6 — Arenas e modos

- [ ] As dez arenas e a Plataforma de Treino
- [ ] Menu completo, Opções, Configurar teclas, Controles
- [ ] Arcade (com o chefe), Sobrevivência, 2 Jogadores
- [ ] Tutorial, Treinos guiados, Desafio de parry, Desafios
- [ ] Desbloqueios, segredos da abertura, saves

## Fase 7 — História

- [ ] Criação do protagonista, hub, atributos, poderes
- [ ] Encontros, rotas, finais, diálogos
- [ ] Galeria da História
- [ ] Secretos liberados pela campanha

## Fase 8 — Acabamento

- [ ] Localização completa PT-BR e EN
- [ ] Trilha e ambiências de todas as arenas
- [ ] Acessibilidade (efeitos reduzidos, remapeamento, legendas)
- [ ] Desempenho medido e estável a 60 FPS
- [ ] Exportação e build de release

## Decisões tomadas

| Decisão | Resultado |
| --- | --- |
| Técnica de apresentação | pixel art com esqueleto: mundo numa grade de 1 px = 2 u, peças pintadas na grade com mapas de normal (antes: 2D em alta definição, tag `phase-5-hd`) |
| Testes | automatizados, executor mínimo próprio |
| Lâmina do Predestinado do Eclipse | vermelho do Ápice `#ff2b45` |
| InputMap | montado em tempo de execução por `Settings` a partir de `core/input_bindings.gd` (ARCHITECTURE) |
| Parry perfeito contra rápido | vale como parry comum (GAME_DESIGN, seção 7) |
| Glow no Compatibility | funciona em LDR com fundo Canvas; brilho principal nas camadas aditivas da lâmina |
| Pipeline de arte | peças pintadas proceduralmente (mapa de material + normal), recoloridas por traje; rig com `Skeleton2D` e IK |
| Reflexo das lâminas | desenho espelhado e achatado sobre o chão (sem cópia de tela) |
| Áudio | sintetizado offline, sem amostras; música em camadas sincronizadas |
| Habilidades | `AbilityData` com cinco tipos (golpe, postura, avanço, carga, salto) sobre os estados existentes |
| Variante do Predestinado | dois `CharacterData` ligados por `variant` |

## Decisões em aberto

| Decisão | Onde | Recomendação |
| --- | --- | --- |
| Voz gravada | AUDIO | fora do escopo inicial |
| Versão para toque | UI_UX | depois do lançamento no PC |
