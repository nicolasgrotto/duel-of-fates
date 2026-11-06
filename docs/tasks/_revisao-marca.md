# Revisão de marcas e imagem de carregamento

Task 20. Conferência técnica feita em 2026-11-06, sobre a branch `1.2`, o site e as releases publicadas. **Não é análise jurídica:** o que é uso aceitável segue decisão do autor, e o aviso de não afiliação informa, mas não elimina direitos de terceiros.

## O que foi conferido

| Item | Como | Resultado |
| --- | --- | --- |
| `assets/boot_splash_clean.png` | Olhada em tamanho natural | Sabre, estrelas e nebulosa. Sem emblema nem texto |
| Imagem de carregamento do site | Baixada de `index.png` | Idêntica à limpa |
| Release v1.1.0 | Zip baixado, `index.png` e `.pck` | Limpa; o `.pck` não contém `boot_splash1` |
| Release v1.0.0 | Zip baixado | Tela padrão da Godot; sem emblema |
| `boot_splash1.png` (original) | `git log --all` | **Nunca entrou no histórico** |
| Imagens removidas no histórico | `git log --diff-filter=D` | Só 3 ícones de poder antigos; nada de franquia |
| `MenuEmblem` | Código e captura | Duas lâminas cruzadas por código, sem símbolo |
| Prévias de missão | Capturas da 1.1 | Recortes do próprio jogo |
| Código, dados e nomes de arquivo | Busca por termos de franquia | Nenhum |
| Traduções | Busca por termos de franquia | Só `Maul` (ver ação 3); "força" é sempre o substantivo comum |
| Aviso de não afiliação | `README.md`, `RELEASE_NOTES.md` | Presente |

## Achados

| # | Achado | Onde |
| --- | --- | --- |
| 1 | O título do jogo é quase igual ao de uma peça musical conhecida da franquia que o inspira. É o item mais visível de toda a revisão | `GAME_TITLE`, nome do repositório, URL do site |
| 2 | O ícone do jogo e do navegador ainda é o da Godot. A licença permite, e `ASSETS.md` já o marca como "a substituir" | `icon.svg` |
| 3 | A habilidade do Bastião em inglês se chama `Maul`, que coincide com o nome de um personagem da franquia | `ABILITY_BASTION` |
| 4 | Documentos citam a trilogia como referência de sensação. O agente lê esses documentos ao escrever prompts | `README.md`, `DESIGN.md`, `design/ART_DIRECTION.md` |
| 5 | O traje Caído e o traje Duelo já existem no jogo, por código, e a descrição do segundo fala em arquétipo reconhecível | `content/CHARACTERS.md`, trajes do Predestinado |
| 6 | A estrutura da História ecoa arquétipos da franquia: mestre escondido, aprendiz do senhor sombrio, herdeiro oculto, nascido para equilibrar. O texto é original, sem nomes | `content/STORY.md`, traduções `STORY_*` |
| 7 | O logo do addon Godot MCP Toolkit, não licenciado para reuso, ficou no histórico entre 2026-10-20 e 2026-11-02. Hoje está fora do repositório e nunca foi para os builds | `addons/godot_mcp_toolkit/icon.svg`, commits `a6086f5` a `927b38d` |

## Ações para o autor decidir

| # | Ação | Recomendação |
| --- | --- | --- |
| 1 | Título do jogo: manter ou trocar antes de divulgar | **Decisão do autor.** Trocar custa pouco no jogo (tradução) e mais fora dele (repositório e URL), e fica mais caro depois de divulgar |
| 2 | Ícone próprio | Fazer na task 22, a partir do punho da imagem de carregamento |
| 3 | Renomear `Maul` | Sim, na task 22: `Sledge`. Só tradução |
| 4 | Referência à trilogia | Manter só no aviso legal do `README.md`; trocar em `DESIGN.md` e `ART_DIRECTION.md` por uma descrição da sensação |
| 5 | Caído e Duelo | Olhar no jogo e decidir se ficam; reescrever a descrição em formas genéricas |
| 6 | Estrutura da História | Manter; revisar só a frase "nascido para equilibrar", se quiser |
| 7 | Logo do addon no histórico | Não reescrever o histórico: é destrutivo, e um arquivo com licença restrita em commits antigos pede só a remoção já feita. Só o autor pode decidir o contrário |
