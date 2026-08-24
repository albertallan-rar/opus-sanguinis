# Lancet Auto Attack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar uma Lanceta de Sangria composta que dispara automaticamente contra o inimigo mais próximo dentro de 600 px e remove o projétil no contato ou ao fim do alcance.

**Architecture:** `LancetWeapon` será uma cena filha do jogador e cuidará somente de cooldown, seleção de alvo e criação do projétil. `Lancet` será uma `Area2D` independente, responsável por direção, movimento, alcance e remoção; inimigos ocuparão a camada física 2 apenas para detecção, permanecendo não sólidos.

**Tech Stack:** Godot 4.7.1, GDScript com tipagem explícita, cenas `.tscn`, Windows desktop.

**Spec:** `docs/superpowers/specs/2026-08-24-lancet-auto-attack-design.md`

## Global Constraints

- Não executar `git add`, commit, push ou alteração de histórico; Git é responsabilidade exclusiva do usuário.
- Não modificar `scripts/player.gd` ou o sistema de spawn.
- Usar cooldown `1.0 s`, alcance de ataque `600.0 px`, velocidade do projétil `500.0 px/s` e alcance do projétil `600.0 px`.
- Criar exatamente um projétil por timeout quando houver alvo válido no alcance.
- Manter inimigos não sólidos: `collision_layer = 2` e `collision_mask = 0`.
- Usar `collision_layer = 0` e `collision_mask = 2` na lanceta.
- Não adicionar dano, vida, morte, XP, upgrades, efeitos, áudio, pooling ou outras armas.
- Usar um verificador temporário em `.godot/`, diretório ignorado pelo Git.

## Mapa de arquivos

- Criar `scripts/lancet.gd`: lançamento, movimento, alcance e remoção no contato.
- Criar `scenes/lancet.tscn`: visual, colisão e signal do projétil.
- Criar `scripts/lancet_weapon.gd`: selecionar alvo e instanciar a lanceta.
- Criar `scenes/lancet_weapon.tscn`: configurar Timer, signal e referência ao projétil.
- Modificar `scenes/player.tscn`: instanciar a arma como filha do jogador.
- Modificar `scenes/enemy.tscn`: mover o inimigo para a camada física 2 sem alterar sua máscara.
- Gerados pelo Godot após importação: `scripts/lancet.gd.uid` e `scripts/lancet_weapon.gd.uid`.
- Criar e remover durante a verificação: `.godot/verify_lancet_auto_attack.gd`.

---

### Task 1: Vertical slice do ataque automático

**Files:**
- Create: `scripts/lancet.gd`
- Create: `scenes/lancet.tscn`
- Create: `scripts/lancet_weapon.gd`
- Create: `scenes/lancet_weapon.tscn`
- Modify: `scenes/player.tscn`
- Modify: `scenes/enemy.tscn`
- Test temporarily: `.godot/verify_lancet_auto_attack.gd`

**Interfaces:**
- Consumes: grupo `enemies`, cena principal atual e `body_entered` emitido pela `Area2D`.
- Produces: `Lancet.launch(direction: Vector2)` e um projétil por timeout contra o inimigo mais próximo dentro de `attack_range: float = 600.0`.

- [ ] **Step 1: Criar o verificador antes da implementação**

Criar `.godot/verify_lancet_auto_attack.gd` com:

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _count_lancets(world: Node) -> int:
	var count: int = 0
	for child: Node in world.get_children():
		if child.scene_file_path == "res://scenes/lancet.tscn":
			count += 1
	return count


func _first_lancet(world: Node) -> Area2D:
	for child: Node in world.get_children():
		if child.scene_file_path == "res://scenes/lancet.tscn":
			return child as Area2D
	return null


func _verify() -> void:
	if not ResourceLoader.exists("res://scenes/lancet.tscn"):
		_fail("lancet.tscn does not exist")
		return
	if not ResourceLoader.exists("res://scenes/lancet_weapon.tscn"):
		_fail("lancet_weapon.tscn does not exist")
		return

	var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	var lancet_scene: PackedScene = load("res://scenes/lancet.tscn") as PackedScene
	var world: Node2D = Node2D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world

	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	world.add_child(player)
	var weapon: Node2D = player.get_node("LancetWeapon") as Node2D
	var timer: Timer = weapon.get_node("AttackTimer") as Timer
	timer.stop()

	weapon.call("_on_attack_timer_timeout")
	if _count_lancets(world) != 0:
		_fail("Weapon must not fire without enemies")
		return

	var far_enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	far_enemy.position = Vector2(601, 0)
	far_enemy.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(far_enemy)
	weapon.call("_on_attack_timer_timeout")
	if _count_lancets(world) != 0:
		_fail("Weapon must not fire beyond 600 px")
		return

	var near_enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	near_enemy.position = Vector2(100, 100)
	near_enemy.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(near_enemy)
	weapon.call("_on_attack_timer_timeout")
	if _count_lancets(world) != 1:
		_fail("Weapon must create exactly one lancet per timeout")
		return
	var aimed_lancet: Area2D = _first_lancet(world)
	var expected_direction: Vector2 = player.global_position.direction_to(near_enemy.global_position)
	var actual_direction: Vector2 = aimed_lancet.get("_direction")
	if not actual_direction.is_equal_approx(expected_direction):
		_fail("Lancet must aim at the nearest enemy")
		return
	aimed_lancet.queue_free()
	await process_frame

	far_enemy.queue_free()
	near_enemy.queue_free()
	await process_frame

	var range_lancet: Area2D = lancet_scene.instantiate() as Area2D
	world.add_child(range_lancet)
	range_lancet.call("launch", Vector2.RIGHT)
	range_lancet.call("_physics_process", 1.2)
	await process_frame
	if is_instance_valid(range_lancet):
		_fail("Lancet must be removed after traveling 600 px")
		return

	var hit_enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	hit_enemy.position = Vector2(40, 0)
	hit_enemy.set("speed", 0.0)
	world.add_child(hit_enemy)
	var hit_lancet: Area2D = lancet_scene.instantiate() as Area2D
	world.add_child(hit_lancet)
	hit_lancet.call("launch", Vector2.RIGHT)
	for _frame: int in range(10):
		await physics_frame
		await process_frame
		if not is_instance_valid(hit_lancet):
			break
	if is_instance_valid(hit_lancet):
		_fail("Lancet must be removed after touching an enemy")
		return
	if not is_instance_valid(hit_enemy):
		_fail("Lancet contact must not remove the enemy")
		return

	world.queue_free()
	await process_frame
	print("LANCET_AUTO_ATTACK_VERIFICATION_OK")
	quit(0)
```

- [ ] **Step 2: Executar o verificador e observar a falha esperada**

Executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_lancet_auto_attack.gd'
```

Esperado: `lancet.tscn does not exist` e código de saída diferente de zero.

- [ ] **Step 3: Criar o script mínimo da lanceta**

Criar `scripts/lancet.gd` com:

```gdscript
class_name Lancet
extends Area2D

@export var speed: float = 500.0
@export var max_range: float = 600.0

var _direction: Vector2 = Vector2.RIGHT
var _distance_traveled: float = 0.0


func launch(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	var movement: Vector2 = _direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()

	if _distance_traveled >= max_range:
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
```

- [ ] **Step 4: Criar a cena da lanceta**

Criar `scenes/lancet.tscn` com:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/lancet.gd" id="1_lancet"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_lancet"]
size = Vector2(16, 4)

[node name="Lancet" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_lancet")

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-8, -2, 8, -2, 8, 2, -8, 2)
color = Color(0.85, 0.78, 0.65, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_lancet")

[connection signal="body_entered" from="." to="." method="_on_body_entered"]
```

- [ ] **Step 5: Criar o script da arma**

Criar `scripts/lancet_weapon.gd` com:

```gdscript
class_name LancetWeapon
extends Node2D

@export var lancet_scene: PackedScene
@export var attack_range: float = 600.0


func _on_attack_timer_timeout() -> void:
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return

	var distance: float = global_position.distance_to(target.global_position)
	if distance > attack_range:
		return

	var lancet: Area2D = lancet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(lancet)
	lancet.global_position = global_position
	lancet.call("launch", global_position.direction_to(target.global_position))


func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy: Node2D = node as Node2D
		if enemy == null:
			continue

		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	return nearest_enemy
```

- [ ] **Step 6: Criar a cena da arma e conectar o Timer**

Criar `scenes/lancet_weapon.tscn` com:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/lancet_weapon.gd" id="1_weapon"]
[ext_resource type="PackedScene" path="res://scenes/lancet.tscn" id="2_lancet"]

[node name="LancetWeapon" type="Node2D"]
script = ExtResource("1_weapon")
lancet_scene = ExtResource("2_lancet")

[node name="AttackTimer" type="Timer" parent="."]
wait_time = 1.0
autostart = true

[connection signal="timeout" from="AttackTimer" to="." method="_on_attack_timer_timeout"]
```

- [ ] **Step 7: Instanciar a arma no jogador**

Em `scenes/player.tscn`, alterar `load_steps` de `3` para `4`, adicionar:

```ini
[ext_resource type="PackedScene" path="res://scenes/lancet_weapon.tscn" id="2_weapon"]
```

E adicionar como último filho:

```ini
[node name="LancetWeapon" parent="." instance=ExtResource("2_weapon")]
```

Preservar grupo, script, visual, colisão e câmera existentes.

- [ ] **Step 8: Tornar o inimigo detectável sem torná-lo sólido**

Em `scenes/enemy.tscn`, alterar somente:

```ini
collision_layer = 2
collision_mask = 0
```

Preservar grupo `enemies`, script, visual e colisão.

- [ ] **Step 9: Executar o verificador e observar o sucesso**

Executar novamente:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_lancet_auto_attack.gd'
```

Esperado: `LANCET_AUTO_ATTACK_VERIFICATION_OK`, código zero e ausência de avisos ou vazamentos.

- [ ] **Step 10: Remover o verificador e validar a cena real**

Remover somente `.godot/verify_lancet_auto_attack.gd`. Em seguida executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 720
git diff --check
git status --short
```

Esperado: o jogo atravessa seis spawns e doze ciclos de ataque sem erros; o verificador não aparece no status.

- [ ] **Step 11: Executar o playtest manual**

Abrir o projeto no Godot 4.7.1 e pressionar **F5**. Confirmar:

1. Nenhuma lanceta aparece antes de um inimigo entrar em alcance.
2. A arma dispara uma vez por segundo quando existe alvo próximo.
3. Entre vários inimigos, o projétil aponta para o mais próximo.
4. A lanceta segue uma linha reta e não corrige sua trajetória.
5. Acertar um inimigo remove somente o projétil.
6. Errar o alvo remove o projétil ao fim do alcance.
7. O jogador continua atravessando e contornando inimigos.
8. Spawn, perseguição, fundo, câmera e movimento continuam funcionando.
9. A aba **Output** permanece sem erros.

- [ ] **Step 12: Entregar para o usuário**

Executar somente inspeção:

```powershell
git diff -- scenes/player.tscn scenes/enemy.tscn scenes/lancet.tscn scenes/lancet_weapon.tscn scripts/lancet.gd scripts/lancet_weapon.gd
git status --short
```

Depois do playtest, o usuário poderá decidir se cria o commit sugerido:

```powershell
git add scenes/player.tscn scenes/enemy.tscn scenes/lancet.tscn scenes/lancet_weapon.tscn scripts/lancet.gd scripts/lancet.gd.uid scripts/lancet_weapon.gd scripts/lancet_weapon.gd.uid docs/superpowers/specs/2026-08-24-lancet-auto-attack-design.md docs/superpowers/plans/2026-08-24-lancet-auto-attack.md
git commit -m "feat: add lancet auto attack"
```

Os comandos Git são somente uma sugestão; o agente não deve executá-los.
