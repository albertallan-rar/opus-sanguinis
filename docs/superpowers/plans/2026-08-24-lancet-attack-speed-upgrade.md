# Lancet Attack Speed Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir escolher entre dano e redução do intervalo da Lanceta, mostrando o intervalo atual no painel e no HUD.

**Architecture:** `LancetWeapon` continuará como fonte única dos atributos da arma e controlará diretamente seu `AttackTimer`. `UpgradePanel` consumirá uma melhoria somente quando a operação escolhida for válida, e o HUD observará o novo sinal de intervalo.

**Tech Stack:** Godot 4.7.1, GDScript, cenas `.tscn`, testes headless com `SceneTree`.

**Spec:** `docs/superpowers/specs/2026-08-24-lancet-attack-speed-upgrade-design.md`

## Global Constraints

- Intervalo inicial `1.0`, multiplicador `0.9` e limite mínimo `0.2` segundos.
- Formatação visual com duas casas e vírgula decimal.
- Melhoria inválida no limite não emite sinal nem consome a fila.
- Dano e toda a lógica existente de pausa e fila devem continuar funcionando.
- Não executar `git add`, `git commit`, `git push` nem alterações de histórico.

---

### Task 1: Controlar o intervalo na `LancetWeapon`

**Files:**
- Modify: `scripts/lancet_weapon.gd`
- Modify: `tests/verify_lancet_weapon_damage.gd`

**Interfaces:**
- Produces: `signal attack_interval_changed(current_interval: float)`
- Produces: `@export var attack_interval: float = 1.0`
- Produces: `@export var minimum_attack_interval: float = 0.2`
- Produces: `@export var attack_interval_multiplier: float = 0.9`
- Produces: `func get_next_attack_interval() -> float`
- Produces: `func increase_attack_speed() -> bool`

- [ ] **Step 1: Acrescentar testes vermelhos do intervalo**

Instanciar `res://scenes/lancet_weapon.tscn` em uma árvore real e confirmar:

```gdscript
var emitted: Array[float] = []
weapon.attack_interval_changed.connect(func(value: float) -> void: emitted.append(value))
var changed: bool = weapon.increase_attack_speed()
_expect(changed, "speed upgrade changes an interval above the minimum")
_expect_float(weapon.attack_interval, 0.9, "speed upgrade reduces interval by ten percent")
_expect_float(weapon.get_node("AttackTimer").wait_time, 0.9, "timer receives the new interval")
_expect_equal(emitted, [0.9], "interval change emits the new value")
```

Adicionar caso com `attack_interval = 0.21`: a primeira melhoria resulta exatamente em `0.2`; a segunda retorna `false`, mantém `0.2` e não acrescenta emissão.

- [ ] **Step 2: Executar e confirmar falha por API ausente**

Run:

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://tests/verify_lancet_weapon_damage.gd'
```

Expected: exit `1` porque os membros de intervalo ainda não existem.

- [ ] **Step 3: Implementar a API mínima**

Adicionar à arma:

```gdscript
signal attack_interval_changed(current_interval: float)

@export var attack_interval: float = 1.0
@export var minimum_attack_interval: float = 0.2
@export var attack_interval_multiplier: float = 0.9

@onready var _attack_timer: Timer = $AttackTimer


func _ready() -> void:
	_attack_timer.wait_time = attack_interval


func get_next_attack_interval() -> float:
	return maxf(attack_interval * attack_interval_multiplier, minimum_attack_interval)


func increase_attack_speed() -> bool:
	var next_interval: float = get_next_attack_interval()
	if is_equal_approx(next_interval, attack_interval):
		return false
	attack_interval = next_interval
	_attack_timer.wait_time = attack_interval
	attack_interval_changed.emit(attack_interval)
	return true
```

- [ ] **Step 4: Reexecutar até obter marcador verde sem erros**

Expected: `LANCET_WEAPON_DAMAGE_TESTS_PASSED`, exit `0`, nenhuma linha `ERROR` ou `WARNING`.

---

### Task 2: Acrescentar a escolha de velocidade ao painel

**Files:**
- Modify: `scripts/upgrade_panel.gd`
- Modify: `scenes/upgrade_panel.tscn`
- Modify: `tests/verify_upgrade_panel.gd`

**Interfaces:**
- Consumes: `LancetWeapon.get_next_attack_interval() -> float`
- Consumes: `LancetWeapon.increase_attack_speed() -> bool`
- Produces: botão `$Overlay/PanelContainer/MarginContainer/VBoxContainer/AttackSpeedButton`.

- [ ] **Step 1: Escrever testes vermelhos da segunda escolha**

Após abrir o painel com duas melhorias pendentes, confirmar texto inicial `Intervalo de ataque: 1,00s → 0,90s`. Pressionar `AttackSpeedButton` e confirmar intervalo `0.9`, uma pendência restante e texto atualizado `Intervalo de ataque: 0,90s → 0,81s`.

Adicionar cenário no limite `0.2`: botão mostra `Intervalo de ataque: 0,20s (máximo)`, fica desabilitado e chamar o manipulador não reduz `pending_upgrades`.

- [ ] **Step 2: Executar e confirmar falha pelo botão ausente**

Expected: exit `1` porque `AttackSpeedButton` ainda não existe.

- [ ] **Step 3: Implementar controlador do segundo botão**

Adicionar referência e conexão:

```gdscript
@onready var _attack_speed_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/AttackSpeedButton
```

Implementar:

```gdscript
func _on_attack_speed_button_pressed() -> void:
	if pending_upgrades <= 0 or _weapon == null:
		return
	if not _weapon.increase_attack_speed():
		return
	_consume_upgrade()


func _format_seconds(value: float) -> String:
	return ("%.2f" % value).replace(".", ",") + "s"
```

Extrair o trecho comum que reduz a fila para `_consume_upgrade()`. Manter `_on_damage_button_pressed()` aplicando dano e chamando esse método. Em `_refresh_buttons()`, atualizar ambos os textos e usar `is_equal_approx(_weapon.attack_interval, _weapon.minimum_attack_interval)` para desabilitar o segundo botão.

- [ ] **Step 4: Adicionar o segundo botão à cena**

Aumentar `PanelContainer.custom_minimum_size` para `Vector2(460, 250)`, offsets centrais para `-230/-125/230/125` e adicionar:

```ini
[node name="AttackSpeedButton" type="Button" parent="Overlay/PanelContainer/MarginContainer/VBoxContainer"]
custom_minimum_size = Vector2(0, 56)
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Intervalo de ataque: 1,00s → 0,90s"
```

- [ ] **Step 5: Reexecutar painel e regressão da arma**

Expected: `UPGRADE_PANEL_TESTS_PASSED` e `LANCET_WEAPON_DAMAGE_TESTS_PASSED`, ambos exit `0` e sem erros ou avisos.

---

### Task 3: Mostrar o intervalo no HUD

**Files:**
- Modify: `scripts/hud.gd`
- Modify: `scenes/hud.tscn`
- Modify: `tests/verify_hud_weapon_damage.gd`

**Interfaces:**
- Consumes: `LancetWeapon.attack_interval: float`
- Consumes: `LancetWeapon.attack_interval_changed(current_interval: float)`
- Produces: `$LancetIntervalLabel`.

- [ ] **Step 1: Escrever teste vermelho do novo indicador**

Confirmar texto inicial `Intervalo da Lanceta: 1,00s`, chamar `increase_attack_speed()` e confirmar atualização imediata para `Intervalo da Lanceta: 0,90s`.

- [ ] **Step 2: Executar e confirmar falha pelo label ausente**

Expected: exit `1` porque `LancetIntervalLabel` ainda não existe.

- [ ] **Step 3: Implementar label e conexão**

Adicionar ao HUD:

```gdscript
@onready var _lancet_interval_label: Label = $LancetIntervalLabel


func _on_lancet_interval_changed(current_interval: float) -> void:
	var formatted: String = ("%.2f" % current_interval).replace(".", ",")
	_lancet_interval_label.text = "Intervalo da Lanceta: %ss" % formatted
```

Conectar `weapon.attack_interval_changed` e inicializar com `weapon.attack_interval` em `_ready()`.

Adicionar à cena em `offset_top = 106.0`, `offset_bottom = 140.0`, largura `320` e fonte `24`, com texto inicial `Intervalo da Lanceta: 1,00s`.

- [ ] **Step 4: Reexecutar até obter saída limpa**

Expected: `HUD_WEAPON_DAMAGE_TESTS_PASSED`, exit `0`, nenhuma linha `ERROR` ou `WARNING`.

---

### Task 4: Regressão integrada e teste manual

**Files:**
- Verify: `scripts/lancet_weapon.gd`
- Verify: `scripts/upgrade_panel.gd`
- Verify: `scripts/hud.gd`
- Verify: `scenes/lancet_weapon.tscn`
- Verify: `scenes/upgrade_panel.tscn`
- Verify: `scenes/hud.tscn`

- [ ] **Step 1: Executar os três testes headless completos**

Exigir os três marcadores de sucesso existentes, exit `0` e nenhuma linha `ERROR` ou `WARNING`.

- [ ] **Step 2: Carregar o jogo completo por 180 frames**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 180
```

Expected: exit `0`, sem erro de parsing, cena, nó ou sinal.

- [ ] **Step 3: Conferir o diff sem alterar Git**

Executar `git diff --check` e `git status --short`. Não preparar nem criar commit.

- [ ] **Step 4: Entregar roteiro manual**

Solicitar validação por F5:

1. HUD começa com `Intervalo da Lanceta: 1,00s`.
2. Painel apresenta dano e intervalo.
3. Escolher intervalo muda HUD para `0,90s` e retoma a partida.
4. Disparos ficam visivelmente mais frequentes.
5. Escolher dano em outro nível ainda aumenta somente o dano.
