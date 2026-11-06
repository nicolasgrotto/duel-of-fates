# Prompt-base de estilo

**Todo brief herda este arquivo** e usa como referência a imagem do sprite atual do lutador em `art/reference/<id>/` (gerada pelo pipeline da task 01). Prompts em inglês, sem citar nenhuma franquia, obra, marca ou artista.

## Prompt-base

```text
Crisp pixel art character, original dark science fiction knight-samurai design.
Hard pixel edges, no anti-aliasing, no blur, no gradients, no dithering on the body.
Limited palette of about 14 colors. Tinted outline, one shade darker than the adjacent color, never pure black.
Three-tone cel shading: light, mid, shadow.
[RIM] Thin rim light along the edge facing the blade, in the blade color.
Glowing energy blade with a pure white core and a saturated color edge.
Full body, side view, facing right, feet visible, neutral readable silhouette.
Flat solid magenta background (#FF00FF), no floor, no cast shadow, no glow on the background.
No text, no letters, no logos, no emblems, no insignia, no symbols on clothing, no watermark, no frame.
```

## Regras de uso

- **Uma imagem por vez:** um frame-chave por pedido, nunca uma folha completa.
- **Referências anexadas:** a imagem do sprite atual e, depois da primeira pose aprovada, essa pose, para manter a consistência.
- **`[RIM]`:** manter em retratos, fundos e referências. Remover nas imagens que viram peças do rig, em que o shader faz essa luz (D4, a confirmar na task 00).
- **Magenta:** não usar `#FF00FF` nem tons próximos no personagem. A lâmina magenta da Sombra é gerada em outra cor e trocada pela paleta.
- **Sem texto ou símbolo:** se aparecer qualquer emblema, logo ou letra, descartar a imagem. Não tentar apagar depois.
- **Conferência:** toda imagem aprovada é olhada à mão, à procura de símbolos que lembrem marcas conhecidas.
- **Registro:** salvar em `art/source/<id>/` com data e prompt, e contar em `_lessons.md`.

Revisar este arquivo a partir das lições do piloto.
