# Terceiro incremento: spawn automático de inimigos

## Objetivo

Substituir o inimigo colocado manualmente por um spawner que instancia inimigos periodicamente ao redor da posição atual do jogador.

Este incremento valida `Timer`, signals e instanciação dinâmica de `PackedScene`. Ele não introduz combate nem dificuldade progressiva.

## Estrutura

O incremento adicionará:

```text
scenes/
└── enemy_spawner.tscn
scripts/
└── enemy_spawner.gd
```

Também serão modificados:

- `scenes/enemy.tscn`, para incluir o inimigo no grupo `enemies`.
- `scenes/main.tscn`, para remover a instância manual de `Enemy` e instanciar um único `EnemySpawner`.

## Composição do spawner

`enemy_spawner.tscn` terá:

- Nó raiz `EnemySpawner` do tipo `Node`.
- Script `enemy_spawner.gd` anexado ao nó raiz.
- Um filho `Timer` com `wait_time = 2.0`, `autostart = true` e repetição habilitada.
- Conexão do signal `timeout` do `Timer` ao método `_on_timer_timeout()` do spawner.
- Referência exportada a `enemy.tscn` como `PackedScene`.

O spawner será instanciado como filho direto de `Main`.

## Aquisição do jogador

Em `_ready()`, o spawner armazenará uma referência anulável ao primeiro `Node2D` do grupo `player`.

Existe somente um jogador. Se nenhum jogador estiver presente durante `_ready()`, cada timeout será ignorado sem produzir erro. O spawner não repetirá a busca neste incremento.

## Regras de spawn

As configurações exportadas terão estes valores iniciais:

- Intervalo do `Timer`: `2.0 s`.
- Raio de spawn: `700.0 px`.
- Limite simultâneo: `10` inimigos.

A cada timeout:

1. Se o jogador ou a cena do inimigo não estiver disponível, não fazer nada.
2. Contar os nós existentes no grupo `enemies`.
3. Se a contagem for igual ou superior a `10`, não fazer nada.
4. Sortear um ângulo no intervalo de `0` a `TAU`.
5. Criar um vetor unitário a partir desse ângulo.
6. Instanciar `enemy.tscn` como filho de `Main`.
7. Posicionar o inimigo na posição global atual do jogador mais o vetor sorteado multiplicado por `700.0 px`.

O raio fixo garante que nenhum inimigo nasça sobre o jogador. Cada spawn fará um novo sorteio independente de ângulo, distribuindo os inimigos ao redor dele sem criar regiões ou pontos de spawn adicionais. Sorteios repetidos são válidos; posições únicas não são requisito.

## Contagem de inimigos

O nó raiz de `enemy.tscn` será incluído no grupo `enemies`. O spawner usará `get_nodes_in_group(&"enemies").size()` para aplicar o limite.

Não será criado um contador separado, pois o grupo já representa as instâncias atualmente presentes na árvore.

## Alteração em `Main`

A referência externa e a instância manual de `Enemy` serão removidas de `main.tscn`. Em seu lugar haverá exatamente uma instância de `enemy_spawner.tscn`.

O fundo, o jogador, a câmera e suas propriedades atuais serão preservados.

## Fluxo

```text
Timer completa 2 segundos
→ emite timeout
→ spawner valida jogador, cena e limite
→ sorteia direção
→ instancia Enemy
→ posiciona a 700 px do jogador
→ Enemy encontra o grupo player
→ inicia perseguição
```

## Tratamento de estados

- Sem jogador: timeout ignorado, sem erro.
- Sem `enemy_scene`: timeout ignorado, sem erro.
- Menos de 10 inimigos: uma nova instância é criada.
- Exatamente 10 inimigos: nenhuma instância adicional é criada.
- Jogador em movimento: cada novo spawn usa a posição atualizada do jogador.
- Inimigos existentes: continuam perseguindo normalmente e não são reposicionados.

## Fora do escopo

- Dificuldade progressiva ou mudança de intervalo
- Ondas, elites e tipos diferentes de inimigo
- Spawn ponderado ou regiões específicas
- Despawn por distância ou tempo
- Object pooling e otimização para grandes quantidades
- Vida, dano, morte e drops
- Ataques, armas e projéteis
- HUD, contador visual ou cronômetro de partida
- Persistência e aleatoriedade reproduzível por seed

## Verificação e critérios de aceite

O incremento será verificado no Godot 4.7.1, confirmando que:

1. O projeto abre e executa sem erros.
2. Não existe mais um inimigo colocado manualmente em `main.tscn`.
3. O primeiro inimigo aparece após `2.0 s`.
4. Um novo inimigo aparece a cada `2.0 s` enquanto a contagem for inferior a `10`.
5. Cada inimigo nasce a `700.0 px` da posição do jogador usada naquele spawn.
6. Cada spawn realiza um novo sorteio de ângulo no intervalo de `0` a `TAU`.
7. A contagem nunca ultrapassa `10` inimigos.
8. Todos os inimigos perseguem o jogador com o comportamento existente.
9. Remover temporariamente o jogador não produz erro nem cria inimigos.
10. Fundo, câmera e movimentação continuam funcionando.
11. O output permanece sem erros durante criação, perseguição e encerramento.
12. Nenhum item listado como fora do escopo foi implementado.

Após o playtest e a aprovação do usuário, uma mensagem de commit possível será `feat: add enemy spawning`. O agente não executará operações de staging, commit, push ou alteração de histórico.
