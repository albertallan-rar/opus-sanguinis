# Sexto incremento: drop, coleta e contador de XP

## Objetivo

Fazer inimigos derrotados deixarem uma recompensa coletável, armazenar a experiência do jogador e exibir um contador simples na tela para validar o fluxo completo.

Este incremento não implementa level up, barra de progresso ou upgrades.

## Estrutura

O incremento adicionará:

```text
scenes/
├── hud.tscn
└── xp_pickup.tscn
scripts/
├── hud.gd
└── xp_pickup.gd
```

Também serão modificados:

- `scripts/player.gd`, para armazenar XP e emitir mudança.
- `scripts/enemy.gd`, para criar o pickup ao morrer.
- `scenes/enemy.tscn`, para configurar a cena do pickup.
- `scenes/main.tscn`, para instanciar o HUD.

## Experiência do jogador

`Player` terá:

- Signal `experience_changed(current_experience: int)`.
- `experience: int = 0`, somente leitura externa por convenção.
- Método público `gain_experience(amount: int) -> void`.

`gain_experience()` somará o valor recebido e emitirá `experience_changed` com o total atualizado. Neste incremento, somente valores positivos serão enviados.

## XP Pickup

`xp_pickup.tscn` terá:

- Nó raiz `XPPickup` do tipo `Area2D`.
- Script `xp_pickup.gd`.
- `Polygon2D` em formato de losango azul-claro de `12 × 12 px`.
- `CollisionShape2D` com `CircleShape2D` de raio `7 px`.
- `collision_layer = 0` e `collision_mask = 1`, detectando o jogador.
- `value: int = 1`, exportado.
- Signal `body_entered` conectado a `_on_body_entered()`.

Quando um corpo entrar:

1. Verificar se possui `gain_experience`.
2. Se não possuir, ignorar o contato e manter o pickup.
3. Se possuir, chamar `gain_experience(value)`.
4. Remover o pickup com `queue_free()`.

O pickup ficará parado no local da morte. Não haverá magnetismo, movimento, tempo de vida ou combinação entre pickups.

## Drop do inimigo

`Enemy` terá:

- `xp_pickup_scene: PackedScene`, exportada e configurada com `xp_pickup.tscn`.
- `_is_dying: bool = false`, impedindo execução duplicada da morte.
- Método privado `_die() -> void`.

Quando a vida chegar a zero:

1. Se `_is_dying` já for verdadeiro, ignorar a chamada.
2. Marcar `_is_dying = true`.
3. Instanciar um único `XPPickup`.
4. Adiar sua inclusão na cena principal com `call_deferred()`, evitando alterar o servidor físico durante `body_entered`.
5. Adiar a atribuição da posição global da morte com `set_deferred()`.
6. Remover o inimigo.

Se a cena do pickup não estiver configurada, o inimigo ainda será removido sem produzir erro.

## HUD de validação

`hud.tscn` terá:

- Nó raiz `HUD` do tipo `CanvasLayer`.
- Script `hud.gd`.
- Filho `ExperienceLabel` do tipo `Label`.
- Texto inicial `XP: 0`.
- Posição fixa a `16 px` das bordas superior e esquerda.
- Tamanho de fonte `24` para leitura durante o protótipo.

Em `_ready()`, `HUD` localizará o primeiro nó do grupo `player`, conectará o signal `experience_changed` a `_on_experience_changed()` e sincronizará o valor inicial.

Ao receber o signal, atualizará o texto exatamente para `XP: <total>`.

Se nenhum jogador existir, o HUD permanecerá em `XP: 0` sem erro.

O `CanvasLayer` será instanciado como filho de `Main`, mantendo o contador fixo enquanto a câmera se move.

## Fluxo

```text
Enemy chega a 0 de vida
→ cria um XPPickup na posição da morte
→ Enemy é removido
→ jogador encosta no pickup
→ XPPickup chama gain_experience(1)
→ Player soma XP e emite experience_changed
→ HUD recebe o signal
→ Label muda para XP: 1, XP: 2, ...
→ XPPickup é removido
```

## Tratamento de estados

- Inimigo recebe múltiplos acertos letais no mesmo frame: cria somente um pickup.
- Cena do pickup ausente: inimigo morre sem drop e sem erro.
- Pickup toca corpo incompatível: permanece no mundo sem erro.
- Pickup toca o jogador: concede exatamente `1 XP` e desaparece.
- HUD sem jogador: mantém `XP: 0`.
- Jogador ganha XP: contador reflete imediatamente o total emitido.

## Fora do escopo

- Level up, limiares e barra de progresso
- Seleção de upgrades
- Magnetismo e raio de coleta
- Diferentes valores, raridades ou tipos de XP
- Combinação, expiração ou pooling de pickups
- Animação, partículas e áudio de coleta
- Persistência entre partidas
- Estilização definitiva do HUD
- Contadores de tempo, inimigos ou mortes

## Verificação e critérios de aceite

O incremento será verificado no Godot 4.7.1, confirmando que:

1. O projeto abre e executa sem erros.
2. Cada inimigo morto cria exatamente um pickup em sua posição global.
3. Múltiplas chamadas letais não criam pickups duplicados.
4. O pickup permanece parado até ser coletado.
5. Contato incompatível não remove o pickup nem produz erro.
6. Contato com o jogador adiciona exatamente `1 XP`.
7. O pickup desaparece após a coleta.
8. O contador começa em `XP: 0`.
9. O contador muda imediatamente para o total atual do jogador.
10. O contador permanece fixo na tela enquanto a câmera se move.
11. Morte, reposição pelo spawner, ataque, perseguição e movimentação continuam funcionando.
12. O output permanece sem erros durante drop, coleta e atualização do HUD.
13. Nenhum item listado como fora do escopo foi implementado.

Após o playtest e a aprovação do usuário, uma mensagem de commit possível será `feat: add xp drops and counter`. O agente não executará operações de staging, commit, push ou alteração de histórico.
