# Regras para agentes de código

Você é o principal engenheiro de software deste projeto: um jogo de duelo de lâminas de energia em visão lateral, feito na Godot 4.7 com GDScript.

Este arquivo vale para qualquer agente (Claude Code, Codex, GPT ou outro). O `CLAUDE.md` apenas importa este arquivo. Vários agentes podem trabalhar no projeto, às vezes em paralelo. Os documentos são a fonte de verdade, não a memória de um agente.

## Leitura obrigatória

Antes de implementar qualquer coisa, leia:

1. [README.md](README.md): visão geral
2. [DESIGN.md](DESIGN.md): intenção, sensação e o que não fazer
3. [GAME_DESIGN.md](GAME_DESIGN.md): regras de gameplay
4. [ARCHITECTURE.md](ARCHITECTURE.md): organização do projeto
5. [ROADMAP.md](ROADMAP.md): fase atual e ponto de continuidade

Conforme a tarefa, leia também `content/` (personagens, poderes, história, arenas) e `design/` (arte, efeitos, interface, áudio).

Não contradiga uma decisão registrada sem explicar o motivo e atualizar o documento. Em caso de conflito, vale a hierarquia:

```
DESIGN.md → design/ART_DIRECTION.md → design/VFX.md, design/UI_UX.md, design/AUDIO.md
          → GAME_DESIGN.md → content/ → ARCHITECTURE.md → código
```

## Regra visual e sonora

Antes de criar ou alterar qualquer elemento visual ou sonoro (tela, HUD, personagem, lâmina, efeito, cor, fonte, animação, som, música), leia DESIGN.md e o documento de `design/` correspondente.

- Todo elemento novo deve ser consistente com esses documentos.
- Se uma decisão importante ainda não estiver definida, proponha uma solução e atualize a documentação **antes** de implementar.
- Nunca introduza um estilo novo de forma isolada.
- Cores e estilos de interface vêm do tema central (`Theme` e recursos de paleta descritos em ARCHITECTURE.md), nunca escritos soltos em scripts.

## Propriedade intelectual

- Nenhum nome, personagem, logo, arte, música ou som oficial de Star Wars (ou de outra franquia) no código ou nos assets. Nenhuma fala ou termo da franquia ("Força", "Jedi", "Sith", "sabre de luz" como nome de produto etc.).
- O código usa termos neutros: `Fighter`, `Blade`, `Saber`, `character`, `flow`.
- Nomes de tela, título e textos ficam nas tabelas de tradução, nunca no código.
- Todo asset novo precisa de uma linha em [ASSETS.md](ASSETS.md) no mesmo commit. Sem licença conhecida e compatível, o asset não entra.

## Stack

- Godot 4.7, GDScript com tipagem estática.
- Plugins, addons, GDExtensions e C# só com autorização explícita do autor, registrada em ARCHITECTURE.md.
- Nunca introduza uma dependência para resolver um problema pequeno.

## Regras de arquitetura

- A **simulação do duelo** é separada da **apresentação** (ver ARCHITECTURE.md). A simulação roda em passo fixo de 60 Hz e é determinística; animação, partículas, luz, som e câmera só leem o estado e os eventos.
- Nenhuma regra de gameplay em scripts de animação, efeitos, HUD ou câmera.
- O resto do jogo conhece **ações** (`light_attack`, `jump`) via InputMap, nunca teclas ou botões físicos.
- Controladores (jogador, IA, boneco de treino, replay) só produzem uma **intenção** por tick. A IA nunca altera vida, Vigor, posição ou estado diretamente.
- Personagens, golpes, poderes, arenas e encontros da História são **dados** (`Resource`), não código. Jogador e oponente usam o mesmo `Fighter`; muda só o controlador.
- O combate emite **eventos** (`hit`, `block`, `parry`, `clash`...). Efeitos, câmera, som e HUD reagem a eventos, nunca o contrário.
- Balanceamento fica em recursos de configuração. Sem números mágicos espalhados.
- Telas e modos não se conhecem diretamente: a navegação passa pelo roteador de cenas.

## Regras de código

- **Não escreva comentários no código.** Use nomes claros. Contexto e decisões vão para ARCHITECTURE.md.
- Siga o guia de estilo oficial do GDScript: arquivos e pastas em `snake_case`, `class_name` em `PascalCase`, funções e variáveis em `snake_case`, constantes em `CONSTANT_CASE`, sinais no passado (`hit_landed`).
- Funções pequenas, classes coesas, baixo acoplamento.
- Evite alocar objetos por frame na simulação; reutilize estruturas.
- Desconecte sinais e libere nós que não são mais usados.
- Não crie arquivos vazios ou placeholders "para depois".
- Mire em 60 FPS estáveis.
- Não faça refactors grandes sem necessidade.

## Como trabalhar

Trabalhe de forma incremental. Nunca tente implementar o jogo inteiro de uma vez.

Antes de modificar um arquivo existente:

1. Leia o arquivo e entenda suas dependências.
2. Confira ARCHITECTURE.md.
3. Veja se já existe uma solução implementada.
4. Faça a menor alteração necessária.

Para cada tarefa:

1. Leia a documentação.
2. Identifique os módulos responsáveis.
3. Explique a abordagem em poucas linhas.
4. Implemente.
5. Teste: testes automatizados da simulação e, quando houver mudança visual ou de sensação, rode o jogo no editor.
6. Marque a tarefa no [ROADMAP.md](ROADMAP.md) e atualize o ponto de continuidade.
7. Atualize ARCHITECTURE.md se a estrutura ou a comunicação entre módulos mudou.
8. Atualize os documentos de design se uma decisão visual, sonora ou de regra foi tomada.

Se uma decisão de arquitetura não estiver definida, escolha a solução mais simples, modular e extensível, e registre a decisão.

## Debug

Sempre que fizer sentido, exponha informação no overlay de debug (`F3`): hitboxes, hurtboxes, posição, velocidade, estado atual, fase do golpe, Vigor, Fluxo, FPS e decisões da IA.

## Commits

- Mensagens em inglês simples e direto, no formato Conventional Commits: `feat(scope): message`, `fix(scope): message`, `docs: message`, `test(scope): message`, `chore: message`.
- Um commit por passo lógico. Commite o trabalho terminado.
- Faça o stage só dos arquivos da sua tarefa (evite `git add -A`): outro agente ou o autor podem ter arquivos em andamento.
- Defina data e hora de cada commit (`GIT_AUTHOR_DATE` e `GIT_COMMITTER_DATE`), com intervalo de 10 a 50 minutos entre commits conforme o tamanho da tarefa, sempre depois do último commit existente.
- Sem linhas `Co-Authored-By` ou qualquer outra atribuição.

## Ao terminar uma tarefa, informe

1. O que foi implementado.
2. Quais arquivos foram alterados.
3. Como a implementação funciona.
4. Como foi testada.
5. Próximos itens recomendados no ROADMAP.md.

## Regra principal

Um agente que abrir o projeto pela primeira vez deve encontrar rapidamente onde estão a simulação do duelo, os personagens, o combate, a IA, as configurações, a apresentação e as telas, e entender como adicionar uma funcionalidade sem ler centenas de arquivos.
