# Lancet Damage Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pausar a partida a cada nível ganho, permitir aumentar em 1 o dano da Lanceta e mostrar o dano atual permanentemente no HUD.

**Architecture:** `LancetWeapon` será a fonte única do dano e emitirá sua alteração. Um `UpgradePanel` com processamento durante pausa enfileirará cada nível ganho e controlará a pausa, enquanto o HUD observará a arma para exibir o valor atual.

**Tech Stack:** Godot 4.7.1, GDScript, cenas `.tscn`, testes headless com `SceneTree`.

**Spec:** `docs/superpowers/specs/2026-08-24-lancet-damage-upgrade-design.md`

## Global Constraints

- O dano inicial da Lanceta é exatamente 1 e cada melhoria adiciona exatamente 1.
- Projéteis em voo mantêm o dano recebido na criação; somente novos projéteis recebem o valor atualizado.
- Cada nível ganho cria uma melhoria pendente, inclusive quando vários níveis são ganhos na mesma coleta.
- O painel deve processar entrada enquanto a árvore estiver pausada.
- Ao fechar, o painel restaura o estado de pausa existente antes da primeira melhoria pendente.
- O HUD deve exibir permanentemente `Dano da Lanceta: N` abaixo de nível e XP.
- Não executar `git add`, `git commit`, `git push` nem alterações de histórico; Git é responsabilidade do usuário.

---

### Task 1: Tornar `LancetWeapon` a fonte do dano

**Files:**
- Create: `tests/verify_lancet_weapon_damage.gd`
- Modify: `scripts/lancet_weapon.gd`

**Interfaces:**
- Produces: `signal damage_changed(current_damage: int)`
- Produces: `@export var damage: int = 1`
- Produces: `func increase_damage(amount: int = 1) -> void`
- Produces: cada `Lancet` criado recebe `lancet.damage = damage` antes de `launch()`.

- [ ] **Step 1: Escrever o teste vermelho da arma**

Criar um `SceneTree` de verificação que instancie `LancetWeapon`, conecte `damage_changed`, chame `increase_damage()` e confirme literalmente dano `2` e emissão `[2]`. Incluir um segundo caso que use uma cena de projétil real, provoque `_on_attack_timer_timeout()` com um inimigo do grupo `enemies` e confirme que o `Lancet.damage` criado é igual a `3` depois de duas melhorias.

```gdscript
var weapon := LancetWeapon.new()
var emitted: Array[int] = []
weapon.damage_changed.connect(func(value: int) -> void: emitted.append(value))
weapon.increase_damage()
assert(weapon.damage == 2)
assert(emitted == [2])
```

- [ ] **Step 2: Executar o teste e confirmar a falha correta**

Run:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://tests/verify_lancet_weapon_damage.gd'
```

Expected: falha porque `damage_changed`, `damage` e `increase_damage()` ainda não existem.

- [ ] **Step 3: Implementar o dano na arma**

Adicionar a `scripts/lancet_weapon.gd`:

```gdscript
signal damage_changed(current_damage: int)

@export var damage: int = 1


func increase_damage(amount: int = 1) -> void:
	damage += amount
	damage_changed.emit(damage)
```

Tipar a criação como `Lancet`, atribuir `lancet.damage = damage` antes de adicionar e lançar o projétil.

- [ ] **Step 4: Executar o teste até obter saída limpa**

Expected: exit code `0`, marcador `LANCET_WEAPON_DAMAGE_TESTS_PASSED` e nenhuma linha `ERROR` ou `WARNING`.

---

### Task 2: Criar painel de melhoria com fila e pausa segura

**Files:**
- Create: `scripts/upgrade_panel.gd`
- Create: `scenes/upgrade_panel.tscn`
- Create: `tests/verify_upgrade_panel.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `Player.leveled_up(new_level: int)`
- Consumes: `LancetWeapon.damage: int`
- Consumes: `LancetWeapon.increase_damage(amount: int = 1) -> void`
- Produces: `var pending_upgrades: int = 0`
- Produces: botão `$Overlay/PanelContainer/MarginContainer/VBoxContainer/DamageButton`.

- [ ] **Step 1: Escrever teste vermelho de abertura, fila e restauração**

O teste deve montar uma árvore real com `Player`, `LancetWeapon` e `UpgradePanel`, aguardar um frame para `_ready()`, emitir duas subidas de nível e confirmar:

```gdscript
assert(panel.visible)
assert(panel.pending_upgrades == 2)
assert(tree.paused)
assert(button.text == "Dano da Lanceta: 1 → 2")
```

Depois, deve pressionar o botão duas vezes e confirmar dano `3`, texto intermediário `Dano da Lanceta: 2 → 3`, painel oculto e árvore despausada. Um caso separado deve iniciar com `tree.paused = true`, abrir e concluir uma melhoria, confirmando que a árvore continua pausada.

- [ ] **Step 2: Executar o teste e confirmar a falha correta**

Expected: falha ao carregar `res://scenes/upgrade_panel.tscn`, que ainda não existe.

- [ ] **Step 3: Implementar o controlador do painel**

Criar `scripts/upgrade_panel.gd` com `process_mode = Node.PROCESS_MODE_ALWAYS` configurado na cena e a seguinte lógica:

```gdscript
class_name UpgradePanel
extends CanvasLayer

var pending_upgrades: int = 0
var _was_tree_paused: bool = false
var _weapon: LancetWeapon

@onready var _damage_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/DamageButton


func _ready() -> void:
	visible = false
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	_weapon = player.get_node("LancetWeapon") as LancetWeapon
	player.leveled_up.connect(_on_player_leveled_up)
	_damage_button.pressed.connect(_on_damage_button_pressed)


func _on_player_leveled_up(_new_level: int) -> void:
	if pending_upgrades == 0:
		_was_tree_paused = get_tree().paused
	pending_upgrades += 1
	visible = true
	_refresh_button()
	get_tree().paused = true


func _on_damage_button_pressed() -> void:
	if pending_upgrades <= 0 or _weapon == null:
		return
	_weapon.increase_damage()
	pending_upgrades -= 1
	if pending_upgrades > 0:
		_refresh_button()
		return
	visible = false
	get_tree().paused = _was_tree_paused


func _refresh_button() -> void:
	_damage_button.text = "Dano da Lanceta: %d → %d" % [_weapon.damage, _weapon.damage + 1]
```

- [ ] **Step 4: Construir a cena visual funcional**

Criar `scenes/upgrade_panel.tscn` como `CanvasLayer` com `process_mode = 3` (`PROCESS_MODE_ALWAYS`) e `layer = 10`, acima do HUD, com estes controles:

- `Overlay`: `ColorRect` com anchors full-rect e preto semitransparente;
- `PanelContainer`: centralizado, com `custom_minimum_size = Vector2(420, 180)`;
- `MarginContainer/VBoxContainer`;
- `TitleLabel` com `Subiu de nível!`, centralizado e fonte 28;
- `DamageButton` com fonte 20 e texto inicial `Dano da Lanceta: 1 → 2`.

Instanciar a cena em `scenes/main.tscn` depois do HUD, garantindo camada visual superior.

- [ ] **Step 5: Executar o teste até obter saída limpa**

Expected: exit code `0`, marcador `UPGRADE_PANEL_TESTS_PASSED`, sem vazamentos, erros ou avisos.

---

### Task 3: Exibir o dano atual permanentemente no HUD

**Files:**
- Create: `tests/verify_hud_weapon_damage.gd`
- Modify: `scripts/hud.gd`
- Modify: `scenes/hud.tscn`

**Interfaces:**
- Consumes: `LancetWeapon.damage: int`
- Consumes: `LancetWeapon.damage_changed(current_damage: int)`
- Produces: `$LancetDamageLabel` com texto `Dano da Lanceta: N`.

- [ ] **Step 1: Escrever o teste vermelho do contador**

Montar `Player` e `HUD` reais, aguardar `_ready()` e confirmar `Dano da Lanceta: 1`. Chamar `player.get_node("LancetWeapon").increase_damage()` e confirmar `Dano da Lanceta: 2` no mesmo label.

- [ ] **Step 2: Executar o teste e confirmar a falha correta**

Expected: falha porque `LancetDamageLabel` ainda não existe.

- [ ] **Step 3: Adicionar o label e sua conexão**

Adicionar a `scenes/hud.tscn`, abaixo do XP:

```ini
[node name="LancetDamageLabel" type="Label" parent="."]
offset_left = 16.0
offset_top = 76.0
offset_right = 300.0
offset_bottom = 110.0
theme_override_font_sizes/font_size = 24
text = "Dano da Lanceta: 1"
```

Em `scripts/hud.gd`, guardar o label, localizar `LancetWeapon`, conectar `damage_changed` e inicializar o texto:

```gdscript
func _on_lancet_damage_changed(current_damage: int) -> void:
	_lancet_damage_label.text = "Dano da Lanceta: %d" % current_damage
```

- [ ] **Step 4: Executar o teste até obter saída limpa**

Expected: exit code `0`, marcador `HUD_WEAPON_DAMAGE_TESTS_PASSED` e nenhuma linha `ERROR` ou `WARNING`.

---

### Task 4: Verificação integrada e entrega para teste manual

**Files:**
- Verify: `scripts/lancet_weapon.gd`
- Verify: `scripts/upgrade_panel.gd`
- Verify: `scripts/hud.gd`
- Verify: `scenes/upgrade_panel.tscn`
- Verify: `scenes/hud.tscn`
- Verify: `scenes/main.tscn`

- [ ] **Step 1: Executar os três testes headless novamente**

Executar individualmente os três scripts em `tests/` e exigir exit code `0` e saída sem erros ou avisos.

- [ ] **Step 2: Carregar o jogo completo**

Run:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 180
```

Expected: exit code `0`, sem erros de parsing, cenas, nós ou sinais.

- [ ] **Step 3: Revisar alterações sem modificar o Git**

Executar `git status --short` e `git diff --check`. Confirmar que somente arquivos da especificação, plano, testes, arma, painel, HUD e cena principal aparecem. Não preparar nem criar commit.

- [ ] **Step 4: Entregar roteiro de teste manual**

Solicitar ao usuário que execute F5 e valide:

1. HUD inicia com `Dano da Lanceta: 1`.
2. Ao alcançar 5 XP, tudo congela e o painel abre.
3. O botão mostra `Dano da Lanceta: 1 → 2`.
4. Após clicar, o HUD mostra dano 2 e a partida continua.
5. Inimigos com 3 de vida passam a morrer em dois impactos.
6. Ao ganhar níveis acumulados, surge uma escolha consecutiva para cada nível.
