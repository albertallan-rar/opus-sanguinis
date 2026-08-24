# Enemy Health and Death Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer cada Lanceta causar 1 ponto de dano e remover um inimigo após três acertos, liberando uma vaga para o spawner.

**Architecture:** `Enemy` armazenará sua própria vida e exporá `take_damage(amount)`. `Lancet` verificará esse contrato no corpo atingido, aplicará o dano configurado e continuará responsável por remover a si mesma; grupos manterão a integração existente com o limite do spawner.

**Tech Stack:** Godot 4.7.1, GDScript com tipagem explícita, cenas `.tscn`, Windows desktop.

**Spec:** `docs/superpowers/specs/2026-08-24-enemy-health-and-death-design.md`

## Global Constraints

- Não executar `git add`, commit, push ou alteração de histórico; Git é responsabilidade exclusiva do usuário.
- Usar `max_health: int = 3` e `damage: int = 1`.
- Remover o inimigo somente quando a vida for igual ou inferior a zero.
- Remover a lanceta em qualquer contato, mesmo se o corpo não aceitar dano.
- Não criar novas cenas, novos scripts, componentes, signals globais ou gerenciadores.
- Não adicionar dano ao jogador, XP, drops, HUD, feedback visual, áudio, knockback ou escalonamento.
- Usar um verificador temporário em `.godot/`, diretório ignorado pelo Git.

## Mapa de arquivos

- Modificar `scripts/enemy.gd`: adicionar vida atual, vida máxima e `take_damage()`.
- Modificar `scripts/lancet.gd`: adicionar dano e aplicá-lo no contato.
- Modificar `scenes/lancet.tscn`: registrar explicitamente `damage = 1` na instância do projétil.
- Criar e remover durante a verificação: `.godot/verify_enemy_health_and_death.gd`.

---

### Task 1: Vertical slice de dano e morte

**Files:**
- Modify: `scripts/enemy.gd`
- Modify: `scripts/lancet.gd`
- Modify: `scenes/lancet.tscn`
- Test temporarily: `.godot/verify_enemy_health_and_death.gd`

**Interfaces:**
- Consumes: `body_entered(body: Node2D)` da Lanceta e contagem existente do grupo `enemies`.
- Produces: `Enemy.take_damage(amount: int) -> void`, `max_health: int = 3`, `_current_health: int` e `Lancet.damage: int = 1`.

- [ ] **Step 1: Criar o verificador antes da implementação**

Criar `.godot/verify_enemy_health_and_death.gd` com:

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _verify() -> void:
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	var lancet_scene: PackedScene = load("res://scenes/lancet.tscn") as PackedScene
	var world: Node2D = Node2D.new()
	root.add_child(world)

	var enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	world.add_child(enemy)
	if not enemy.has_method(&"take_damage"):
		_fail("Enemy must expose take_damage")
		return
	if enemy.get("max_health") != 3 or enemy.get("_current_health") != 3:
		_fail("Enemy must start with 3 health")
		return

	enemy.call(&"take_damage", 1)
	if not is_instance_valid(enemy) or enemy.get("_current_health") != 2:
		_fail("First hit must leave Enemy alive with 2 health")
		return
	enemy.call(&"take_damage", 1)
	if not is_instance_valid(enemy) or enemy.get("_current_health") != 1:
		_fail("Second hit must leave Enemy alive with 1 health")
		return
	enemy.call(&"take_damage", 1)
	await process_frame
	if is_instance_valid(enemy):
		_fail("Third hit must remove Enemy")
		return
	if get_nodes_in_group(&"enemies").size() != 0:
		_fail("Removed Enemy must leave enemies group")
		return

	var contact_enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	world.add_child(contact_enemy)
	var lancet: Area2D = lancet_scene.instantiate() as Area2D
	world.add_child(lancet)
	if lancet.get("damage") != 1:
		_fail("Lancet damage must be 1")
		return
	lancet.call("_on_body_entered", contact_enemy)
	await process_frame
	if is_instance_valid(lancet):
		_fail("Lancet must be removed after contact")
		return
	if not is_instance_valid(contact_enemy) or contact_enemy.get("_current_health") != 2:
		_fail("Lancet contact must apply exactly 1 damage")
		return

	var neutral_body: StaticBody2D = StaticBody2D.new()
	world.add_child(neutral_body)
	var neutral_lancet: Area2D = lancet_scene.instantiate() as Area2D
	world.add_child(neutral_lancet)
	neutral_lancet.call("_on_body_entered", neutral_body)
	await process_frame
	if is_instance_valid(neutral_lancet) or not is_instance_valid(neutral_body):
		_fail("Lancet must disappear safely without damaging an unsupported body")
		return

	world.queue_free()
	await process_frame

	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	var spawner: Node = main.get_node("EnemySpawner")
	var timer: Timer = spawner.get_node("Timer") as Timer
	timer.stop()
	for _spawn: int in range(10):
		spawner.call("_on_timer_timeout")
	var spawned_enemies: Array[Node] = get_nodes_in_group(&"enemies")
	if spawned_enemies.size() != 10:
		_fail("Spawner setup must create 10 enemies")
		return
	var defeated_enemy: Node = spawned_enemies[0]
	defeated_enemy.call(&"take_damage", 3)
	await process_frame
	if get_nodes_in_group(&"enemies").size() != 9:
		_fail("Enemy death must free one spawner slot")
		return
	spawner.call("_on_timer_timeout")
	if get_nodes_in_group(&"enemies").size() != 10:
		_fail("Spawner must refill a freed enemy slot")
		return

	main.queue_free()
	await process_frame
	print("ENEMY_HEALTH_AND_DEATH_VERIFICATION_OK")
	quit(0)
```

- [ ] **Step 2: Executar o verificador e observar a falha esperada**

Executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_enemy_health_and_death.gd'
```

Esperado: `Enemy must expose take_damage` e código de saída diferente de zero.

- [ ] **Step 3: Adicionar vida e morte ao inimigo**

Em `scripts/enemy.gd`, adicionar após `speed`:

```gdscript
@export var max_health: int = 3
```

Adicionar junto ao estado privado:

```gdscript
@onready var _current_health: int = max_health
```

Adicionar antes de `_physics_process()`:

```gdscript
func take_damage(amount: int) -> void:
	_current_health -= amount

	if _current_health <= 0:
		queue_free()
```

Não alterar aquisição do jogador nem perseguição.

- [ ] **Step 4: Aplicar dano no contato da Lanceta**

Em `scripts/lancet.gd`, adicionar após `max_range`:

```gdscript
@export var damage: int = 1
```

Substituir `_on_body_entered()` por:

```gdscript
func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"take_damage"):
		body.call(&"take_damage", damage)

	queue_free()
```

- [ ] **Step 5: Fixar o valor inicial na cena da Lanceta**

Em `scenes/lancet.tscn`, manter camadas e script e adicionar:

```ini
[node name="Lancet" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_lancet")
damage = 1
```

- [ ] **Step 6: Executar o verificador e observar o sucesso**

Executar novamente:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_enemy_health_and_death.gd'
```

Esperado: `ENEMY_HEALTH_AND_DEATH_VERIFICATION_OK`, código zero e ausência de avisos ou vazamentos.

- [ ] **Step 7: Remover o verificador e validar o jogo real**

Remover somente `.godot/verify_enemy_health_and_death.gd`. Depois executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 1200
git diff --check
git status --short
```

Esperado: o jogo executa por 20 segundos, permitindo múltiplos spawns, disparos e mortes, sem erros.

- [ ] **Step 8: Executar o playtest manual**

Abrir o projeto no Godot 4.7.1 e pressionar **F5**. Confirmar:

1. O primeiro e o segundo acertos não removem o inimigo.
2. O terceiro acerto remove o inimigo.
3. Cada lanceta desaparece ao acertar.
4. Outros inimigos permanecem ativos.
5. O spawner volta a preencher as vagas sem ultrapassar 10 inimigos.
6. Movimento, perseguição, spawn, câmera e seleção de alvo continuam funcionando.
7. A aba **Output** permanece sem erros.

- [ ] **Step 9: Entregar para o usuário**

Executar somente inspeção:

```powershell
git diff -- scripts/enemy.gd scripts/lancet.gd scenes/lancet.tscn
git status --short
```

Após o playtest, o usuário poderá decidir se cria o commit sugerido:

```powershell
git add scripts/enemy.gd scripts/lancet.gd scenes/lancet.tscn docs/superpowers/specs/2026-08-24-enemy-health-and-death-design.md docs/superpowers/plans/2026-08-24-enemy-health-and-death.md
git commit -m "feat: add enemy health and death"
```

Os comandos Git são apenas uma sugestão; o agente não deve executá-los.
