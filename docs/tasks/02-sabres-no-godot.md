# Task 02: Sabres no Godot

**Quem executa:** Claude Code

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Fazer a lâmina ser a coisa mais impressionante da tela, sem arte externa.

## Contexto

A lâmina já tem camadas, rastro, faíscas e sete punhos (ver auditoria); ela lê como linha fina por largura e por alfa baixo. **Regras da simulação não mudam:** comprimento, hitbox e pose vêm dos dados. O renderer é de compatibilidade e a Web usa uma thread, então o orçamento de luz é apertado. Medir, não presumir.

## Entregáveis

- `BladeView` em 3 camadas definidas: núcleo branco, cor, halo aditivo com material `blend_add`.
- **Medição antes de adotar:** tempo de quadro com `web_glow` ligado e desligado, no duelo mais pesado, em 720p e 1080p, registrado em `docs/tasks/_glow-web.md`. Usar o Chrome do autor com GPU real e registrar a GPU em `chrome://gpu`: o Chrome da automação pode renderizar por software, e aí a medida não vale.
- **Decisão pela medida:** só ligar o glow na Web se mantiver 60 FPS. Se não der, fazer o halo aditivo no próprio sabre, em camadas, sem pós-processamento, para o site ficar no mesmo nível do nativo.
- Glow e bloom ajustados em `duel_environment.tres`; flicker sutil contínuo, com `Settings.reduced_effects` desligando.
- Rastro de golpe mais legível, com fim em faixas e não em degradê.
- `PointLight2D` colorida por lâmina, com limite por cena.
- Faíscas de choque por força do contato, reagindo aos eventos existentes.
- Um punho único por lutador, indo além dos 7 tipos atuais, ainda por código.
- Parâmetros em `EffectsConfig`, sem números soltos.
- `design/VFX.md` atualizado antes do código.

## Critérios de aceite

- Testes completos sem falha (`godot --headless --path . --script res://tools/run_tests.gd`).
- Matriz de duelos idêntica à base (`tools/simulate.gd --matrix all --duels 12 --difficulty hard`: comparar com a última medição registrada no ROADMAP).
- Build Web local aberta no Chrome em 1280×720 e 1920×1080, sem erro no console e a 60 FPS no duelo mais pesado.
- Em captura a 720p, a lâmina tem pelo menos 5 px de largura visível no neutro e é o elemento mais claro da cena em todas as arenas.
- Cor e silhueta distinguíveis nos 16 lutadores (folha de capturas).
- `reduced_effects` remove flicker e reduz o glow.
- A lâmina na build Web e no nativo fica equivalente em folha de capturas lado a lado.
- Sem novo evento nem mudança na simulação (`git diff --stat -- simulation` vazio).

## Arquivos afetados

- `presentation/fighters/blade_view.gd`, `blade_trail.gd`, `hilt_view.gd`, `fighter_view.gd`
- `presentation/effects/*`
- `presentation/duel_environment.tres`
- `data/balance/effects_config.*`
- `design/VFX.md`

## Dependências

Nenhuma obrigatória. Se vier depois da 00b, herda a grade; se vier antes, usar a escala do config.

## Ordem sugerida

Pode ser feita primeiro, para ganho visível imediato.
