# Player Health and Contact Damage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao jogador 10 pontos de vida, permitir que inimigos causem dano imediato e periódico por contato e mostrar a vida no HUD.

**Architecture:** `Player` será a fonte única da vida e do estado de morte. Cada `Enemy` terá sua própria área de detecção e timer, permitindo temporização independente, enquanto o HUD observará o sinal de vida do jogador.

**Tech Stack:** Godot 4.7.1, GDScript, cenas `.tscn`, testes headless com `SceneTree`.

**Spec:** `docs/superpowers/specs/2026-08-24-player-health-contact-damage-design.md`

## Global Constraints

- Vida inicial e máxima exatamente `10`.
- Dano de contato exatamente `1`, imediato na entrada e repetido a cada `1.0s`.
- Vida limitada a zero; morte emitida uma única vez.
- Corpos do jogador e inimigo continuam não sólidos entre si.
- Cada inimigo mantém timer independente.
- Nenhuma tela de derrota, cura, knockback ou invulnerabilidade neste incremento.
- Não executar `git add`, `git commit`, `git push` nem alterações de histórico.

---

### Task 1: Adicionar vida e morte ao jogador

**Files:**
- Create: `tests/verify_player_health.gd`
- Modify: `scripts/player.gd`

**Interfaces:**
- Produces: `signal health_changed(current_health: int, maximum_health: int)`
- Produces: `signal died`
- Produces: `@export var max_health: int = 10`
- Produces: `var current_health: int = max_health`
- Produces: `func take_damage(amount: int) -> void`

- [ ] **Step 1: Escrever teste vermelho da vida**

Criar teste headless com `Player.new()` que confirme valores iniciais `10 / 10`, conecte os dois sinais e execute:

```gdscript
player.take_damage(3)
_expect_equal(player.current_health, 7, "damage reduces current health")
_expect_equal(health_events, [[7, 10]], "health change emits current and maximum values")

player.velocity = Vector2.RIGHT * 100.0
player.take_damage(20)
_expect_equal(player.current_health, 0, "lethal damage clamps health to zero")
_expect_equal(death_count, 1, "lethal damage emits death once")
_expect_equal(player.velocity, Vector2.ZERO, "death stops player velocity")
```

Depois chamar dano positivo novamente, zero e negativo, confirmando que vida e contagens de sinais não mudam.

- [ ] **Step 2: Executar e confirmar falha pela API ausente**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://tests/verify_player_health.gd'
```

Expected: exit `1` porque sinais, propriedades e método ainda não existem.

- [ ] **Step 3: Implementar vida, dano e morte**

Adicionar a `player.gd`:

```gdscript
signal health_changed(current_health: int, maximum_health: int)
signal died

@export var max_health: int = 10

var current_health: int = max_health
var _is_dead: bool = false


func take_damage(amount: int) -> void:
	if amount <= 0 or _is_dead:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health > 0:
		return
	_is_dead = true
	velocity = Vector2.ZERO
	died.emit()
```

No começo de `_physics_process`, se `_is_dead`, definir `velocity = Vector2.ZERO` e retornar.

- [ ] **Step 4: Reexecutar até obter saída limpa**

Expected: `PLAYER_HEALTH_TESTS_PASSED`, exit `0`, sem `ERROR` ou `WARNING`.

---

### Task 2: Adicionar dano por contato independente aos inimigos

**Files:**
- Create: `tests/verify_enemy_contact_damage.gd`
- Modify: `scripts/enemy.gd`
- Modify: `scenes/enemy.tscn`

**Interfaces:**
- Consumes: `Player.take_damage(amount: int) -> void`
- Produces: `@export var contact_damage: int = 1`
- Produces: `$DamageArea` com máscara 1 e forma `36 × 36`.
- Produces: `$DamageTimer` com intervalo `1.0`, não autostart e repetição.

- [ ] **Step 1: Escrever teste vermelho do ciclo de contato**

Instanciar `Player` e um `Enemy` reais, aguardar `_ready()` e confirmar que os nós `DamageArea` e `DamageTimer` existem. Chamar o manipulador de entrada com o jogador e confirmar vida 9 e timer ativo. Chamar o timeout e confirmar vida 8. Chamar saída e outro timeout, confirmando que permanece 8 e o timer está parado.

Adicionar caso com dois inimigos chamando entrada uma vez cada, confirmando vida 8. Repetir a entrada do mesmo jogador no mesmo inimigo e confirmar que não há dano duplicado.

- [ ] **Step 2: Executar e confirmar falha pelos nós e manipuladores ausentes**

Expected: exit `1` porque `DamageArea`, `DamageTimer` e os métodos de contato ainda não existem.

- [ ] **Step 3: Implementar a lógica de contato**

Adicionar a `enemy.gd`:

```gdscript
@export var contact_damage: int = 1

var _contact_player: Player
@onready var _damage_timer: Timer = $DamageTimer


func _on_damage_area_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or player == _contact_player:
		return
	_contact_player = player
	_contact_player.take_damage(contact_damage)
	_damage_timer.start()


func _on_damage_area_body_exited(body: Node2D) -> void:
	if body != _contact_player:
		return
	_contact_player = null
	_damage_timer.stop()


func _on_damage_timer_timeout() -> void:
	if not is_instance_valid(_contact_player):
		_contact_player = null
		_damage_timer.stop()
		return
	_contact_player.take_damage(contact_damage)
```

- [ ] **Step 4: Adicionar área, forma, timer e conexões à cena**

Incrementar `load_steps` e adicionar um `RectangleShape2D` de `Vector2(36, 36)`. Criar:

```ini
[node name="DamageArea" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="DamageArea"]
shape = SubResource("RectangleShape2D_damage_area")

[node name="DamageTimer" type="Timer" parent="."]
wait_time = 1.0
```

Conectar `body_entered`, `body_exited` e `timeout` aos três métodos definidos.

- [ ] **Step 5: Reexecutar contato e saúde até obter saída limpa**

Expected: `ENEMY_CONTACT_DAMAGE_TESTS_PASSED` e `PLAYER_HEALTH_TESTS_PASSED`, ambos exit `0` e sem erros ou avisos.

---

### Task 3: Exibir vida no HUD

**Files:**
- Modify: `scripts/hud.gd`
- Modify: `scenes/hud.tscn`
- Modify: `tests/verify_hud_weapon_damage.gd`

**Interfaces:**
- Consumes: `Player.current_health: int`
- Consumes: `Player.max_health: int`
- Consumes: `Player.health_changed(current_health: int, maximum_health: int)`
- Produces: `$HealthLabel`.

- [ ] **Step 1: Escrever teste vermelho do indicador**

No teste existente do HUD, confirmar `HealthLabel.text == "Vida: 10 / 10"`; chamar `player.take_damage(3)` e confirmar atualização imediata para `Vida: 7 / 10`.

- [ ] **Step 2: Executar e confirmar falha pelo label ausente**

Expected: exit `1` porque `HealthLabel` ainda não existe.

- [ ] **Step 3: Implementar label e conexão**

Adicionar ao HUD:

```gdscript
@onready var _health_label: Label = $HealthLabel


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	_health_label.text = "Vida: %d / %d" % [current_health, maximum_health]
```

Em `_ready()`, conectar `player.health_changed` e inicializar com as duas propriedades.

Adicionar `HealthLabel` em `top = 16`, `bottom = 50`, largura 220 e fonte 24. Deslocar os labels existentes para os intervalos verticais `46–80`, `76–110`, `106–140` e `136–170`, preservando sua ordem.

- [ ] **Step 4: Reexecutar até obter saída limpa**

Expected: `HUD_WEAPON_DAMAGE_TESTS_PASSED`, exit `0`, sem erros ou avisos.

---

### Task 4: Regressão integrada e teste manual

**Files:**
- Verify: `scripts/player.gd`
- Verify: `scripts/enemy.gd`
- Verify: `scripts/hud.gd`
- Verify: `scenes/enemy.tscn`
- Verify: `scenes/hud.tscn`
- Verify: `tests/`

- [ ] **Step 1: Executar todos os testes headless em `tests/`**

Executar cada `verify_*.gd` e exigir exit `0`, marcador de sucesso e nenhuma linha `ERROR` ou `WARNING`.

- [ ] **Step 2: Carregar o jogo completo por 180 frames**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 180
```

Expected: exit `0`, sem erros de parsing, cena, nó ou sinal.

- [ ] **Step 3: Conferir o diff sem alterar Git**

Executar `git diff --check` e `git status --short`. Não preparar nem criar commit.

- [ ] **Step 4: Entregar roteiro manual**

Solicitar validação por F5:

1. HUD inicia com `Vida: 10 / 10`.
2. Primeiro contato reduz imediatamente para 9.
3. Permanecer em contato reduz novamente a cada segundo.
4. Afastar-se interrompe o dano.
5. Dois inimigos em contato causam dano independentemente.
6. Em zero, o jogador não se move mais.
