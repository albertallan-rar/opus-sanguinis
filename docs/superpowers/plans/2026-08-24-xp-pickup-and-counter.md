# XP Pickup and Counter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer inimigos mortos deixarem um pickup de 1 XP, permitir sua coleta pelo jogador e exibir o total em um contador fixo na tela.

**Architecture:** `XPPickup` será uma `Area2D` independente que entrega XP por uma interface mínima. `Player` armazenará o total e emitirá um signal; `HUD`, em `CanvasLayer`, observará esse signal, enquanto `Enemy` continuará dono do próprio fluxo de morte e criará exatamente um drop.

**Tech Stack:** Godot 4.7.1, GDScript com tipagem explícita, cenas `.tscn`, Windows desktop.

**Spec:** `docs/superpowers/specs/2026-08-24-xp-pickup-and-counter-design.md`

## Global Constraints

- Não executar `git add`, commit, push ou alteração de histórico; Git é responsabilidade exclusiva do usuário.
- Cada inimigo morto cria no máximo um pickup de `1 XP`.
- O jogador inicia com `experience: int = 0`.
- O HUD exibe exatamente `XP: <total>` e permanece fixo em um `CanvasLayer`.
- Não alterar movimentação, ataque, spawn, perseguição ou separação existentes.
- Não adicionar level up, barra, upgrades, magnetismo, áudio, partículas, persistência ou UI definitiva.
- Usar um verificador temporário em `.godot/`, diretório ignorado pelo Git.

## Mapa de arquivos

- Criar `scripts/xp_pickup.gd` e `scenes/xp_pickup.tscn`.
- Criar `scripts/hud.gd` e `scenes/hud.tscn`.
- Modificar `scripts/player.gd` para armazenar e emitir XP.
- Modificar `scripts/enemy.gd` e `scenes/enemy.tscn` para criar um drop único.
- Modificar `scenes/main.tscn` para instanciar o HUD.
- Gerados pelo Godot após importação: `scripts/xp_pickup.gd.uid` e `scripts/hud.gd.uid`.
- Criar e remover durante a verificação: `.godot/verify_xp_pickup_and_counter.gd`.

---

### Task 1: Vertical slice de XP e contador

**Files:**
- Create: `scripts/xp_pickup.gd`
- Create: `scenes/xp_pickup.tscn`
- Create: `scripts/hud.gd`
- Create: `scenes/hud.tscn`
- Modify: `scripts/player.gd`
- Modify: `scripts/enemy.gd`
- Modify: `scenes/enemy.tscn`
- Modify: `scenes/main.tscn`
- Test temporarily: `.godot/verify_xp_pickup_and_counter.gd`

**Interfaces:**
- Produces: `Player.gain_experience(amount: int)`, signal `experience_changed(current_experience: int)`, `XPPickup.value: int = 1` e texto `XP: <total>`.
- Consumes: `Enemy._die()`, grupo `player`, `body_entered` e cena principal atual.

- [ ] **Step 1: Criar o verificador antes da implementação**

Criar `.godot/verify_xp_pickup_and_counter.gd` com:

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _count_pickups(world: Node) -> int:
	var count: int = 0
	for child: Node in world.get_children():
		if child.scene_file_path == "res://scenes/xp_pickup.tscn":
			count += 1
	return count


func _first_pickup(world: Node) -> Area2D:
	for child: Node in world.get_children():
		if child.scene_file_path == "res://scenes/xp_pickup.tscn":
			return child as Area2D
	return null


func _verify() -> void:
	if not ResourceLoader.exists("res://scenes/xp_pickup.tscn"):
		_fail("xp_pickup.tscn does not exist")
		return
	if not ResourceLoader.exists("res://scenes/hud.tscn"):
		_fail("hud.tscn does not exist")
		return

	var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	var pickup_scene: PackedScene = load("res://scenes/xp_pickup.tscn") as PackedScene
	var hud_scene: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	world.add_child(player)
	var attack_timer: Timer = player.get_node("LancetWeapon/AttackTimer") as Timer
	attack_timer.stop()
	if not player.has_method(&"gain_experience") or player.get("experience") != 0:
		_fail("Player must start with 0 XP and expose gain_experience")
		return

	var hud: CanvasLayer = hud_scene.instantiate() as CanvasLayer
	world.add_child(hud)
	var label: Label = hud.get_node("ExperienceLabel") as Label
	if label.text != "XP: 0":
		_fail("HUD must start at XP: 0")
		return
	player.call(&"gain_experience", 2)
	if player.get("experience") != 2 or label.text != "XP: 2":
		_fail("HUD must update from Player experience signal")
		return

	var neutral_body: StaticBody2D = StaticBody2D.new()
	world.add_child(neutral_body)
	var neutral_pickup: Area2D = pickup_scene.instantiate() as Area2D
	world.add_child(neutral_pickup)
	neutral_pickup.call("_on_body_entered", neutral_body)
	await process_frame
	if not is_instance_valid(neutral_pickup):
		_fail("Unsupported body must not collect XP")
		return
	neutral_pickup.queue_free()
	await process_frame

	var collected_pickup: Area2D = pickup_scene.instantiate() as Area2D
	world.add_child(collected_pickup)
	collected_pickup.call("_on_body_entered", player)
	await process_frame
	if is_instance_valid(collected_pickup):
		_fail("Collected pickup must be removed")
		return
	if player.get("experience") != 3 or label.text != "XP: 3":
		_fail("Pickup must add exactly 1 XP and update HUD")
		return

	var enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	enemy.position = Vector2(123, 45)
	enemy.set("speed", 0.0)
	world.add_child(enemy)
	enemy.call(&"take_damage", 3)
	enemy.call(&"take_damage", 1)
	await process_frame
	if is_instance_valid(enemy):
		_fail("Lethal damage must remove Enemy")
		return
	if _count_pickups(world) != 1:
		_fail("Enemy death must create exactly one XP pickup")
		return
	var dropped_pickup: Area2D = _first_pickup(world)
	if dropped_pickup.global_position != Vector2(123, 45):
		_fail("XP pickup must use Enemy death position")
		return

	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	if not main.has_node("HUD"):
		_fail("Main must contain HUD")
		return
	main.free()

	world.queue_free()
	await process_frame
	print("XP_PICKUP_AND_COUNTER_VERIFICATION_OK")
	quit(0)
```

- [ ] **Step 2: Executar o verificador e observar a falha esperada**

Executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_xp_pickup_and_counter.gd'
```

Esperado: `xp_pickup.tscn does not exist` e código diferente de zero.

- [ ] **Step 3: Adicionar XP e signal ao jogador**

Em `scripts/player.gd`, adicionar após `extends`:

```gdscript
signal experience_changed(current_experience: int)
```

Adicionar junto ao estado:

```gdscript
var experience: int = 0
```

Adicionar antes de `_physics_process()`:

```gdscript
func gain_experience(amount: int) -> void:
	experience += amount
	experience_changed.emit(experience)
```

- [ ] **Step 4: Criar script e cena do pickup**

Criar `scripts/xp_pickup.gd`:

```gdscript
class_name XPPickup
extends Area2D

@export var value: int = 1


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"gain_experience"):
		return

	body.call(&"gain_experience", value)
	queue_free()
```

Criar `scenes/xp_pickup.tscn`:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/xp_pickup.gd" id="1_pickup"]

[sub_resource type="CircleShape2D" id="CircleShape2D_pickup"]
radius = 7.0

[node name="XPPickup" type="Area2D"]
collision_layer = 0
collision_mask = 1
script = ExtResource("1_pickup")
value = 1

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-6, 0, 0, -6, 6, 0, 0, 6)
color = Color(0.35, 0.85, 0.95, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_pickup")

[connection signal="body_entered" from="." to="." method="_on_body_entered"]
```

- [ ] **Step 5: Criar um drop único na morte do inimigo**

Em `scripts/enemy.gd`, adicionar:

```gdscript
@export var xp_pickup_scene: PackedScene
```

Adicionar ao estado privado:

```gdscript
var _is_dying: bool = false
```

Alterar a condição letal de `take_damage()` para chamar `_die()` e adicionar:

```gdscript
func _die() -> void:
	if _is_dying:
		return

	_is_dying = true
	if xp_pickup_scene != null:
		var pickup: Area2D = xp_pickup_scene.instantiate() as Area2D
		get_tree().current_scene.call_deferred(&"add_child", pickup)
		pickup.set_deferred(&"global_position", global_position)

	queue_free()
```

Em `scenes/enemy.tscn`, alterar `load_steps` para `4`, adicionar:

```ini
[ext_resource type="PackedScene" path="res://scenes/xp_pickup.tscn" id="2_pickup"]
```

E configurar no nó raiz:

```ini
xp_pickup_scene = ExtResource("2_pickup")
```

- [ ] **Step 6: Criar HUD e conectar ao jogador**

Criar `scripts/hud.gd`:

```gdscript
class_name HUD
extends CanvasLayer

@onready var _experience_label: Label = $ExperienceLabel


func _ready() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return

	player.connect(&"experience_changed", _on_experience_changed)
	_on_experience_changed(player.get("experience"))


func _on_experience_changed(current_experience: int) -> void:
	_experience_label.text = "XP: %d" % current_experience
```

Criar `scenes/hud.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1_hud"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="ExperienceLabel" type="Label" parent="."]
offset_left = 16.0
offset_top = 16.0
offset_right = 200.0
offset_bottom = 50.0
theme_override_font_sizes/font_size = 24
text = "XP: 0"
```

- [ ] **Step 7: Instanciar o HUD em Main**

Em `scenes/main.tscn`, adicionar junto às referências:

```ini
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4_hud"]
```

Adicionar como último filho:

```ini
[node name="HUD" parent="." instance=ExtResource("4_hud")]
```

Preservar fundo, jogador e spawner literalmente.

- [ ] **Step 8: Executar o verificador e observar o sucesso**

Executar novamente o comando do Step 2.

Esperado: `XP_PICKUP_AND_COUNTER_VERIFICATION_OK`, código zero e ausência de vazamentos.

- [ ] **Step 9: Remover o verificador e validar o jogo real**

Remover `.godot/verify_xp_pickup_and_counter.gd` e executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 1800
git diff --check
git status --short
```

Esperado: 30 segundos de spawn, ataques, mortes e drops sem erros.

- [ ] **Step 10: Executar o playtest manual**

Com **F5**, confirmar:

1. Contador inicia em `XP: 0` e fica fixo no canto superior esquerdo.
2. Inimigos mortos deixam um losango azul-claro.
3. O pickup permanece parado até o jogador encostar.
4. Cada coleta incrementa o contador em exatamente 1.
5. Cada pickup desaparece após a coleta.
6. Movimentar a câmera não desloca o contador.
7. Sistemas anteriores continuam funcionando e o Output permanece limpo.

- [ ] **Step 11: Entregar para o usuário**

Depois do playtest, o usuário poderá decidir se cria:

```powershell
git add scenes/main.tscn scenes/enemy.tscn scenes/xp_pickup.tscn scenes/hud.tscn scripts/player.gd scripts/enemy.gd scripts/xp_pickup.gd scripts/xp_pickup.gd.uid scripts/hud.gd scripts/hud.gd.uid docs/superpowers/specs/2026-08-24-xp-pickup-and-counter-design.md docs/superpowers/plans/2026-08-24-xp-pickup-and-counter.md
git commit -m "feat: add xp drops and counter"
```

Os comandos Git são somente uma sugestão; o agente não deve executá-los.
