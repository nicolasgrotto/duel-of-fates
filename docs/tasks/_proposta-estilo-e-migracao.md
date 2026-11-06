# Proposta: guia de estilo e migração para 640×360

Proposta para aprovação, a ser registrada de vez na task 00. **Nada foi implementado.** Base: [_auditoria.md](_auditoria.md).

## Grade

| Medida | Hoje | Proposta |
| --- | --- | --- |
| Grade neutra | cerca de 480×270 | **640×360** |
| Escala do mundo | 1 px = 2 u | **1 px = 1,5 u** (`units_per_pixel = 1.5`) |
| Altura do lutador | cerca de 75 px | **cerca de 100 px**, dentro da faixa 64×96 a 96×128 |
| Ampliação | 2,67× em 720p, 4× em 1080p | **2× em 720p, 3× em 1080p, 4× em 1440p** |

A simulação não muda: ela trabalha em unidades, e a mudança é só de quantos pixels cabem em cada unidade. O enquadramento continua igual, com o lutador em 27% da altura da tela.

## Decisões que precisam do autor

### D1. Rig com peças ou quadro a quadro

O plano pede sprites com frames-chave. O jogo usa rig, e o que depende dele está na auditoria.

| | **A. Peças no rig (recomendada)** | B. Quadro a quadro |
| --- | --- | --- |
| Imagens por lutador | cerca de 10: poses-chave de referência e folha de peças | **centenas**: cerca de 25 ações × 6 quadros = 150 por lutador, cerca de 2.700 no elenco, antes dos trajes |
| Animação | toda a atual, e o trabalho da Vespa e da Brasa é preservado | refazer tudo; golpes sincronizados à mão |
| Trajes e rostos | troca de paleta, como hoje | multiplicam o volume |
| Luz da lâmina em tempo real | sim, com normal gerado | só pintada, e errada nas outras cores |
| Execuções, peças cortadas, capa física | preservadas | perdidas ou refeitas |
| Limite | movimento fica limitado ao que o rig faz | poses totalmente livres |

**Recomendo A**, sem abrir mão dos frames-chave: idle, ataque e hit continuam sendo gerados um por vez, como **alvo de qualidade e referência**, e a folha de peças sai deles. A task 03 mede a diferença com um lutador real antes de comprometer o restante. Se o resultado do rig não chegar ao nível das poses, a alternativa é híbrida: rig para o combate e quadros pintados só em poses especiais, como introduções.

### D2. Zoom da câmera ou 2× literal

Pixel perfect com ampliação inteira e fixa não convive com o zoom contínuo e o punch-in, que são parte da sensação do duelo (`ART_DIRECTION`, "Punch-in curto no impacto").

**Recomendo** tratar 640×360 como a grade **neutra** e manter o zoom com `pixel_upscale`: todo o quadro é desenhado na grade e ampliado por igual, então não há mixel, pois todos os pixels têm o mesmo tamanho, e no neutro a ampliação é inteira. A alternativa literal, câmera só com pan, exige refazer o enquadramento e perde o punch-in.

### D3. Texto de interface

**Recomendo** manter a Oxanium em alta resolução, como na família tática aprovada na 1.1: é mais legível, serve aos dois idiomas e cumpre o mínimo de 18 px em 720p. Tudo que for **imagem** de interface (retratos, ícones, molduras, fundos) fica na grade, com pixel de 3 px na base 1080p.

### D4. Luz de recorte pintada ou dinâmica

Cada lutador tem três cores de lâmina, e o shader já ilumina o corpo pela lâmina. Recorte pintado ficaria na cor errada em duas delas.

**Recomendo:** recorte **pintado** só em retratos, fundos e referências; nas peças do rig, a luz vem do shader e dos mapas de normal. O prompt-base traz a instrução em um bloco opcional.

### D5. Ordem em relação às tasks 19 a 22 do Codex

O Codex tem Roguelite, Saga e Ação lateral pendentes, na mesma branch. A migração de grade e a troca de peças mexem no que essas tasks usam. **Recomendo** concluir as tasks 00b e 03 antes de Ação lateral (21 e 22), que reutiliza o rig, ou deixar as duas frentes em branches separadas.

### D6. Modos top-down

Operações e naves têm sprites de 24×28 e 40×40, tiles de 32×32 e câmera própria. **Recomendo** deixá-los fora desta rodada, na grade atual, porque foram refeitos e aprovados na 1.1.

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
| Base de painel | azul-ardósia `#0b1424` | vinho muito escuro, a definir na task 00 |
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

Passos da task 00b, sem arte nova:

1. Trocar `units_per_pixel` para 1,5 e tirar valores fixos como `GRID` de `blade_view.gd`, passando a ler do config.
2. Fazer os pintores (`fighter_parts.py`, `make_arenas.py`, `make_finishers.py`, `paint_blasters.py`) aceitarem a escala e regenerar as peças e arenas atuais na grade nova.
3. Ajustar `PixelStage` para escala inteira no enquadramento neutro nas resoluções comuns, com `expand` mostrando mais mundo em vez de barras.
4. Validar: matriz de duelos idêntica, todos os testes, capturas de todas as arenas e 720p, 1080p e janela não padrão.

Essa ordem deixa o jogo inteiro e testável na grade nova **antes** da primeira imagem gerada.
