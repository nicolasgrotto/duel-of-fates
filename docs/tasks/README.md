# Upgrade visual e sonoro: tasks

Uma task por arquivo, executável isoladamente. Ao concluir uma task com os critérios cumpridos, **renomeie o arquivo com o prefixo `DONE_`**, como em `build/codex_tasks/`, e marque no `ROADMAP.md`.

Base: [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md), com as decisões D1 a D8 do autor. A numeração destas tasks é separada das tasks do Codex em `build/codex_tasks/`. Briefs em [../art-briefs/](../art-briefs/).

## Regras para todas as tasks

- Valem [AGENTS.md](../../AGENTS.md) e a hierarquia dos documentos: decisão visual ou sonora é registrada **antes** de implementar.
- Sem API key. Imagens só no Codex (plano ChatGPT, gpt-image), com o Gemini como reserva. Claude Code não gera imagens.
- Briefs e prompts descrevem personagens como originais de ficção científica sombria e não citam nenhuma franquia, obra ou artista.
- Conferir à mão toda imagem gerada: sem emblema, insígnia, logo ou texto.
- Trajes de risco por código ou só com formas genéricas (D8).
- Áudio sem serviço pago ou externo; faixa sem licença confirmada não entra (D7).
- A simulação não muda por causa de arte ou áudio. A matriz de duelos tem de ficar idêntica.
- Todo asset entra em `ASSETS.md` no mesmo commit, com ferramenta, data e licença.

## Índice

| Task | Título | Quem | Depende de |
| --- | --- | --- | --- |
| [00](00-guia-de-estilo-e-grade.md) | Guia de estilo e grade | Claude Code + autor | — |
| [00b](00b-migracao-grade-640x360.md) | Migração para 640×360 | Claude Code | 00 |
| [01](01-pipeline-de-assets.md) | Pipeline de assets | Claude Code | 00 |
| [02](02-sabres-no-godot.md) | Sabres no Godot | Claude Code | — |
| [03](03-piloto-guardiao.md) | Piloto: Guardião | Codex, autor, Claude Code | 00, 00b, 01 |
| [04](04-sombra-bastiao-vespa.md) | Sombra, Bastião, Vespa | Codex, autor, Claude Code | 03 |
| [05](05-espelho-haste-brasa.md) | Espelho, Haste, Brasa | idem | 03 |
| [06](06-forja-garca-ceifador.md) | Forja, Garça, Ceifador | idem | 03 |
| [07](07-eco-corsaria-lince.md) | Eco, Corsária, Lince | idem | 03 |
| [08](08-soberano-anciao-predestinado.md) | Soberano, Ancião, Predestinado | idem | 03 |
| [09](09-sombra-desperta-coldre-protagonista.md) | Sombra Desperta, Coldre, protagonista | idem | 03 |
| [10](10-retratos.md) | Retratos 64×64 | Codex, autor, Claude Code | 01 |
| [11](11-briefing-de-design.md) | Mockups no Claude Design | Claude Code + autor | 00 |
| [12](12-menu-principal.md) | Menu principal | Claude Code | 11 |
| [13](13-selecao-de-lutador.md) | Seleção de lutador | Claude Code | 10, 11 |
| [14](14-arenas-e-hud.md) | Arenas e HUD | Claude Code, Codex | 00b, 11 |
| [15](15-audio-direcao-musical.md) | Direção musical | Claude Code + autor | — |
| [16](16-audio-faixas.md) | Faixas | Claude Code | 15, 18 |
| [17](17-audio-sfx.md) | SFX | Claude Code | 15 |
| [18](18-audio-producao.md) | Produção: MIDI, FluidSynth, numpy | Claude Code | 15 |
| [19](19-audio-integracao.md) | Integração de áudio | Claude Code | 16, 17 |
| [20](20-revisao-marca-e-splash.md) | Revisão de marcas e imagem de carregamento | Claude Code + autor | — |

## Ordem recomendada

1. **20:** curta, antes de divulgar o repositório.
2. **00:** registra as decisões e as paletas.
3. **02:** não depende de arte externa e dá o maior ganho visível de imediato.
4. **00b** e **01**, em paralelo.
5. **03:** portão do projeto. Nenhum lutador novo antes da decisão do autor.
6. **Tasks 20 a 22 do Codex** (`build/codex_tasks/`) só depois de 00b e 03. A task 19 do Codex é top-down e pode rodar antes.
7. **11**, e depois **04 a 09** em lotes pequenos, com **10**.
8. **12**, **13**, **14**.
9. Áudio, em paralelo a partir de qualquer ponto: **15**, **18**, **16** e **17**, **19**.

## Riscos

| Risco | Efeito | Mitigação |
| --- | --- | --- |
| Peças geradas não combinam entre si | Lutador com aparência montada | Task 03 compara com o híbrido antes de escalar |
| Inconsistência entre imagens geradas | Peças do mesmo lutador não combinam | Referência fixa, paleta fixa, uma imagem por vez, limpeza em Aseprite; medir no piloto |
| Limite do plano do Codex | Cronograma incerto | Lotes pequenos; custo real em `_lessons.md` |
| Gerador reproduz símbolos ou personagens conhecidos | Violação de propriedade intelectual em release pública | Negativo no prompt-base, conferência manual, trajes de risco por código (D8), task 20 |
| Licença de imagem gerada ou de soundfont | Asset não pode entrar | Conferir termos no momento do uso; registrar em `ASSETS.md`; sem licença, fica de fora |
| Música própria abaixo do esperado | Trilha sem o peso desejado, sem serviço para recorrer | Teste de 30 s na task 18, antes de produzir tudo; direção de synth favorece a síntese |
| Glow e luzes na Web | Queda de FPS (uma thread, compatibilidade) | Orçamento medido na task 02 |
| Tamanho da build Web | Carregamento lento | OGG, orçamento na task 18 |
| Mapas de normal gerados | Luz da lâmina pior que a atual | Comparar na task 03 antes de adotar |
| Duas frentes na mesma branch | Conflito entre Codex e Claude Code | Uma task por vez; tasks 20 a 22 do Codex só depois de 00b e 03 (D5) |
| Regressão visual sem teste | Mãos fora do cabo, peças soltas | `test_guard_tracking`, folhas de captura por task |
| Zoom contínuo contra pixel perfect | Shimmer ou pixels desiguais | Teste e alternativas na task 00b (D2) |
