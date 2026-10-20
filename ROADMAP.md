# ROADMAP

Ordem de construção do jogo. Cada fase termina jogável e testada. Marque `[x]` ao concluir e atualize o ponto de continuidade.

## Ponto de continuidade

- **Fase atual**: 0 — Fundação.
- **Próximo passo**: estrutura de pastas de ARCHITECTURE.md e o executor de testes próprio.

## Fase 0 — Fundação

- [x] Inicializar o repositório git com `.gitignore` da Godot
- [x] Addon de MCP para os agentes (Godot MCP Toolkit) e `.mcp.json`
- [x] Decisão: testes automatizados com executor próprio mínimo
- [ ] Executor de testes `tools/run_tests.gd` rodando headless
- [ ] Estrutura de pastas de ARCHITECTURE.md
- [ ] Resolução base 1920×1080, janela e escala
- [ ] Autoloads vazios só quando forem usados: `Settings`, `SceneRouter`
- [ ] InputMap com as ações de GAME_DESIGN (P1 e P2, teclado e gamepad)
- [ ] Fonte Oxanium registrada em ASSETS.md e tema base da UI
- [ ] Verificação técnica: glow/HDR 2D, luzes 2D com mapa de normal, reflexos no renderer Compatibility

## Fase 1 — O duelo mínimo

Arte provisória (formas simples), sensação final.

- [ ] `MatchSimulation` com tick fixo, `FighterState`, `Intent`, `PlayerController`
- [ ] Movimento: caminhada, aceleração, pulo, pulo duplo, colisão de corpos, paredes
- [ ] Rápido (com sequência), forte, guarda, parry e parry perfeito, contra-ataque
- [ ] Vida, Vigor, ação recusada, quebra de guarda
- [ ] Hit stop, câmera de enquadramento, HUD mínima, rounds e K.O.
- [ ] Debug F3 com hitboxes
- [ ] Testes de regra e de determinismo

## Fase 2 — Combate completo

- [ ] Empurrão, esquiva, esquiva de precisão, dash aéreo, forte de avanço, golpe aéreo
- [ ] Choque de lâminas, disputa de lâminas (com "segurar para disputar")
- [ ] Exaustão, ferimentos, finalizações (lógica)
- [ ] IA: pensamento, prioridades, perfis, dificuldades, memória de hábitos
- [ ] Boneco de treino, modo Treino com gravação e dados de quadro
- [ ] Replay do golpe final por re-simulação
- [ ] Simulador headless IA × IA

## Fase 3 — Pipeline de arte

- [x] Decisão: técnica de apresentação — 2D em alta definição com esqueleto e mapas de normal
- [ ] Pipeline de arte (pintura, rig, formato das peças) fechado com o protótipo de um personagem
- [ ] Guardião completo (família Guardião) e Sombra completa (família Agressor): modelo, todas as animações, lâmina, luz
- [ ] Sincronia animação × simulação e validação lâmina × hitbox
- [ ] Efeitos da VFX.md para o combate de lâmina, dessaturação do parry perfeito, letterbox, câmera lenta
- [ ] Plataforma de Refino completa
- [ ] Áudio das lâminas e do combate; primeira música dinâmica

## Fase 4 — Elenco

- [ ] Dados e jogabilidade de cada personagem (traço, habilidade, sequência, IA)
- [ ] Famílias de movimento restantes e arte de cada personagem
- [ ] Seleção de personagem completa, cores de lâmina, trajes
- [ ] Matriz de equilíbrio no simulador

## Fase 5 — O Fluxo

- [ ] Medidor, tiers, recarga, comandos com direção, tabela de interação
- [ ] Poderes do Fluxo comum, Aurora e Eclipse; técnicas de lâmina; choque entre técnicas
- [ ] Quarto poder do Predestinado
- [ ] Conjuntos personalizados e Galeria de poderes
- [ ] IA com poderes

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
| Técnica de apresentação | 2D em alta definição com esqueleto e mapas de normal |
| Testes | automatizados, executor mínimo próprio |
| Lâmina do Predestinado do Eclipse | vermelho do Ápice `#ff2b45` |

## Decisões em aberto

| Decisão | Onde | Recomendação |
| --- | --- | --- |
| Suporte a glow/HDR 2D no renderer | ARCHITECTURE | verificar na fase 0 |
| Voz gravada | AUDIO | fora do escopo inicial |
| Versão para toque | UI_UX | depois do lançamento no PC |
