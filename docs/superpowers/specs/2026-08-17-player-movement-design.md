# Primeiro incremento: movimentação do jogador

## Objetivo

Criar o menor incremento jogável de *Opus Sanguinis*: uma cena vazia na qual um placeholder do jogador pode ser movimentado com WASD enquanto a câmera o acompanha.

Este incremento valida o ciclo básico de edição, execução e teste no Godot 4.7. Ele não implementa combate nem qualquer outro sistema do jogo.

## Contexto do produto

*Opus Sanguinis* será um survivor 2D gótico em pixel art, ambientado em uma região rural corrompida por uma peste sanguínea. O produto futuro terá sobrevivência, combate automático, progressão, transmutação de armas e um boss final.

Esses elementos servem apenas como direção do produto. Eles não fazem parte deste incremento.

## Estrutura

O incremento terá duas cenas e um script:

```text
project.godot
scenes/
├── main.tscn
└── player.tscn
scripts/
└── player.gd
```

- `main.tscn` será a cena principal e o espaço vazio de gameplay. Seu nó raiz será um `Node2D` e conterá uma instância de `player.tscn`.
- `player.tscn` representará o jogador. Seu nó raiz será um `CharacterBody2D` com um placeholder geométrico visível, um `CollisionShape2D` e uma `Camera2D` habilitada.
- `player.gd` será anexado ao `CharacterBody2D` e terá somente a responsabilidade de ler o input e movimentar o jogador.
- `project.godot` registrará a cena principal e as quatro ações de movimento.

Essa composição mantém o espaço de gameplay separado do comportamento do jogador sem introduzir abstrações ou dados configuráveis que ainda não são necessários.

## Controles e movimento

As ações serão:

| Ação | Tecla |
| --- | --- |
| `move_left` | A |
| `move_right` | D |
| `move_up` | W |
| `move_down` | S |

A cada atualização de física, o script obterá um vetor a partir dessas ações. O vetor será limitado a comprimento `1`, garantindo que o movimento diagonal não seja mais rápido que o movimento em um único eixo. A velocidade será um `float` exportado com valor inicial de `240 px/s`, permitindo ajustes posteriores pelo Inspector.

O script atribuirá o vetor calculado a `velocity` e chamará `move_and_slide()`. Não haverá aceleração, desaceleração, inércia, corrida ou animação.

## Representação, colisão e câmera

O jogador será representado por um quadrado vermelho-escuro de `32 × 32 px`, criado com um `Polygon2D`. Não será adicionada arte definitiva.

O `CollisionShape2D` usará um `RectangleShape2D` de `32 × 32 px`, alinhado ao placeholder. Neste incremento não existirão paredes, obstáculos ou outros corpos; portanto, a colisão apenas deixa a composição do jogador pronta para incrementos posteriores.

A `Camera2D` permanecerá centralizada no jogador e o acompanhará automaticamente. Não haverá limites, suavização, zoom dinâmico, tremor ou efeitos de câmera.

## Fluxo de dados

```text
WASD
→ ações do Input Map
→ vetor direcional limitado
→ velocidade do CharacterBody2D
→ move_and_slide()
→ nova posição do jogador
→ Camera2D acompanha o jogador
```

Não serão usados sinais nem `Resource` personalizado neste incremento. Eles serão introduzidos apenas quando houver comunicação entre sistemas ou dados reutilizáveis que justifiquem seu uso.

## Tratamento de estados

- Sem teclas pressionadas, a velocidade será zero e o jogador ficará parado.
- Teclas opostas no mesmo eixo se cancelarão.
- Combinações entre um eixo horizontal e um vertical produzirão movimento diagonal com velocidade total igual à do movimento reto.
- O jogador poderá se mover indefinidamente, pois ainda não existem limites de mapa.

## Fora do escopo

- Inimigos, spawn e perseguição
- Armas, ataque automático, projéteis e dano
- Vida, morte e Game Over
- XP, níveis, upgrades e transmutação
- Mapa, obstáculos e decoração
- Boss e arena de laboratório
- Arte definitiva, animações, áudio e partículas
- HUD, menus e configurações
- Persistência, metaprogressão e publicação

Qualquer necessidade relacionada a esses itens será registrada para um incremento futuro, não adicionada a este.

## Verificação e critérios de aceite

O incremento será verificado executando o projeto no Godot 4.7 e confirmando que:

1. O projeto abre sem erros.
2. `main.tscn` está configurada e executa como cena principal.
3. W, A, S e D movimentam o placeholder nas direções correspondentes.
4. O movimento diagonal não é mais rápido que o movimento reto.
5. Soltar todas as teclas interrompe imediatamente o movimento.
6. Pressionar direções opostas no mesmo eixo não movimenta o jogador nesse eixo.
7. A câmera permanece centralizada e acompanha o jogador.
8. O output do Godot não apresenta erros.
9. Nenhum sistema listado como fora do escopo foi antecipado.

Após a implementação e a verificação, o incremento poderá ser registrado com o commit `feat: add player movement`.
