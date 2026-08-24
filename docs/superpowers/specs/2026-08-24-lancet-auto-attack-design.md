# Quarto incremento: ataque automático da Lanceta de Sangria

## Objetivo

Adicionar a primeira arma automática do jogador. A Lanceta de Sangria localizará o inimigo mais próximo dentro do alcance e lançará periodicamente um projétil reto que desaparece ao tocar um inimigo ou completar seu alcance máximo.

Este incremento valida aquisição de alvo, composição de arma, instanciação de projéteis e detecção de contato. Ele não introduz dano, vida ou morte.

## Estrutura

O incremento adicionará:

```text
scenes/
├── lancet.tscn
└── lancet_weapon.tscn
scripts/
├── lancet.gd
└── lancet_weapon.gd
```

Também serão modificados:

- `scenes/player.tscn`, para instanciar `LancetWeapon` como filha do jogador.
- `scenes/enemy.tscn`, para tornar o inimigo detectável pelo projétil sem voltar a ser sólido.

`player.gd` continuará responsável somente pela movimentação.

## Composição da arma

`lancet_weapon.tscn` terá:

- Nó raiz `LancetWeapon` do tipo `Node2D`.
- Script `lancet_weapon.gd` anexado ao nó raiz.
- Um filho `Timer` com `wait_time = 1.0`, repetição habilitada e `autostart = true`.
- Signal `timeout` conectado a `_on_attack_timer_timeout()`.
- Referência exportada a `lancet.tscn` como `PackedScene`.
- Alcance de ataque exportado com valor inicial de `600.0 px`.

A cena será instanciada como filha direta do nó raiz de `player.tscn`, herdando sua posição global.

## Seleção de alvo

A cada timeout, a arma consultará os nós do grupo `enemies` e calculará a distância global até cada `Node2D` válido.

Será escolhido o inimigo com a menor distância. Se não houver inimigo ou se o mais próximo estiver além de `600.0 px`, nenhum projétil será criado naquele timeout.

Em caso de empate exato, o primeiro nó encontrado no grupo poderá ser escolhido. Não haverá prioridade por vida, direção, tempo de existência ou visibilidade.

## Composição da lanceta

`lancet.tscn` terá:

- Nó raiz `Lancet` do tipo `Area2D`.
- Script `lancet.gd` anexado ao nó raiz.
- `Polygon2D` chamado `Visual`, representando um retângulo claro de `16 × 4 px`.
- `CollisionShape2D` com `RectangleShape2D` de `16 × 4 px`.
- Signal `body_entered` conectado a `_on_body_entered()`.

O projétil usará:

- Velocidade inicial: `500.0 px/s`.
- Alcance máximo: `600.0 px`.
- Camada física: `0`, para não ser tratado como corpo sólido ou alvo.
- Máscara física: camada `2`, destinada aos inimigos.

## Lançamento e trajetória

Ao disparar:

1. A arma instancia `lancet.tscn` como filha da cena principal atual.
2. Posiciona a lanceta na posição global da arma.
3. Calcula a direção normalizada da arma até a posição atual do alvo.
4. Chama `launch(direction)` no projétil.

A lanceta armazena essa direção no momento do lançamento. Ela não acompanha mudanças posteriores de posição do inimigo.

A cada frame de física, o projétil:

1. Calcula `direction * speed * delta`.
2. Soma o deslocamento à posição global.
3. Acumula o comprimento percorrido.
4. Executa `queue_free()` ao atingir ou ultrapassar `600.0 px`.

Sua rotação visual será alinhada ao ângulo da direção durante `launch()`.

## Detecção de contato

O inimigo continuará com `collision_mask = 0`, portanto não bloqueará jogador, outros inimigos ou cenário. Sua `collision_layer` mudará de `0` para a camada `2`.

O jogador permanece na camada padrão `1` e não consulta a camada `2`; assim, continuará atravessando inimigos livremente.

A lanceta terá `collision_layer = 0` e `collision_mask = 2`. Quando o signal `body_entered` detectar um inimigo, o projétil executará `queue_free()`.

Não haverá dano ou alteração no inimigo. A colisão serve apenas para validar o acerto e encerrar o projétil.

## Fluxo

```text
Timer completa 1 segundo
→ arma consulta grupo enemies
→ escolhe inimigo mais próximo
→ valida distância de até 600 px
→ instancia Lancet
→ define direção inicial
→ projétil percorre linha reta
→ toca inimigo ou completa 600 px
→ projétil é removido
```

## Tratamento de estados

- Nenhum inimigo: timeout ignorado sem erro.
- Inimigos somente fora do alcance: timeout ignorado sem erro.
- Um ou mais inimigos no alcance: um único projétil é criado contra o mais próximo.
- Alvo se move após o disparo: projétil mantém sua trajetória original.
- Projétil toca inimigo: projétil desaparece; inimigo permanece inalterado.
- Projétil não toca inimigo: desaparece ao completar `600.0 px`.
- Alvo removido após o disparo: projétil continua na direção armazenada até acertar outro inimigo ou terminar o alcance.

## Fora do escopo

- Dano, vida, morte e drops
- XP, níveis e upgrades
- Ramificações ou transmutação da Lanceta
- Perfuração, fragmentação e múltiplos acertos
- Crítico, knockback e status hemorrágico
- Pooling de projéteis
- Predição de movimento e projétil teleguiado
- Animação, partículas, áudio e arte definitiva
- Interface, cooldown visual ou indicador de alvo
- Outras armas

## Verificação e critérios de aceite

O incremento será verificado no Godot 4.7.1, confirmando que:

1. O projeto abre e executa sem erros.
2. Nenhuma lanceta é criada sem inimigos no alcance.
3. Exatamente uma lanceta é criada por timeout quando existe alvo a até `600.0 px`.
4. Entre múltiplos inimigos, a direção inicial aponta para o mais próximo.
5. A lanceta viaja em linha reta a `500.0 px/s`.
6. O projétil mantém sua direção mesmo quando o alvo se move.
7. A lanceta desaparece ao tocar o primeiro inimigo.
8. Uma lanceta que não acerta desaparece ao atingir `600.0 px` de percurso.
9. O acerto não remove nem altera o inimigo.
10. O jogador continua atravessando e contornando inimigos livremente.
11. Spawn, perseguição, fundo, câmera e movimentação continuam funcionando.
12. O output permanece sem erros durante disparo, contato e encerramento.
13. Nenhum item listado como fora do escopo foi implementado.

Após o playtest e a aprovação do usuário, uma mensagem de commit possível será `feat: add lancet auto attack`. O agente não executará operações de staging, commit, push ou alteração de histórico.
