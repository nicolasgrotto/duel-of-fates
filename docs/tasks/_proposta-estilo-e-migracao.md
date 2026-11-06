# Proposta: guia de estilo e migração para 640×360

Aprovada pelo autor, com as decisões abaixo; a task 21 registra tudo em `ART_DIRECTION.md`. **Nada foi implementado ainda.** Base: [_auditoria.md](_auditoria.md).

## Grade

| Medida | Hoje | Proposta |
| --- | --- | --- |
| Grade neutra | cerca de 480×270 | **640×360** |
| Escala do mundo | 1 px = 2 u | **1 px = 1,5 u** (`units_per_pixel = 1.5`) |
| Altura do lutador | cerca de 75 px | **cerca de 100 px**, dentro da faixa 64×96 a 96×128 |
| Ampliação | 2,67× em 720p, 4× em 1080p | **2× em 720p, 3× em 1080p, 4× em 1440p** |

A simulação não muda: ela trabalha em unidades, e a mudança é só de quantos pixels cabem em cada unidade. O enquadramento continua igual, com o lutador em 27% da altura da tela.

## Decisões do autor

Respondidas pelo autor. A task 21 as registra em `ART_DIRECTION.md`. Os números de task referem-se a `build/agent_tasks/`.

| # | Decisão | Consequência |
| --- | --- | --- |
| D1 | **Rig com peças**, mantido. Quadro a quadro está descartado | A task 27 compara (a) peças geradas a partir do frame-chave e (b) híbrido, com IA só em cabeça, torso, capa e punho. Registra imagens consumidas, tempo de limpeza e resultado visual, com capturas ao lado do Guardião atual. Só a versão escolhida fica no jogo |
| D2 | **Zoom contínuo mantido**, com 640×360 como enquadramento neutro | A task 24 testa shimmer e largura dos pixels no zoom contínuo e no punch-in, no nativo e no Chrome, e propõe degraus inteiros ou transição curta se precisar |
| D3 | **Texto em Oxanium**, em alta resolução | Imagens de interface ficam na grade, com pixel de 3 px na base 1080p |
| D4 | **Recorte pintado só em retratos e fundos** | Nas peças, a luz vem do shader e dos mapas de normal |
| D5 | **Upgrade visual antes das tasks 53 e 54 (Ação lateral)** e da 52 (Saga), para os modos nascerem com a grade e o rig novos | Essas tasks só começam depois da migração (24) e da aprovação do piloto (27). A 19 (Roguelite) e o áudio não esperam |
| D6 | **Modos top-down fora** desta rodada | Operações e naves ficam na grade atual |
| D7 | **Áudio só com synth sombrio e atmosférico:** pads, baixos graves, drones, arpejos, coro sintético, percussão e impactos eletrônicos. **Sem camadas orquestrais.** Sem serviços pagos, Suno ou Udio | Síntese em numpy e, se precisar, MIDI com sons de synth, com material de licença livre registrado. Faixa sem licença confirmada não entra. Faixa de teste do menu, de cerca de 30 s, antes de produzir o resto |
| D8 | **Trajes de risco:** Caído, Duelo, Legado e Ocaso do Predestinado, além de Soberano, Sombra, Espelho e Eco, só por código ou formas genéricas | Podem ser reabertos um a um depois do piloto |
| D9 | **Glow na Web:** o autor mede no Chrome dele, com GPU real | Se não mantiver 60 FPS, usar halo aditivo no próprio sabre (task 23) |
| D10 | **Limpeza de arte:** automatizada ao máximo por script (quantização, pixels soltos, contorno) | Tempo automático e manual registrados separadamente |
| D11 | **Retoque em Pixelorama** (1.2.4), com LibreSprite como alternativa. Sem Aseprite | MCP do Pixelorama não é instalado agora; critérios na task 27 |
| D12 | **Duas publicações:** 1.1.1 antes da migração e 1.2 com todo o resto. Não haverá 1.3 | Tasks 22 e 55. Tags internas sem publicar |

## Trajes de risco

Armaduras e mantos escuros, máscaras e próteses são o que o gerador mais tende a aproximar de personagens conhecidos.

| Lutador | Traje ou visual | Tratamento |
| --- | --- | --- |
| Predestinado | Caído, Duelo, Legado, Ocaso | **Por código** a partir dos pintores atuais, sem imagem gerada |
| Soberano | Original (manto preto, capuz fundo, olhos do Eclipse) e Legado | Por código, ou brief só com formas genéricas e sem prompt de rosto |
| Sombra | Capa longa quase preta, capuz pontudo | Formas genéricas; conferência manual reforçada |
| Espelho, Eco | Máscara lisa com capuz | Formas genéricas; máscara própria |

Nos prompts, nunca citar franquia, obra ou personagem, nem por negação: o texto descreve só formas, materiais e cores.

## Guia de estilo proposto

**Lutadores**

- 12 a 16 cores por lutador, por slot: pele, cabelo, roupa, acabamento, couro, metal e olhos, com 3 tons cada.
- Contorno colorido, um tom mais escuro que a cor vizinha, nunca preto puro. Contorno seletivo: a borda do lado da luz pode sumir.
- Cel shading em 3 tons, sem degradê e sem dither no corpo.
- Luz de cima e levemente à frente. Luz de cena fria e fraca, nunca mais forte que a lâmina.
- Teste da silhueta: pintado de preto, continua reconhecível.

**Paletas por Caminho**

Sem moral: nenhuma cor de lâmina indica lado, e o Caminho aparece só na interface.

| Tema | Aurora | Eclipse |
| --- | --- | --- |
| Cor de interface | `#5aa2ff` | `#ff4458` |
| Base de painel | azul-ardósia `#0b1424` | vinho muito escuro, a definir na task 21 |
| Roupas | ardósia, terra, oliva, dessaturados | vinho, carvão, ferrugem, dessaturados |

**Lâmina:** núcleo branco, cor saturada e halo aditivo. É sempre o elemento mais claro da cena.

**Fundos:** preto profundo, azul escuro, metais frios. Estrelas em pixel único e nebulosa em blocos. Céus em faixas, conforme a regra atual.

## Checklist anti-mixel

Para toda imagem que entra no jogo:

1. Sem pixels de meio-tom criados por redimensionamento: nenhuma cor fora da paleta declarada.
2. Bloco de 2×2 ou maior em que todo pixel tem a cor vizinha é aceitável só se for forma real.
3. Sem escala, rotação com filtro ou `Sprite2D.scale` não inteiro em arte de interface.
4. Peças do rig giram com nearest e snap; por isso continuam simples.
5. Todo ícone, retrato e moldura em múltiplo inteiro do pixel de interface (3 px na base 1080p).
6. Sem transparência parcial no sprite, exceto efeitos aditivos.
7. Sem texto, logo, insígnia ou emblema na imagem.

A imagem de carregamento é **referência de riqueza, não de técnica**: tem 1672×941 e blocos de tamanhos variados, sem grade única. Nenhum asset em jogo deve seguir esse método.

## Migração para 640×360

Passos da task 24, sem arte nova:

1. Trocar `units_per_pixel` para 1,5 e tirar valores fixos como `GRID` de `blade_view.gd`, passando a ler do config.
2. Fazer os pintores (`fighter_parts.py`, `make_arenas.py`, `make_finishers.py`, `paint_blasters.py`) aceitarem a escala e regenerar as peças e arenas atuais na grade nova.
3. Ajustar `PixelStage` para escala inteira no enquadramento neutro nas resoluções comuns, com `expand` mostrando mais mundo em vez de barras.
4. Validar: matriz de duelos idêntica, todos os testes, capturas de todas as arenas e 720p, 1080p e janela não padrão.

Essa ordem deixa o jogo inteiro e testável na grade nova **antes** da primeira imagem gerada.
