# Task 10: Retratos 64×64

**Quem executa:** Codex nas imagens; autor na limpeza; Claude Code no pipeline

Leia antes: [AGENTS.md](../../AGENTS.md), [README desta pasta](README.md), [_auditoria.md](_auditoria.md) e [_proposta-estilo-e-migracao.md](_proposta-estilo-e-migracao.md).

## Objetivo

Um busto de 64×64 por lutador para os menus.

## Contexto

Hoje a seleção mostra o rig ao vivo e não há retratos. O pixel de interface é de 3 px na base 1080p (D3), então o retrato ocupa 192×192 na base. Aqui o recorte de luz pintado é permitido (D4), na cor padrão. Cada lutador precisa de versão neutra e, se a task 13 pedir, frames de animação.

## Entregáveis

- `assets/ui/portraits/<id>.png` para os 16 selecionáveis, mais chefe, Coldre e Predestinado Eclipse.
- Brief em cada arquivo de lutador, seção Retrato.
- Etapa de retrato no pipeline.
- Linhas em `ASSETS.md`.

## Critérios de aceite

- Exatamente 64×64, paleta do lutador, sem resíduo de chroma.
- Rosto ou máscara reconhecível a 720p, e silhueta distinta entre eles.
- Sem emblema, logo ou texto.
- Testes sem falha.

## Arquivos afetados

- `assets/ui/portraits/**`
- `docs/art-briefs/*.md`
- `tools/art/pipeline/**`
- `ASSETS.md`

## Dependências

01 e a arte do lutador correspondente, para coerência.

## Ordem sugerida

Junto dos grupos, ou ao fim deles.
