# Enemy Pursuit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar um único inimigo placeholder que encontra o jogador pelo grupo `player` e o persegue continuamente a `120.0 px/s`.

**Architecture:** `enemy.tscn` encapsulará corpo, visual, colisão e comportamento do inimigo. `enemy.gd` obterá uma referência anulável ao primeiro nó do grupo `player` em `_ready()` e atualizará somente sua própria velocidade em `_physics_process()`; `main.tscn` continuará responsável apenas pela composição do espaço de gameplay.

**Tech Stack:** Godot 4.7.1, GDScript com tipagem explícita, cenas `.tscn`, Windows desktop.

**Spec:** `docs/superpowers/specs/2026-08-18-enemy-pursuit-design.md`

## Global Constraints

- Não executar `git add`, commit, push ou alteração de histórico; Git é responsabilidade exclusiva do usuário.
- Preservar os ajustes locais existentes em `scenes/main.tscn`, inclusive fundo e posição do jogador em `(3, 5)`.
- Instanciar exatamente um inimigo em `(403, 5)`, mantendo `400 px` de separação horizontal do jogador.
- Usar velocidade exportada de `120.0 px/s`.
- Usar um `Polygon2D` quadrado roxo de `32 × 32 px` e colisão retangular equivalente.
- Não adicionar spawn, combate, vida, dano, morte, drops, pathfinding, animação, áudio ou partículas.
- Não adicionar dependências nem framework de testes; usar um verificador temporário em `.godot/`, diretório ignorado pelo Git.

## Mapa de arquivos

- Criar `scripts/enemy.gd`: adquirir o alvo e executar a perseguição.
- Criar `scenes/enemy.tscn`: compor corpo, visual e colisão do inimigo.
- Modificar `scenes/player.tscn`: adicionar o nó raiz ao grupo `player`.
- Modificar `scenes/main.tscn`: instanciar um único inimigo em `(403, 5)` sem alterar o fundo ou o jogador.
- Gerado pelo Godot: `scripts/enemy.gd.uid`, identidade persistente associada ao script.
- Criar e remover durante a verificação: `.godot/verify_enemy_pursuit.gd`.

---

### Task 1: Vertical slice de perseguição

**Files:**
- Create: `scripts/enemy.gd`
- Create: `scenes/enemy.tscn`
- Modify: `scenes/player.tscn`
- Modify: `scenes/main.tscn`
- Test temporarily: `.godot/verify_enemy_pursuit.gd`

**Interfaces:**
- Consumes: primeiro `Node2D` disponível no grupo `player`.
- Produces: `Enemy`, um `CharacterBody2D` com propriedade exportada `speed: float = 120.0` e perseguição física segura quando o alvo existe ou está ausente.

- [ ] **Step 1: Registrar o estado inicial sem alterá-lo**

Executar:

```powershell
git status --short --branch
Get-Content -Raw scenes\main.tscn
Get-Content -Raw scenes\player.tscn
```

Esperado: branch `main`; a especificação e este plano podem estar pendentes; quaisquer ajustes preexistentes em `main.tscn` devem ser preservados literalmente, exceto pela nova referência e instância do inimigo.

- [ ] **Step 2: Criar o verificador antes da implementação**

Criar `.godot/verify_enemy_pursuit.gd` com:

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _verify() -> void:
	if not ResourceLoader.exists("res://scenes/enemy.tscn"):
		_fail("enemy.tscn does not exist")
		return

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if enemy_scene == null or player_scene == null:
		_fail("Could not load player or enemy scene")
		return

	var enemy_without_target: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	enemy_without_target.position = Vector2(100, 0)
	root.add_child(enemy_without_target)
	await physics_frame
	var stationary_position: Vector2 = enemy_without_target.position
	await physics_frame
	if enemy_without_target.position != stationary_position or enemy_without_target.velocity != Vector2.ZERO:
		_fail("Enemy must remain stationary without a player")
		return
	enemy_without_target.queue_free()
	await process_frame

	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player.position = Vector2.ZERO
	root.add_child(player)
	if not player.is_in_group(&"player"):
		_fail("Player root must belong to player group")
		return

	var enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	enemy.position = Vector2(100, 100)
	root.add_child(enemy)
	var initial_distance: float = enemy.position.distance_to(player.position)
	await physics_frame

	if not is_equal_approx(enemy.get("speed"), 120.0):
		_fail("Enemy speed must be 120 px/s")
		return
	if not is_equal_approx(enemy.velocity.length(), 120.0):
		_fail("Enemy velocity must remain normalized at 120 px/s")
		return
	if enemy.position.distance_to(player.position) >= initial_distance:
		_fail("Enemy must move toward the player")
		return

	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	var main_player: Node2D = main.get_node("Player") as Node2D
	var main_enemy: Node2D = main.get_node("Enemy") as Node2D
	if main_player == null or main_enemy == null:
		_fail("Main must contain Player and Enemy")
		return
	if main_enemy.position != main_player.position + Vector2(400, 0):
		_fail("Enemy must start exactly 400 px to the right of Player")
		return

	print("ENEMY_PURSUIT_VERIFICATION_OK")
	quit(0)
```

- [ ] **Step 3: Executar o verificador e observar a falha esperada**

Executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_enemy_pursuit.gd'
```

Esperado: saída contendo `enemy.tscn does not exist` e código de saída diferente de zero. A falha demonstra que o verificador detecta a ausência do incremento.

- [ ] **Step 4: Criar o comportamento mínimo do inimigo**

Criar `scripts/enemy.gd` com:

```gdscript
class_name Enemy
extends CharacterBody2D

@export var speed: float = 120.0

var _target: Node2D


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(_target.global_position) * speed
	move_and_slide()
```

`direction_to()` devolve uma direção normalizada. A referência não será buscada novamente, mantendo o comportamento previsto quando nenhum alvo existir em `_ready()`.

- [ ] **Step 5: Criar a cena composta do inimigo**

Criar `scenes/enemy.tscn` com:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/enemy.gd" id="1_enemy"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_enemy"]
size = Vector2(32, 32)

[node name="Enemy" type="CharacterBody2D"]
collision_layer = 0
collision_mask = 0
script = ExtResource("1_enemy")

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
color = Color(0.38, 0.12, 0.55, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_enemy")
```

- [ ] **Step 6: Registrar o jogador no grupo `player`**

Alterar somente o cabeçalho do nó raiz em `scenes/player.tscn`:

```ini
[node name="Player" type="CharacterBody2D" groups=["player"]]
```

Preservar script, visual, colisão e câmera existentes.

- [ ] **Step 7: Instanciar exatamente um inimigo em `main.tscn`**

Adicionar a referência externa junto às existentes:

```ini
[ext_resource type="PackedScene" path="res://scenes/enemy.tscn" id="3_enemy"]
```

Adicionar depois do jogador:

```ini
[node name="Enemy" parent="." instance=ExtResource("3_enemy")]
position = Vector2(403, 5)
```

Se o Godot tiver acrescentado `uid` ou `unique_id`, preservar esses metadados. Não alterar propriedades do `Background` nem a posição `(3, 5)` do jogador.

- [ ] **Step 8: Executar o verificador e observar o sucesso**

Executar novamente:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_enemy_pursuit.gd'
```

Esperado: `ENEMY_PURSUIT_VERIFICATION_OK` e código de saída zero.

- [ ] **Step 9: Remover o verificador temporário e validar o projeto real**

Remover somente `.godot/verify_enemy_pursuit.gd`. Em seguida, executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 5
git diff --check
git status --short
```

Esperado: Godot encerra sem erro de parser, recurso ou cena; `git diff --check` não apresenta saída; o verificador temporário não aparece no status.

- [ ] **Step 10: Executar o playtest manual**

Abrir o projeto no Godot 4.7.1 e pressionar **F5**. Confirmar:

1. Um único quadrado roxo aparece à direita do jogador.
2. Ele se aproxima continuamente do jogador.
3. Mudar de direção faz o inimigo corrigir sua trajetória.
4. O jogador consegue fugir por ter o dobro da velocidade.
5. Movimentos diagonais do inimigo não parecem mais rápidos.
6. O contato não causa dano, morte ou outro efeito de combate.
7. O fundo, a câmera e a movimentação anterior continuam funcionando.
8. A aba **Output** permanece sem erros.

- [ ] **Step 11: Entregar as mudanças para o usuário**

Executar somente comandos de inspeção:

```powershell
git diff -- scenes/main.tscn scenes/player.tscn scenes/enemy.tscn scripts/enemy.gd
git status --short
```

Informar arquivos alterados, verificações realizadas e o playtest pendente. Depois de testar e aprovar, o usuário poderá decidir se cria o commit sugerido:

```powershell
git add scenes/main.tscn scenes/player.tscn scenes/enemy.tscn scripts/enemy.gd scripts/enemy.gd.uid docs/superpowers/specs/2026-08-18-enemy-pursuit-design.md docs/superpowers/plans/2026-08-18-enemy-pursuit.md
git commit -m "feat: add enemy pursuit"
```

Esses comandos são apenas uma sugestão; o agente não deve executá-los.
