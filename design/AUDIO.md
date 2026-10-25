# AUDIO — Som e música

Segue [DESIGN.md](../DESIGN.md). Som e música são parte da sensação do duelo: o choque precisa ser **ouvido** tanto quanto visto.

> Implementado na fase 3: sons sintetizados (sem amostras) por `tools/audio/synth_audio.py`, barramentos, zumbido por personagem, disputa, abafar no parry perfeito e no K.O., música em três camadas (base, percussão, tensão) que abrem com a vida mais baixa, batida de vida baixa e ambiência da Plataforma de Refino. Fase 8: ambiência própria das dez arenas (`assets/audio/ambience/<arena>.wav`, 10 s em laço, 22 kHz), tema sagrado (Santuário, Floresta, Cume) e tema de chefe (Cidadela e os personagens com `CharacterData.theme`: Sombra Desperta, Soberano, Ancião e as duas variantes do Predestinado; o tema do adversário vence o da arena). A variação por arena vem de `MusicData.pitch` (transposição de até três semitons, que também muda levemente o andamento) sobre os três temas. No despertar do chefe, a música passa a tocar com pelo menos `ModesConfig.boss_music_floor` de intensidade (percussão e tensão abertas).

## Regras

- **Tudo original**: efeitos gravados, desenhados ou sintetizados para o jogo, ou bibliotecas com licença compatível registrada em [ASSETS.md](../ASSETS.md). Nenhum som ou música da franquia, nem imitação reconhecível deles (o zumbido, a ignição e os temas clássicos não podem ser copiados nem "quase copiados").
- A música é **composição original**. O nome do jogo não autoriza citar nenhuma melodia existente.
- O áudio reage aos **eventos** da simulação, como os efeitos visuais.
- Posição estéreo segue o lutador na tela.
- Hit stop e câmera lenta afetam o som de forma coerente (o K.O. escurece e alonga o som; o parry perfeito abafa o mundo e deixa só a lâmina).

## Lâminas

- Na introdução individual, o som de ignição existente acompanha o início visível de cada lâmina; as duas pontas do Ceifador e as duas armas da Vespa soam nos respectivos tempos. O zumbido acompanha o comprimento aceso. Nenhum novo asset sonoro.

- **Zumbido** contínuo de cada lâmina: grave, levemente desafinado, com timbre próprio por personagem (a Forja mais grave, a Vespa mais aguda e dupla, o Ceifador com batimento de duas lâminas). Mais forte e mais agudo durante o golpe, com efeito de passagem (doppler) no arco.
- **Ignição** no começo do round e **desligar** no K.O. do derrotado (tom caindo).
- **Golpe**: "whoosh" elétrico; o forte é mais grave e longo.
- **Acerto**: estalo elétrico curto com um baque grave.
- **Bloqueio**: metálico e elétrico. **Choque**: o mais forte dos contatos. **Choque entre técnicas**: ainda mais grave e alto.
- **Parry**: tom metálico claro. **Parry perfeito**: tom claro com o mundo abafado por um instante.
- **Quebra de guarda**: estalo forte e descendente.
- **Golpe final**: baque grave, silêncio curto e a lâmina do derrotado apagando.
- **Lâmina arremessada**: zumbido girando que vai e volta.

## Disputa de lâminas

Atrito elétrico contínuo que cresce em volume e brilho com o tempo da disputa; batida metálica curta com baque grave a cada pressão; no desfecho, a lâmina que escapa (vitória) ou um raspão curto e agudo (empate). Para no desfecho, na pausa e ao sair do duelo.

## Corpo e movimento

Passos por superfície (metal, água, pedra, neve, sal, musgo), tecidos e capas, pulo e aterrissagem, esquiva (whoosh curto e agudo), esquiva de precisão (sopro curto subindo e toque agudo suave), empurrão (impacto surdo), exaustão (sopro grave descendente, baixo), ferimento (impacto forte com camada grave), ação recusada (som seco curto).

## Poderes

Cada poder tem uma identidade sonora reconhecível e curta:

- **Repulsão**: estouro de ar comprimido. **Repulsão Suprema**: estrondo grave.
- **Puxão**: sucção que se fecha. **Arremesso**: rocha arrancando, voo, impacto. **Fratura**: ronco de rocha correndo e explosões curtas (só o acerto tem som próprio, para não virar ruído).
- **Truque Mental**: dois tons quase iguais descendo (batimento) sobre um grave curto.
- **Barreira**: zumbido de campo; clareia ao absorver. **Santuário**: acorde subindo; quebra como vidro.
- **Absorção**: inspiração descendente. **Cura**: tom quente subindo. **Foco**: tom limpo e calmo.
- **Raio**: crepitar elétrico contínuo com estalos por pulso. **Estrangular**: pressão grave e sufocada. **Congelar**: cristalização e estalo ao quebrar.
- **Tempestade**: crepitar subindo na invocação, trovão longo, estalo curto em cada marca, estalo seco com estrondo em cada raio.
- **Telecinese em Massa**: ronco subindo, rocha rachando, assobio descendo a cada marca, estrondo no impacto.
- **Ira**: tom grave crescente; cada armadura gasta, baque grave rasgado.
- **Dreno**: sucção grave. **Arsenal**: ronco subindo, lançamento cortante, bloqueio metálico.
- **Corte de Fluxo**: corte com zumbido subindo; devolução com tom metálico claro.
- **Resistido**: impacto abafado numa "parede".

> Implementado na fase 5: todos os sons acima sintetizados em `assets/audio/powers/` (Fratura, Tempestade e Telecinese têm som na invocação, nas marcas e nos impactos; a Barreira, o Raio e o Dreno são loops enquanto o canal dura). Prioridade de mixagem: poderes 3 dB abaixo dos golpes.

## Interface

Tique curto ao navegar, tom curto ao confirmar, tom de voltar, som de ação recusada. Segredos da abertura: acorde grave (O Equilíbrio) e arpejo claro subindo (O Guarda-roupa).

## Música

- Trilha original, épica e tensa: percussão, cordas graves, metais contidos e, se a produção permitir, coro. Cada arena com um tema ou variação própria, e a música do menu e da História com identidade.
- **Música dinâmica** em camadas: quanto menor a vida do lutador mais ferido, mais a música abre (mais camadas, filtro mais claro, percussão mais presente) e mais aparece uma camada de tensão. Volta ao normal ao sair do duelo.
- **Batida com vida baixa**: com o jogador abaixo de 25% de vida, um "tum-tum" grave a cada ~0,9 s (em 2 jogadores, segue quem tiver menos vida).
- **K.O.**: a música abaixa (silêncio curto) e volta depois.
- **Disputa de lâminas**: a música recua para dar espaço ao atrito.
- **Chefe**: tema próprio para a Sombra Desperta, o Soberano, o Ancião e o Predestinado; o despertar do chefe muda a camada.

## Ambiência por arena

Vapor e ecos metálicos (Refino), água e gotas (Santuário), gotejar e ressonância de cristal (Mina), chuva e cidade distante (Telhado), silêncio quase total e zumbido de estrutura (Anel), insetos e folhas (Floresta), vento quente e areia (Salinas), vento forte e motores (Convés), nevasca e sinos distantes (Cume), salão vazio e reverberação longa (Cidadela).

## Voz

Fora do escopo inicial: as falas são texto. Se entrar voz no futuro, em PT-BR e EN, com elenco original e registro em ASSETS; sem imitar vozes de atores da franquia.

## Mixagem e opções

Barramentos separados para música, efeitos, interface e ambiência, com volumes nas Opções e opção de desligar som e música. Prioridade de mixagem: golpes e defesas > poderes > corpo > ambiência > música.
