# Paletas

Task 21. Aprovada pelo autor, que manteve as cores atuais, gerada do traje Original em `data/characters/`. A cor-base de cada slot é a atual; o que muda é a escala de tons.

## Regra

**16 cores por lutador**, dentro do teto de 12 a 16: manto 3, corpo 3, acabamento 2, pele 2, cabelo 2, metal 2, couro 1, olhos 1. Três tons só onde há área grande para sombrear; slots pequenos usam menos. Sombra com leve desvio de matiz para o frio; contorno é o tom mais escuro do slot vizinho.

Os trajes alternativos usam os mesmos slots e a mesma regra, e o rig troca as cores por traje, como hoje. Cor da lâmina não pertence à paleta do corpo: é desenhada à parte e não conta nas 16.

## Tema dos Caminhos (só interface)

| Token | Aurora | Eclipse |
| --- | --- | --- |
| Destaque | `#5aa2ff` | `#ff4458` |
| Painel | `#0b1424` | `#1a0d14` |
| Elevado | `#12203a` | `#2c1420` |
| Borda | `#223555` | `#4d2233` |

Nenhuma cor indica herói ou vilão; o tema aparece só na seleção de lutador e nas telas de Caminho.

## Conferência de contraste

**Só informativa.** O autor gostou das cores atuais e elas ficam. Os casos abaixo ocorrem quase só no acabamento, a menor área; núcleo branco e halo (task 23) já separam a lâmina da roupa. Reavaliar no piloto só se a lâmina se perder em captura.

Critério: contraste de pelo menos 2,0 entre a lâmina padrão e manto, corpo e acabamento, e manto saturado sem o mesmo matiz da lâmina. O núcleo branco sempre passa; a conta usa a cor da lâmina, o caso difícil.

| Lutador | Lâmina | Menor contraste | Mesmo matiz do manto |
| --- | --- | --- | --- |
| Vespa | `#ffd23f` | 1.4 | não |
| Espelho | `#e8eeff` | 1.2 | não |
| Haste | `#a46bff` | 1.8 | não |
| Brasa | `#ff7a2a` | 1.7 | sim |
| Garça | `#5fffc0` | 1.6 | não |
| Corsária | `#3f6bff` | 1.8 | não |
| Lince | `#e0ff3f` | 1.6 | não |
| Ancião | `#3fd07a` | 1.0 | não |
| Predestinado | `#6fb2ff` | 1.0 | não |

## Paletas por lutador

### Guardião

Caminho: Aurora. Lâmina padrão: `#7fe4ff`. Menor contraste entre a lâmina e o tecido: 4.5. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#493b31` `#6b5a48` `#8b785e` |
| Corpo | `#1f1b19` `#2e2925` `#3c3630` |
| Acabamento | `#413024` `#5a4632` |
| Pele | `#855d49` `#b08a6e` |
| Cabelo | `#352118` `#4a3222` |
| Metal | `#697782` `#9aa3ad` |
| Couro | `#3a2c22` |
| Olhos | `#ffb22e` |

### Sombra

Caminho: Eclipse. Lâmina padrão: `#ff3f9e`. Menor contraste entre a lâmina e o tecido: 4.3. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#15161c` `#1f2029` `#282935` |
| Corpo | `#0c0d11` `#121319` `#171820` |
| Acabamento | `#1e2027` `#2a2b36` |
| Pele | `#63514b` `#8a7468` |
| Cabelo | `#0e1013` `#14151b` |
| Metal | `#596168` `#7d8590` |
| Couro | `#18181e` |
| Olhos | `#ffb22e` |

### Bastião

Caminho: Aurora. Lâmina padrão: `#9dff3f`. Menor contraste entre a lâmina e o tecido: 7.9. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#2a3025` `#3d4636` `#4e5b46` |
| Corpo | `#161813` `#1f231c` `#282e24` |
| Acabamento | `#20221b` `#2c2f26` |
| Pele | `#4f382e` `#6e5240` |
| Cabelo | `#1e1511` `#2a1f18` |
| Metal | `#5a6055` `#7c8576` |
| Couro | `#1c1c18` |
| Olhos | `#ffb22e` |

### Vespa

Caminho: Aurora. Lâmina padrão: `#ffd23f`. Menor contraste entre a lâmina e o tecido: 1.4. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#3f3023` `#5c4a33` `#786342` |
| Corpo | `#1d1611` `#2a2219` `#372e20` |
| Acabamento | `#a7814d` `#c9b48a` |
| Pele | `#9e6545` `#c49a78` |
| Cabelo | `#634831` `#8a6a44` |
| Metal | `#697782` `#9aa3ad` |
| Couro | `#3a2c20` |
| Olhos | `#ffb22e` |

### Espelho

Caminho: Aurora. Lâmina padrão: `#e8eeff`. Menor contraste entre a lâmina e o tecido: 1.2. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#757d90` `#b9bcc7` `#f9f9fa` |
| Corpo | `#272a30` `#3a3d47` `#4b4e5c` |
| Acabamento | `#939bac` `#d9dbe2` |
| Pele | `#7e6254` `#a88f7c` |
| Cabelo | `#232323` `#303030` |
| Metal | `#738496` `#aeb6c2` |
| Couro | `#2a2c33` |
| Olhos | `#ffb22e` |

### Haste

Caminho: Eclipse. Lâmina padrão: `#a46bff`. Menor contraste entre a lâmina e o tecido: 1.8. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#272331` `#3b3348` `#4e425e` |
| Corpo | `#121118` `#1c1924` `#25202f` |
| Acabamento | `#4b4160` `#6c5a86` |
| Pele | `#705447` `#9c7a62` |
| Cabelo | `#1d1823` `#2a2230` |
| Metal | `#636d79` `#8e96a3` |
| Couro | `#25202c` |
| Olhos | `#ffb22e` |

### Brasa

Caminho: Eclipse. Lâmina padrão: `#ff7a2a`. Menor contraste entre a lâmina e o tecido: 1.7. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#3d1a14` `#5a2c1e` `#753e27` |
| Corpo | `#180c0a` `#24140f` `#2f1c13` |
| Acabamento | `#b1956d` `#d8cdb6` |
| Pele | `#65443a` `#8c6450` |
| Cabelo | `#130c0a` `#1a120e` |
| Metal | `#62686d` `#8a8f96` |
| Couro | `#2a1a14` |
| Olhos | `#ffb22e` |

### Forja

Caminho: Eclipse. Lâmina padrão: `#ff4038`. Menor contraste entre a lâmina e o tecido: 2.1. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#322621` `#4a3a30` `#604d3e` |
| Corpo | `#16110e` `#211a15` `#2b231b` |
| Acabamento | `#4c382e` `#6a5240` |
| Pele | `#735444` `#a07a5e` |
| Cabelo | `#2a1c16` `#3a2a1e` |
| Metal | `#62686d` `#8a8f96` |
| Couro | `#2a1f18` |
| Olhos | `#ffb22e` |

### Garça

Caminho: Aurora. Lâmina padrão: `#5fffc0`. Menor contraste entre a lâmina e o tecido: 1.6. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#203438` `#2f4a52` `#3d5d6b` |
| Corpo | `#0f191d` `#16232a` `#1d2c37` |
| Acabamento | `#659197` `#9fb8bf` |
| Pele | `#a5664c` `#c8a088` |
| Cabelo | `#211917` `#2e2420` |
| Metal | `#697782` `#9aa3ad` |
| Couro | `#1e262b` |
| Olhos | `#ffb22e` |

### Ceifador

Caminho: Eclipse. Lâmina padrão: `#ff2a2a`. Menor contraste entre a lâmina e o tecido: 2.7. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#130e10` `#1c1517` `#241b1d` |
| Corpo | `#0a0809` `#0f0c0d` `#131011` |
| Acabamento | `#581620` `#7a1f24` |
| Pele | `#4f3f3b` `#6e5a52` |
| Cabelo | `#0c0c0c` `#111111` |
| Metal | `#4f5459` `#6e737c` |
| Couro | `#1a1214` |
| Olhos | `#ffb22e` |

### Eco

Caminho: Eclipse. Lâmina padrão: `#ffa6e0`. Menor contraste entre a lâmina e o tecido: 6.7. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#17161d` `#23202b` `#2e2a38` |
| Corpo | `#0c0b10` `#121017` `#18151e` |
| Acabamento | `#292630` `#3a3542` |
| Pele | `#634c45` `#8a6e60` |
| Cabelo | `#0f0e11` `#151318` |
| Metal | `#585c64` `#7a7f8a` |
| Couro | `#19161c` |
| Olhos | `#ffb22e` |

### Corsária

Caminho: Eclipse. Lâmina padrão: `#3f6bff`. Menor contraste entre a lâmina e o tecido: 1.8. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#482f1f` `#6a4a2e` `#8a653c` |
| Corpo | `#1e252c` `#2c3440` `#394253` |
| Acabamento | `#a2713b` `#c9a46a` |
| Pele | `#895744` `#b48468` |
| Cabelo | `#1e110e` `#2a1a14` |
| Metal | `#62696f` `#8a9098` |
| Couro | `#3a2a20` |
| Olhos | `#ffb22e` |

### Lince

Caminho: Aurora. Lâmina padrão: `#e0ff3f`. Menor contraste entre a lâmina e o tecido: 1.6. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#2a3631` `#3e4f4a` `#516762` |
| Corpo | `#151d1c` `#1f2a2a` `#283637` |
| Acabamento | `#849774` `#b7c4b0` |
| Pele | `#633c2e` `#8a5a40` |
| Cabelo | `#0e0c0c` `#141010` |
| Metal | `#6b797d` `#9aa4a8` |
| Couro | `#2a2420` |
| Olhos | `#ffb22e` |

### Soberano

Caminho: Eclipse. Lâmina padrão: `#ff3040`. Menor contraste entre a lâmina e o tecido: 3.4. Cores: 16. Trajes que trocam a paleta: legacy.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#16131b` `#211c27` `#2c2433` |
| Corpo | `#0d0b0f` `#131016` `#19151d` |
| Acabamento | `#292430` `#3a3242` |
| Pele | `#5a4b47` `#7d6a62` |
| Cabelo | `#0c0c0c` `#111111` |
| Metal | `#63594c` `#8a7f6a` |
| Couro | `#18141c` |
| Olhos | `#ffb22e` |

### Ancião

Caminho: Aurora. Lâmina padrão: `#3fd07a`. Menor contraste entre a lâmina e o tecido: 1.0. Cores: 16. Trajes que trocam a paleta: hermit.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#5e523f` `#8a7c5c` `#aba080` |
| Corpo | `#29261e` `#3c3a2c` `#4e4d39` |
| Acabamento | `#a7884d` `#c9b98a` |
| Pele | `#8f674b` `#b89878` |
| Cabelo | `#b3a995` `#e8e6df` |
| Metal | `#7b6d53` `#a59a7a` |
| Couro | `#3a3428` |
| Olhos | `#ffb22e` |

### Predestinado

Caminho: Aurora. Lâmina padrão: `#6fb2ff`. Menor contraste entre a lâmina e o tecido: 1.0. Cores: 16. Trajes que trocam a paleta: dusk, fallen, duel, legacy.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#95866e` `#c9c3b5` `#f9f9f7` |
| Corpo | `#1d2127` `#2a2f3a` `#373c4b` |
| Acabamento | `#0991ff` `#6fb2ff` |
| Pele | `#855d49` `#b08a6e` |
| Cabelo | `#2a1d17` `#3a2a20` |
| Metal | `#697782` `#9aa3ad` |
| Couro | `#2a2622` |
| Olhos | `#ffb22e` |

### Predestinado Eclipse

Caminho: Eclipse. Lâmina padrão: `#ff2b45`. Menor contraste entre a lâmina e o tecido: 2.1. Cores: 16. Trajes que trocam a paleta: nenhum.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#95866e` `#c9c3b5` `#f9f9f7` |
| Corpo | `#1d2127` `#2a2f3a` `#373c4b` |
| Acabamento | `#631e2d` `#8a2a36` |
| Pele | `#855d49` `#b08a6e` |
| Cabelo | `#2a1d17` `#3a2a20` |
| Metal | `#697782` `#9aa3ad` |
| Couro | `#2a2622` |
| Olhos | `#ffb22e` |

### Sombra Desperta

Caminho: Eclipse. Lâmina padrão: `#ff3f9e`. Menor contraste entre a lâmina e o tecido: 4.3. Cores: 16. Trajes que trocam a paleta: nenhum.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#0c0d11` `#121219` `#181720` |
| Corpo | `#07080b` `#0b0b10` `#0f0e15` |
| Acabamento | `#1e2027` `#2a2b36` |
| Pele | `#63514b` `#8a7468` |
| Cabelo | `#0c0c0f` `#101015` |
| Metal | `#44484f` `#5e636e` |
| Couro | `#121218` |
| Olhos | `#ffb22e` |

### Coldre

Caminho: Aurora. Lâmina padrão: `#7fe4ff`. Menor contraste entre a lâmina e o tecido: 4.5. Cores: 16. Trajes que trocam a paleta: traveler, sentinel.

| Slot | Tons (sombra → luz) |
| --- | --- |
| Manto | `#493b31` `#6b5a48` `#8b785e` |
| Corpo | `#1f1b19` `#2e2925` `#3c3630` |
| Acabamento | `#413024` `#5a4632` |
| Pele | `#855d49` `#b08a6e` |
| Cabelo | `#352118` `#4a3222` |
| Metal | `#697782` `#9aa3ad` |
| Couro | `#3a2c22` |
| Olhos | `#ffb22e` |

O protagonista usa as bases Guardião, Sombra e Garça e os visuais da História. Caído, Duelo, Legado e Ocaso ficam por código, com cores nos dados.
