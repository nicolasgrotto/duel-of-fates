# AUDIO — Som e música

Segue [DESIGN.md](../DESIGN.md). Som e música são parte da sensação do duelo: o choque precisa ser **ouvido** tanto quanto visto.

> Implementado na fase 3: sons sintetizados (sem amostras) por `tools/audio/synth_audio.py`, barramentos, zumbido por personagem, disputa, abafar no parry perfeito e no K.O., música em três camadas (base, percussão, tensão) que abrem com a vida mais baixa, batida de vida baixa e ambiência da Plataforma de Refino. Fase 8: ambiência própria das dez arenas (`assets/audio/ambience/<arena>.wav`, 10 s em laço, 22 kHz), tema sagrado (Santuário, Floresta, Cume) e tema de chefe (Cidadela e os personagens com `CharacterData.theme`: Sombra Desperta, Soberano, Ancião e as duas variantes do Predestinado; o tema do adversário vence o da arena). A variação por arena vem de `MusicData.pitch` (transposição de até três semitons, que também muda levemente o andamento) sobre os três temas. No despertar do chefe, a música passa a tocar com pelo menos `ModesConfig.boss_music_floor` de intensidade (percussão e tensão abertas).

## Direção da versão 1.2 (decisão do autor)

**Só synth sombrio e atmosférico:** pads, baixos graves, drones, arpejos, coro sintético, percussão e impactos eletrônicos. **Sem camadas orquestrais e sem serviços pagos de música.** Produção por síntese em numpy e, se precisar, MIDI com sons de synth. Material de terceiros só com licença livre (CC0 ou permissiva), com licença e atribuição registradas em `ASSETS.md`; faixa sem licença confirmada não entra. Uma faixa de teste do menu, de cerca de 30 s, passa pelo autor antes das demais. Detalhes por faixa em `docs/art-briefs/audio/_direction.md`.

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

### Operações de blaster (task 16)

Task 18 reutiliza confirmação de UI para onda/fase, impacto metálico para barreiras/torres, tiros existentes para aliados e camadas industriais durante combate. Sem novas amostras ou música. Pausa/sair continuam suspendendo e liberando players locais; volume ouvido não interfere em percepção ou objetivos.

Reutiliza exclusivamente o banco original: tiro/desvio/devolução/acerto `bolt_*`, esquiva e confirmação de precisão existentes, sons de Repulsão/Puxão/Barreira e impacto metálico para cobertura. Preparação inimiga usa o aviso curto existente da Infiltração; supera passos em volume, sem novo áudio ou imitação de franquia. Superaquecimento usa a recusa seca uma vez na entrada, nunca a cada tick segurado. Música e ambiência industriais existentes; pausa suspende áudio local e sair encerra seus players. Áudio consome eventos e não altera percepção, calor ou preparação.

### Infiltração (tasks 10–12)

Passos metálicos por eventos de distância percorrida, com ritmo maior ao correr e volume menor em furtivo; nunca ruído sonoro que altera a simulação. Golpe, impacto, zumbido e disparos reutilizam os sons originais do banco (`swing_light`, `hit_light`, `blade_hum`, `bolt_shot`, `bolt_deflect`, `bolt_reflect`, `bolt_hit`), sem amostras novas na task 10. Som de deflexão claro, devolução com tom ascendente. Prioridade: disparo próximo/defesa > passos > ambiência. Pan segue a posição no quadro, sem mudar regras.

Na task 11, a detecção recebe eventos de ruído da simulação, e não o volume ouvido. Suspeita usa um aviso curto e alerta um padrão pulsado original; alarmes contínuos pertencem à task 11 e serão sintetizados/registrados quando implementados. No treino o alarme fica inativo, sem sirene ou música nova. Pausa silencia o zumbido; sair libera o player do modo.

Task 11: passos dos inimigos reutilizam o metal existente. Aviso de suspeita curto e sirene pulsada de 1 s são sintetizados por `infiltration_sounds` em `synth_audio.py`, sem amostras; sirene local do modo repete somente com alarme ativo. Música usa as três camadas do tema original de duelo: baixa intensidade em furtividade, maior com inimigos alertados, máxima no alarme. Pausa suspende música/sirene/zumbido e sair encerra os players locais. A música não altera o duelo nem a simulação.

Task 12: briefings e resultados reutilizam os sons de navegação; copiar informação e recrutar reutilizam `ui_confirm`. Não há música ou amostra nova. As camadas locais cessam ao abrir o resultado. A sirene segue o estado atual; a classificação Furtivo/Direto usa o histórico determinístico, sem depender do áudio.

### Duelo

Passos por superfície (metal, água, pedra, neve, sal, musgo), tecidos e capas, pulo e aterrissagem, esquiva (whoosh curto e agudo), esquiva de precisão (sopro curto subindo e toque agudo suave), empurrão (impacto surdo), exaustão (sopro grave descendente, baixo), ferimento (impacto forte com camada grave), ação recusada (som seco curto).

## Combate de naves (task 13)

Sete sons originais por `synth_audio.py::space_sounds`, com semente local e sem amostras: motor em laço discreto de 1 s (grave estável com ar filtrado), tiro seco de 0,10 s, preparação ascendente de 0,30 s, impulso de 0,28 s, escudo vítreo curto de 0,18 s, impacto metálico de 0,16 s e explosão grave de 0,42 s. Sem sons reconhecíveis de naves de outra obra. Volume: dano/aviso acima do motor, tiros abaixo das lâminas do duelo. Banco local com vozes pré-alocadas, barramentos Effects/Ambience já existentes; posição estéreo segue o quadro. Motor sobe apenas com propulsão/impulso. Pausa suspende motor e encerra efeitos pendentes; sair libera tudo. Sem música nova nesta etapa. Som e VFX só consomem estados/eventos, nunca controlam o voo.

Task 14 reutiliza o banco de voo e acrescenta apenas `space/missile.wav`, sopro grave curto de 0,24 s com semente local e envelope, sintetizado sem amostras. Tiros de leque mantêm o timbre existente; interceptação reutiliza impacto de casco. A preparação avisa antes de míssil ou leque. Sem trilha nova ou imitação de som de franquia. Resultado/sair encerra vozes locais; pausa silencia motor e efeitos, e opções globais de volume continuam valendo.

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
- **Corte Projetado**: corte com zumbido subindo; devolução com tom metálico claro.
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

## Finalizações em etapas

Cada coreografia de finalização (`FinisherMotion`) traz uma lista de deixas de som (`FinisherCue`: instante, som do banco, volume e tom). Quem corta emite a deixa (`FighterView.finisher_cue`) e o `DuelAudio` toca o som. Só sons já existentes no banco: golpes (`swing_light`, `swing_heavy`), acertos (`hit_light`, `hit_heavy`), o puxão (`power_pull`), a ignição e o apagar da lâmina emprestada (`ignition`, `extinguish`). O estilo do personagem estica as deixas junto com a animação.

### Instinto Superior

Ativação: acorde breve e claro em três parciais, com sopro suave; cada esquiva: sopro lateral curto com dois tons discretos, distinguível da esquiva de precisão comum. Sons originais gerados por funções próprias em tools/audio/synth_audio.py, sem amostras. Volume de poder abaixo das lâminas, sem abafar o mundo e sem loop permanente.

### Singularidade Devastadora (task 05)

Quatro amostras originais em synth_audio.py::singularity_sounds, com semente própria: criação grave ascendente (power_singularity), extração curta de pedra e ar (power_singularity_extract), arremesso com queda de frequência (power_singularity_throw), impacto grave seco (power_singularity_impact). A marca reaproveita power_mark_tick; cada onda aciona o aviso, cada extração seu estalo. Sem loop adicional, ruído de franquia ou dependência externa. Volume/canais do DuelAudio existentes; efeitos reduzidos não removem os avisos sonoros.

### Disparos (task 06)

Task 15: armas de coldre reutilizam os sons originais de disparo, impacto e desvio; `BlasterData` referencia os ids existentes e `BoltData.pitch` define afinação. Sem novos arquivos de áudio ou som durante o saque silencioso.

Quatro sons originais em `synth_audio.py::bolt_sounds`, com semente própria: tiro seco e curto com queda rápida de frequência (`bolt_shot`), desvio na lâmina como um chiado curto e metálico (`bolt_deflect`), devolução com o chiado e um tom ascendente (`bolt_reflect`), acerto abafado e curto (`bolt_hit`). Nenhum lembra o som de armas da franquia: sem o "pew" ressonante com mola. Volume abaixo das lâminas.

Família Versáteis (tasks 07 e 08): os personagens usam os mesmos sons, com afinação por disparo (`BoltData.pitch`): a Corsária um pouco mais grave (0,92), o Lince mais agudo e seco (1,12). A Rajada Desestabilizadora reaproveita os sons de disparo e de golpe.
