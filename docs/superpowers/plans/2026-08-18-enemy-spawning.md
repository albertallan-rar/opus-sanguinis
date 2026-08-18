# Enemy Spawning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o inimigo manual por um spawner que cria até 10 inimigos, um a cada 2 segundos, a 700 px da posição atual do jogador.

**Architecture:** `EnemySpawner` será uma cena independente composta por um `Node`, um `Timer` e um script pequeno. O signal `timeout` acionará a instanciação de `enemy.tscn`; grupos fornecerão as referências mínimas ao jogador e aos inimigos existentes sem adicionar coordenação a `Main`.

**Tech Stack:** Godot 4.7.1, GDScript com tipagem explícita, cenas `.tscn`, Windows desktop.

**Spec:** `docs/superpowers/specs/2026-08-18-enemy-spawning-design.md`

## Global Constraints

- Não executar `git add`, commit, push ou alteração de histórico; Git é responsabilidade exclusiva do usuário.
- Preservar todas as propriedades atuais de `Background` e `Player` em `scenes/main.tscn`.
- Remover somente a referência e a instância manual de `Enemy` de `main.tscn`.
- Usar intervalo `2.0 s`, raio `700.0 px` e limite `10`.
- Instanciar inimigos como filhos diretos de `Main`.
- Não adicionar despawn, dificuldade progressiva, ondas, tipos de inimigo, combate, HUD ou pooling.
- Não adicionar dependências; usar um verificador temporário em `.godot/`, diretório ignorado pelo Git.

## Mapa de arquivos

- Criar `scripts/enemy_spawner.gd`: adquirir o jogador, validar o limite e instanciar inimigos.
- Criar `scenes/enemy_spawner.tscn`: configurar `Timer`, signal e referência a `enemy.tscn`.
- Modificar `scenes/enemy.tscn`: incluir o nó raiz no grupo `enemies`.
- Modificar `scenes/main.tscn`: trocar o inimigo manual por uma instância de `EnemySpawner`.
- Gerado pelo Godot após importação: `scripts/enemy_spawner.gd.uid`.
- Criar e remover durante a verificação: `.godot/verify_enemy_spawning.gd`.

---

### Task 1: Vertical slice de spawn periódico

**Files:**
- Create: `scripts/enemy_spawner.gd`
- Create: `scenes/enemy_spawner.tscn`
- Modify: `scenes/enemy.tscn`
- Modify: `scenes/main.tscn`
- Test temporarily: `.godot/verify_enemy_spawning.gd`

**Interfaces:**
- Consumes: `Node2D` do grupo `player`, `PackedScene` de `enemy.tscn` e nós do grupo `enemies`.
- Produces: método `_on_timer_timeout() -> void`, que cria no máximo um inimigo por chamada, a `700.0 px` do jogador, respeitando o limite de `10`.

- [ ] **Step 1: Registrar o estado inicial**

Executar:

```powershell
git status --short --branch
Get-Content -Raw scenes\main.tscn
Get-Content -Raw scenes\enemy.tscn
```

Esperado: `main.tscn` contém o fundo, o jogador em `(3, 5)` e uma instância manual de `Enemy` em `(403, 5)`. Preservar literalmente as propriedades atuais do fundo, inclusive posição e escala salvas pelo usuário.

- [ ] **Step 2: Criar o verificador antes da implementação**

Criar `.godot/verify_enemy_spawning.gd` com:

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _verify() -> void:
	if not ResourceLoader.exists("res://scenes/enemy_spawner.tscn"):
		_fail("enemy_spawner.tscn does not exist")
		return

	var spawner_scene: PackedScene = load("res://scenes/enemy_spawner.tscn") as PackedScene
	var spawner_without_player: Node = spawner_scene.instantiate()
	root.add_child(spawner_without_player)
	var isolated_timer: Timer = spawner_without_player.get_node("Timer") as Timer
	isolated_timer.stop()
	spawner_without_player.call("_on_timer_timeout")
	if get_nodes_in_group(&"enemies").size() != 0:
		_fail("Spawner must not create enemies without a player")
		return
	spawner_without_player.queue_free()
	await process_frame

	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	if main.has_node("Enemy"):
		_fail("Main must not contain a manually placed Enemy")
		return
	var player: Node2D = main.get_node("Player") as Node2D
	var spawner: Node = main.get_node("EnemySpawner")
	var timer: Timer = spawner.get_node("Timer") as Timer
	timer.stop()

	if not is_equal_approx(timer.wait_time, 2.0) or timer.one_shot or not timer.autostart:
		_fail("Timer must repeat every 2 seconds and autostart")
		return
	if not timer.timeout.is_connected(Callable(spawner, "_on_timer_timeout")):
		_fail("Timer timeout must be connected to the spawner")
		return

	for _spawn: int in range(12):
		spawner.call("_on_timer_timeout")

	var enemies: Array[Node] = get_nodes_in_group(&"enemies")
	if enemies.size() != 10:
		_fail("Spawner must cap enemies at 10; actual=%s" % enemies.size())
		return
	for enemy_node: Node in enemies:
		var enemy: Node2D = enemy_node as Node2D
		var distance: float = enemy.global_position.distance_to(player.global_position)
		if not is_equal_approx(distance, 700.0):
			_fail("Every enemy must spawn exactly 700 px from Player; actual=%s" % distance)
			return

	main.queue_free()
	await process_frame
	print("ENEMY_SPAWNING_VERIFICATION_OK")
	quit(0)
```

- [ ] **Step 3: Executar o verificador e observar a falha esperada**

Executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_enemy_spawning.gd'
```

Esperado: `enemy_spawner.tscn does not exist` e código de saída diferente de zero.

- [ ] **Step 4: Criar o script mínimo do spawner**

Criar `scripts/enemy_spawner.gd` com:

```gdscript
class_name EnemySpawner
extends Node

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 700.0
@export var max_enemies: int = 10

var _target: Node2D


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D


func _on_timer_timeout() -> void:
	if not is_instance_valid(_target) or enemy_scene == null:
		return
	if get_tree().get_nodes_in_group(&"enemies").size() >= max_enemies:
		return

	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	get_parent().add_child(enemy)
	enemy.global_position = _target.global_position + direction * spawn_radius
```

Não armazenar contador nem lista paralela. O grupo `enemies` é a fonte de verdade.

- [ ] **Step 5: Criar a cena do spawner e conectar o signal**

Criar `scenes/enemy_spawner.tscn` com:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/enemy_spawner.gd" id="1_spawner"]
[ext_resource type="PackedScene" path="res://scenes/enemy.tscn" id="2_enemy"]

[node name="EnemySpawner" type="Node"]
script = ExtResource("1_spawner")
enemy_scene = ExtResource("2_enemy")

[node name="Timer" type="Timer" parent="."]
wait_time = 2.0
autostart = true

[connection signal="timeout" from="Timer" to="." method="_on_timer_timeout"]
```

`Timer.one_shot` permanece no padrão `false`, portanto o signal continua periódico.

- [ ] **Step 6: Incluir o inimigo no grupo `enemies`**

Alterar somente o cabeçalho do nó raiz em `scenes/enemy.tscn`, preservando a configuração não sólida:

```ini
[node name="Enemy" type="CharacterBody2D" groups=["enemies"]]
collision_layer = 0
collision_mask = 0
```

- [ ] **Step 7: Substituir o inimigo manual em `main.tscn`**

Remover:

```ini
[ext_resource type="PackedScene" path="res://scenes/enemy.tscn" id="3_enemy"]

[node name="Enemy" parent="." instance=ExtResource("3_enemy")]
position = Vector2(403, 5)
```

Adicionar junto às referências externas:

```ini
[ext_resource type="PackedScene" path="res://scenes/enemy_spawner.tscn" id="3_spawner"]
```

Adicionar depois do jogador:

```ini
[node name="EnemySpawner" parent="." instance=ExtResource("3_spawner")]
```

Preservar todos os `uid`, `unique_id`, propriedades do fundo e posição do jogador presentes no arquivo no momento da edição.

- [ ] **Step 8: Executar o verificador e observar o sucesso**

Executar novamente:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://.godot/verify_enemy_spawning.gd'
```

Esperado: `ENEMY_SPAWNING_VERIFICATION_OK`, código zero e ausência de avisos ou vazamentos.

- [ ] **Step 9: Remover o verificador e validar a cena real**

Remover somente `.godot/verify_enemy_spawning.gd`. Depois executar:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 12
git diff --check
git status --short
```

Esperado: o jogo cria inimigos por seis timeouts sem erro; `git diff --check` não apresenta saída; o verificador não aparece no status.

- [ ] **Step 10: Executar o playtest manual**

Abrir o projeto no Godot 4.7.1 e pressionar **F5**. Confirmar:

1. Nenhum inimigo está presente imediatamente ao iniciar.
2. O primeiro aparece após aproximadamente `2 segundos`.
3. Novos inimigos aparecem a cada `2 segundos` em direções variadas.
4. Cada inimigo surge fora da área central e persegue o jogador.
5. A criação para quando existem `10 inimigos`.
6. O jogador continua livre para atravessar e contornar inimigos.
7. Fundo, câmera e movimento continuam funcionando.
8. A aba **Output** permanece sem erros.

- [ ] **Step 11: Entregar para o usuário**

Executar somente inspeção:

```powershell
git diff -- scenes/main.tscn scenes/enemy.tscn scenes/enemy_spawner.tscn scripts/enemy_spawner.gd
git status --short
```

Depois do playtest, o usuário poderá decidir se cria o commit sugerido:

```powershell
git add scenes/main.tscn scenes/enemy.tscn scenes/enemy_spawner.tscn scripts/enemy_spawner.gd scripts/enemy_spawner.gd.uid docs/superpowers/specs/2026-08-18-enemy-spawning-design.md docs/superpowers/plans/2026-08-18-enemy-spawning.md
git commit -m "feat: add enemy spawning"
```

Os comandos de Git são apenas uma sugestão; o agente não deve executá-los.
