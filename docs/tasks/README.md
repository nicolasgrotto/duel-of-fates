# Upgrade visual e sonoro: índice geral

As tasks ficam em [`build/agent_tasks/`](../../build/agent_tasks/), numeradas na **ordem de execução**, com o agente no fim do nome: `NN_titulo_codex.md` ou `NN_titulo_claude.md`. Tarefa concluída recebe o prefixo `DONE_`. A instrução para o Codex está em `build/agent_tasks/CODEX_INSTRUCTION.md`.

Esta pasta guarda só este índice, a [auditoria](_auditoria.md) e a [proposta com as decisões do autor](_proposta-estilo-e-migracao.md). Os briefs estão em [`docs/art-briefs/`](../art-briefs/).

## Versões

| Versão | Conteúdo | Quando |
| --- | --- | --- |
| **1.1.1** | Blasters, armas de assinatura, correção de cache e tasks do Codex já concluídas | Task 22, antes da migração |
| **1.2** | Todo o resto: visual, áudio e modos. Não haverá 1.3 | Task 55 |

**Marcos internos**, sem publicar no site: `1.2-alpha1` (24, sabres e grade), `1.2-alpha2` (27, piloto aprovado), `1.2-alpha3` (45, elenco), `1.2-alpha4` (51, interface e arenas), `1.2-audio` (32, áudio mesclado). Tags sem `v` na frente: `release.yml` só publica tags `v*`.

## Tabela

Tasks 01 a 18 estão concluídas, com o prefixo `DONE_`.

| Nº | Título | Responsável | Depende de |
| --- | --- | --- | --- |
| 19 | Roguelite (Operações) | Codex | — |
| 20 | Revisão de marcas e imagem de carregamento | Claude | — |
| 21 | Guia de estilo e grade | Claude | — |
| 22 | **Release 1.1.1** | Claude + autor | 20 |
| 23 | Sabres e glow | Claude + autor | — |
| 24 | Migração para 640×360 | Claude | 21, 22 |
| 25 | Pipeline de assets | Claude | 21 |
| 26 | Piloto: frames-chave do Guardião | Codex | 21, 25 |
| 27 | Piloto: peças, integração e comparação | Claude + autor | 24, 25, 26 |
| 28 | Áudio: direção | Codex | — |
| 29 | Áudio: produção e faixa de teste | Codex + autor | 28 |
| 30 | Áudio: faixas | Codex | 29 |
| 31 | Áudio: efeitos | Codex | 28 |
| 32 | Áudio: integração | Codex | 30, 31 |
| 33 | Mockups no Claude Design | Claude + autor | 21 |
| 34 | Imagens: Sombra, Bastião e Vespa | Codex | 27 |
| 35 | Peças e integração: Sombra, Bastião e Vespa | Claude + autor | 34 |
| 36 | Imagens: Espelho, Haste e Brasa | Codex | 27 |
| 37 | Peças e integração: Espelho, Haste e Brasa | Claude + autor | 36 |
| 38 | Imagens: Forja, Garça e Ceifador | Codex | 27 |
| 39 | Peças e integração: Forja, Garça e Ceifador | Claude + autor | 38 |
| 40 | Imagens: Eco, Corsária e Lince | Codex | 27 |
| 41 | Peças e integração: Eco, Corsária e Lince | Claude + autor | 40 |
| 42 | Imagens: Soberano, Ancião e Predestinado | Codex | 27 |
| 43 | Peças e integração: Soberano, Ancião e Predestinado | Claude + autor | 42 |
| 44 | Imagens: Sombra Desperta, Coldre e protagonista | Codex | 27 |
| 45 | Peças e integração: Sombra Desperta, Coldre e protagonista | Claude + autor | 44 |
| 46 | Imagens: retratos | Codex | 35 a 45 |
| 47 | Imagens: ícones 16×16 | Codex | 25 |
| 48 | Imagens: fundos de menu e arenas | Codex | 33 |
| 49 | Menu principal | Claude | 23, 33, 48 |
| 50 | Seleção de lutador | Claude | 33, 46, 47 |
| 51 | Arenas e HUD | Claude | 24, 33, 48 |
| 52 | Saga (era 20) | Codex | 24, 27 |
| 53 | Ação lateral 1 (era 21) | Codex | 24, 27 |
| 54 | Ação lateral 2 (era 22) | Codex | 53 |
| 55 | **Release 1.2** | Claude + autor | todas |

A 19 e o áudio (28 a 32) não esperam nada do visual. O restante pode ser lido de cima para baixo.

## Equivalência

| Antes | Agora |
| --- | --- |
| `build/codex_tasks/` | `build/agent_tasks/` |
| Codex 19 | 19 (só ganhou o sufixo) |
| Codex 20 (Saga) | 52 |
| Codex 21 (Ação lateral 1) | 53 |
| Codex 22 (Ação lateral 2) | 54 |
| docs 20 (marcas) | 20 |
| docs 00 (guia) | 21 |
| docs 02 (sabres) | 23 |
| docs 00b (migração) | 24 |
| docs 01 (pipeline) | 25 |
| docs 03 (piloto) | 26 (imagens) e 27 (peças e comparação) |
| docs 15 (direção) | 28 |
| docs 18 (produção) | 29 |
| docs 16 (faixas) | 30 |
| docs 17 (efeitos) | 31 |
| docs 19 (integração) | 32 |
| docs 11 (mockups) | 33 |
| docs 04 a 09 (elenco) | 34 a 45, em pares de imagens e peças |
| docs 10 (retratos) | 46 |
| docs 12, 13, 14 | 49, 50, 51 |
| novas | 22 (release 1.1.1), 47 (ícones), 48 (fundos), 55 (release 1.2) |

## O que o autor roda

Tudo que depende de GPU real ou de intervenção manual. Cada task diz exatamente o que rodar e o que observar.

| Task | O quê |
| --- | --- |
| 22 | Conferir a build 1.1.1 no navegador antes da publicação |
| 23 | Medir o glow no Chrome com GPU real |
| 24 | Olhar as capturas de zoom e decidir, se houver alternativa |
| 26, 34 a 48 | Aprovar imagens e conferir que não há emblema |
| 27 e 35 a 45 | Retoque no Pixelorama, cronometrado; aprovar jogando |
| 29 a 32 | Ouvir a faixa de teste e as faixas |
| 33 | Gerar e aprovar os mockups no Claude Design |

## Trabalho em paralelo

- **Áudio:** worktree `../dof-audio`, branch `audio/1.2`. Mescla em `1.2` com `git merge --no-ff` ao fim de cada task, depois de atualizar com `1.2` e passar os testes.
- **Roguelite (19):** não depende do rig, mas mexe no jogo. Uma task de código por vez na branch `1.2`, e os limites de arquivo de imagem e áudio não valem para ela nem para 52, 53 e 54.
- **Imagens:** ficam em `art/source/` e `docs/art-briefs/`, sem conflito com código.

## Riscos

| Risco | Efeito | Mitigação |
| --- | --- | --- |
| Peças geradas não combinam entre si | Lutador com aparência montada | Task 27 compara com o híbrido antes de escalar |
| Inconsistência entre imagens geradas | Peças do mesmo lutador não combinam | Referência fixa, paleta fixa, uma imagem por vez, limpeza em Pixelorama; medir no piloto |
| Limite do plano do Codex | Cronograma incerto | Lotes pequenos; custo real em `_lessons.md` |
| Gerador reproduz símbolos ou personagens conhecidos | Violação de propriedade intelectual em release pública | Negativo no prompt-base, conferência manual, trajes de risco por código (D8), task 20 |
| Licença de imagem gerada ou de soundfont | Asset não pode entrar | Conferir termos no momento do uso; registrar em `ASSETS.md`; sem licença, fica de fora |
| Música própria abaixo do esperado | Trilha sem o peso desejado, sem serviço para recorrer | Teste de 30 s na task 29, antes de produzir tudo; direção de synth favorece a síntese |
| Glow e luzes na Web | Queda de FPS (uma thread, compatibilidade) | Orçamento medido na task 23 |
| Tamanho da build Web | Carregamento lento | OGG, orçamento na task 29 |
| Mapas de normal gerados | Luz da lâmina pior que a atual | Comparar na task 27 antes de adotar |
| Duas frentes na mesma branch | Conflito entre Codex e Claude Code | Uma task por vez; 52, 53 e 54 só depois de 24 e 27 (D5) |
| Regressão visual sem teste | Mãos fora do cabo, peças soltas | `test_guard_tracking`, folhas de captura por task |
| Zoom contínuo contra pixel perfect | Shimmer ou pixels desiguais | Teste e alternativas na task 24 (D2) |
