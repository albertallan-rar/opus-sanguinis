# Vida do jogador e dano por contato

## Objetivo

Fazer os inimigos representarem uma ameaça real por meio de dano contínuo por contato. O jogador terá vida limitada, acompanhamento visual no HUD e um estado de morte, sem implementar ainda a tela de derrota.

## Vida do jogador

`Player` será a fonte única do estado de vida:

- vida máxima inicial: `10`;
- vida atual inicial: `10`;
- `take_damage(amount: int)` reduz a vida até o mínimo de zero;
- `health_changed(current_health: int, maximum_health: int)` é emitido após cada dano que efetivamente altera a vida;
- `died` é emitido exatamente uma vez quando a vida chega a zero;
- depois da morte, novos danos são ignorados;
- o jogador mantém `velocity = Vector2.ZERO` e não processa entrada de movimento depois da morte.

Valores de dano iguais ou menores que zero são ignorados. Cura, regeneração e aumento de vida máxima não fazem parte deste incremento.

## Dano do inimigo

Cada `Enemy` terá uma área filha chamada `DamageArea` e um timer filho chamado `DamageTimer`:

- dano por contato: `1`;
- intervalo entre danos: `1,0s`;
- ao detectar a entrada do jogador, causa dano imediatamente e inicia o timer;
- a cada timeout, causa novo dano se o jogador ainda estiver dentro da área;
- ao detectar a saída do jogador, remove a referência de contato e para o timer;
- ao morrer ou sair da árvore, o inimigo deixa de causar dano naturalmente com a destruição de seus filhos.

A área usa `collision_layer = 0` e `collision_mask = 1`, detectando o `CharacterBody2D` do jogador, que permanece na camada padrão 1. A colisão física entre jogador e inimigo continua desativada, preservando o movimento e a separação já validados.

## Contato e múltiplos inimigos

Cada inimigo administra seu próprio contato e timer. Dois inimigos tocando o jogador causam dois danos imediatos e continuam causando dano independentemente a cada segundo.

O inimigo guarda no máximo uma referência ao jogador dentro de sua área. Eventos duplicados de entrada não aplicam dano adicional nem reiniciam o ciclo enquanto o mesmo jogador já estiver registrado.

## Estado de morte

Quando a vida chega a zero:

- o jogador interrompe o movimento;
- o sinal `died` é emitido uma vez;
- XP, nível e atributos da Lanceta permanecem armazenados;
- inimigos, spawner e ataques continuam processando;
- nenhum painel novo é aberto.

A pausa, tela de derrota e reinício serão tratados no incremento seguinte.

## HUD

O HUD acrescenta `Vida: 10 / 10` no topo esquerdo e mantém os indicadores existentes. A ordem será:

1. vida;
2. nível;
3. XP;
4. dano da Lanceta;
5. intervalo da Lanceta.

O texto é inicializado a partir do jogador e atualizado pelo sinal `health_changed`.

## Interface visual

O jogador e os inimigos continuam usando os visuais temporários atuais. Não haverá barra gráfica, efeito de impacto, piscar, knockback ou animação de morte neste incremento. O contador textual permitirá validar todos os danos.

## Casos-limite

- Dano maior que a vida restante resulta em vida zero, nunca negativa.
- `take_damage(0)` e valores negativos não alteram a vida nem emitem sinais.
- Danos recebidos após a morte não emitem `health_changed` ou `died` novamente.
- Sair da área antes de um segundo impede o próximo dano.
- Reentrar causa novo dano imediato e inicia um novo ciclo de um segundo.
- Vários inimigos aplicam dano e temporização de forma independente.

## Validação

Os testes automatizados devem comprovar:

- estado inicial `10 / 10`;
- redução e emissão de `health_changed`;
- limite em zero e emissão única de `died`;
- rejeição de dano não positivo e dano após morte;
- interrupção do movimento após morte;
- dano imediato na entrada da `DamageArea`;
- repetição após timeout enquanto existe contato;
- ausência de repetição depois da saída;
- independência entre dois inimigos;
- inicialização e atualização do HUD;
- manutenção dos testes existentes de XP, upgrades e combate.

A validação manual deve confirmar que encostar em um inimigo reduz a vida imediatamente, permanecer em contato reduz novamente a cada segundo e afastar-se interrompe o dano.

## Fora do escopo

- tela de derrota, pausa e reinício;
- invulnerabilidade global após dano;
- cura, regeneração e melhoria de vida;
- knockback, feedback visual e sonoro;
- barra gráfica de vida;
- dano de projéteis inimigos.
