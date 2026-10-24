# ASSETS

Todo asset do projeto (arte, fonte, som, música, shader de terceiros) tem uma linha aqui, no mesmo commit em que entra. Sem origem e licença conhecidas e compatíveis, o asset não entra. Nenhum asset oficial de Star Wars ou de outra franquia.

| Arquivo | Tipo | Autor / origem | Licença | Observação |
| --- | --- | --- | --- | --- |
| `icon.svg` | ícone | template da Godot | MIT (Godot Engine) | ícone padrão do projeto, a substituir pelo ícone próprio |
| `addons/godot_mcp_toolkit/` | addon de editor | NPGameDev, Godot MCP Toolkit 1.0.4 | MIT (código); logo e ícones do addon não licenciados para reuso | ferramenta de desenvolvimento, fora dos builds |
| `assets/fonts/oxanium/Oxanium-Variable.ttf` | fonte | The Oxanium Project Authors (sevmeyer/oxanium), via Google Fonts | SIL Open Font License 1.1 (`assets/fonts/oxanium/OFL.txt`) | fonte única da interface (UI_UX.md); variável, pesos 200 a 800 |
| `assets/fonts/arrows/DuelArrows.ttf` | fonte (só as setas ← ↑ → ↓) | original do projeto, gerada por `tools/art/make_arrow_font.py` | original (mesma licença do projeto) | fallback da Oxanium no tema, que não tem setas; na Web não há fontes do sistema para emprestar |
| `assets/characters/<id>/*.png`, `art.tres` | arte de personagem em pixel art na grade do mundo (mapas de material e de normal) | original do projeto, pintado por `tools/art/paint_fighters.py` a partir de `tools/art/fighter_specs.py` | original (mesma licença do projeto) | peças do rig 2D; as cores vêm dos trajes em `data/characters/` |
| `assets/audio/sfx/*.wav` | efeitos sonoros | original do projeto, sintetizado por `tools/audio/synth_audio.py` (osciladores, ruído e envelopes, sem amostras) | original (mesma licença do projeto) | lâminas, impactos, corpo, interface |
| `assets/audio/powers/*.wav` | efeitos sonoros dos poderes (lançamento, impactos, loops de canalização, quebras) | original do projeto, sintetizado por `tools/audio/synth_audio.py` (osciladores, ruído e envelopes, sem amostras) | original (mesma licença do projeto) | poderes do Fluxo |
| `assets/audio/music/*.wav` | música (camadas base, percussão e tensão) dos temas do duelo, sagrado e de chefe | original do projeto, composta e sintetizada por `tools/audio/synth_audio.py` | original (mesma licença do projeto) | música dinâmica do duelo; variações por arena e tema dos chefes |
| `assets/audio/ambience/*.wav` | ambiência | original do projeto, sintetizada por `tools/audio/synth_audio.py` | original (mesma licença do projeto) | uma por arena (Refino, Santuário, Mina, Telhado, Anel, Floresta, Salinas, Convés, Cume, Cidadela) |
| Onda de Repulsão em `presentation/effects/power_view.gd` | VFX procedural na grade de pixels | original do projeto, geometria de arco e faixas de opacidade desenhada em GDScript | original (mesma licença do projeto) | sem textura externa; parâmetros em `data/balance/power_vfx_config.tres`, cores de tier no `UiPalette` |
