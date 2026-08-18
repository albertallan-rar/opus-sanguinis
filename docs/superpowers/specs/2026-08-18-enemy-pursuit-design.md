# Segundo incremento: perseguição de um inimigo

## Objetivo

Adicionar um único inimigo placeholder que identifica o jogador e o persegue continuamente. Este incremento valida o primeiro comportamento autônomo do mundo sem antecipar spawn, combate ou atributos.

## Estrutura

O incremento adicionará:

```text
scenes/
└── enemy.tscn
scripts/
└── enemy.gd
```

Também serão modificados:

- `scenes/player.tscn`, para incluir o jogador no grupo `player`.
- `scenes/main.tscn`, para instanciar exatamente um inimigo.

## Composição do inimigo

`enemy.tscn` terá:

- Nó raiz `Enemy` do tipo `CharacterBody2D`.
- `Polygon2D` chamado `Visual`, representando um quadrado roxo de `32 × 32 px`.
- `CollisionShape2D` com `RectangleShape2D` de `32 × 32 px`.
- Script `enemy.gd` anexado ao nó raiz.

O placeholder não terá animação, arte definitiva, barra de vida ou efeitos.

## Aquisição do alvo

O nó raiz de `player.tscn` pertencerá ao grupo `player`.

Em `_ready()`, `enemy.gd` consultará a `SceneTree` pelo primeiro nó do grupo `player`. O resultado será armazenado como `Node2D` anulável.

Este incremento possui somente um jogador. Não haverá seleção entre múltiplos alvos, troca de alvo nem busca repetida. Se nenhum jogador existir quando `_ready()` executar, o inimigo permanecerá parado sem gerar erro.

O grupo evita adicionar um script à cena principal apenas para conectar dois nós. A decisão poderá ser revisada quando o sistema de spawn exigir coordenação explícita.

## Perseguição

O inimigo terá velocidade exportada e explicitamente tipada com valor inicial de `120.0 px/s`. O jogador continuará com `240.0 px/s`, permitindo que consiga fugir.

A cada atualização de física:

1. Se não houver alvo, `velocity` será definida como `Vector2.ZERO` e o inimigo não se moverá.
2. Se houver alvo, o inimigo calculará o vetor do próprio `global_position` até o `global_position` do jogador.
3. O vetor será normalizado com `direction_to()`.
4. A direção será multiplicada pela velocidade.
5. O resultado será atribuído a `velocity`.
6. O inimigo chamará `move_and_slide()`.

O uso de uma direção normalizada mantém a mesma velocidade em movimentos retos e diagonais.

## Posicionamento inicial

`main.tscn` instanciará exatamente um `Enemy` na mesma coordenada vertical do jogador e `400 px` à direita de sua posição inicial. A posição concreta será calculada a partir da posição do jogador atualmente salva na cena.

Não haverá área de spawn, aleatoriedade ou respawn.

## Interação física

O inimigo manterá seu `CollisionShape2D`, mas usará `collision_layer = 0` e `collision_mask = 0`. Portanto, ele não será um obstáculo sólido e não bloqueará nem deslizará junto com o jogador.

O contato não causará dano, empurrão programado, invencibilidade, morte ou qualquer outra consequência de combate. Quando dano por contato for implementado, sua detecção será separada da colisão física, usando uma `Area2D`.

## Tratamento de estados

- Sem jogador no grupo `player`: inimigo parado e sem erro.
- Jogador parado: inimigo aproxima-se continuamente.
- Jogador em movimento: inimigo atualiza a direção a cada frame de física.
- Jogador e inimigo em contato: os dois podem se sobrepor e o jogador permanece livre para escapar em qualquer direção.

## Fora do escopo

- Spawn automático, temporizadores e dificuldade progressiva
- Múltiplos inimigos ou tipos de inimigo
- Vida, dano, morte e drops
- Ataques, armas e projéteis
- Knockback e invencibilidade
- Pathfinding, navegação e desvio de obstáculos
- Animações, áudio, partículas e arte definitiva
- Otimização para grandes quantidades de entidades

## Verificação e critérios de aceite

O incremento será verificado no Godot 4.7.1, confirmando que:

1. O projeto e as três cenas abrem sem erros.
2. Exatamente um inimigo aparece na mesma coordenada vertical e `400 px` à direita do jogador.
3. O inimigo começa a perseguição automaticamente.
4. O inimigo atualiza a direção quando o jogador muda de posição.
5. A velocidade diagonal não supera `120.0 px/s`.
6. O jogador consegue se afastar do inimigo por ser mais rápido.
7. Remover temporariamente o jogador da cena não produz erro e deixa o inimigo parado.
8. O contato não bloqueia o jogador e não causa dano, morte ou outros efeitos de combate.
9. O output do Godot permanece sem erros durante abertura, perseguição e encerramento.
10. Nenhum item listado como fora do escopo foi implementado.

Após o playtest e a aprovação do usuário, uma mensagem de commit possível será `feat: add enemy pursuit`. O agente não executará operações de staging, commit, push ou alteração de histórico.
