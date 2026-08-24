# Game Over and Restart Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar uma tela de derrota durante a pausa e permitir iniciar uma partida nova e limpa pelo botão `Tentar novamente`.

**Architecture:** Um `GameOverPanel` independente observará `Player.died`, exibirá o nível alcançado e controlará somente a solicitação de reinício. `GameFlow` continuará responsável pela pausa global, preservando a separação entre fluxo da partida e apresentação.

**Tech Stack:** Godot 4.7.1, GDScript, cenas `.tscn`, testes headless com `SceneTree`.

**Spec:** `docs/superpowers/specs/2026-08-24-game-over-restart-design.md`

## Global Constraints

- Painel inicialmente oculto, `layer = 20` e `process_mode = PROCESS_MODE_ALWAYS`.
- Texto exato: `Você morreu`, `Nível alcançado: N` e `Tentar novamente`.
- Reinício remove a pausa antes de chamar `reload_current_scene()`.
- Falha de recarga volta a pausar e mantém o painel visível.
- A nova partida deve iniciar com nível 1, XP 0, vida 10 e dano 1.
- Não executar `git add`, `git commit`, `git push` nem alterações de histórico.

---

### Task 1: Criar e abrir o painel de derrota

**Files:**
- Create: `scripts/game_over_panel.gd`
- Create: `scenes/game_over_panel.tscn`
- Create: `tests/verify_game_over_panel.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `Player.died`
- Consumes: `Player.level: int`
- Produces: `$Overlay/PanelContainer/MarginContainer/VBoxContainer/LevelLabel`
- Produces: `$Overlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton`
- Produces: `func _on_player_died() -> void`

- [ ] **Step 1: Escrever teste vermelho de abertura**

O teste deve carregar `main.tscn`, aguardar `_ready()`, localizar `GameOverPanel`, definir o nível do jogador como 3 e causar dano letal. Confirmar:

```gdscript
_expect(not panel.visible, "game over panel starts hidden")
player.level = 3
player.take_damage(10)
_expect(paused, "death keeps the game tree paused")
_expect(panel.visible, "death opens the game over panel")
_expect_equal(panel.process_mode, Node.PROCESS_MODE_ALWAYS, "panel processes while paused")
_expect_equal(level_label.text, "Nível alcançado: 3", "panel displays the reached level")
```

- [ ] **Step 2: Executar e confirmar falha pela cena ausente**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://tests/verify_game_over_panel.gd'
```

Expected: exit `1` porque `GameOverPanel` ainda não existe na cena principal.

- [ ] **Step 3: Implementar o controlador mínimo**

Criar `scripts/game_over_panel.gd`:

```gdscript
class_name GameOverPanel
extends CanvasLayer

var _player: Player

@onready var _level_label: Label = $Overlay/PanelContainer/MarginContainer/VBoxContainer/LevelLabel
@onready var _restart_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton


func _ready() -> void:
	visible = false
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		return
	_player.died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_button_pressed)


func _on_player_died() -> void:
	_level_label.text = "Nível alcançado: %d" % _player.level
	visible = true
```

- [ ] **Step 4: Construir a cena visual**

Criar `scenes/game_over_panel.tscn` com:

- raiz `CanvasLayer`, `process_mode = 3`, `layer = 20`;
- `Overlay` full-rect, preto com alpha `0.85`, `mouse_filter = 0`;
- `PanelContainer` central com `custom_minimum_size = Vector2(440, 240)` e offsets `-220/-120/220/120`;
- margens 24 e `VBoxContainer` com separação 20;
- `TitleLabel`, fonte 32, texto `Você morreu`, centralizado;
- `LevelLabel`, fonte 22, texto `Nível alcançado: 1`, centralizado;
- `RestartButton`, altura 56, fonte 20, texto `Tentar novamente`.

Instanciar `GameOverPanel` em `main.tscn` depois de `UpgradePanel`.

- [ ] **Step 5: Executar até obter saída verde para abertura**

Expected: o cenário de abertura passa sem `ERROR` ou `WARNING`; o cenário de reinício da próxima tarefa ainda não foi adicionado.

---

### Task 2: Recarregar a partida com estado inicial

**Files:**
- Modify: `scripts/game_over_panel.gd`
- Modify: `tests/verify_game_over_panel.gd`

**Interfaces:**
- Produces: `func _on_restart_button_pressed() -> void`

- [ ] **Step 1: Acrescentar teste vermelho da recarga real**

Depois de abrir o painel, guardar a referência da cena atual, emitir `RestartButton.pressed`, aguardar dois frames e confirmar:

```gdscript
_expect(not paused, "restart removes the game pause")
_expect(current_scene != previous_scene, "restart replaces the previous scene")
var new_player: Player = current_scene.get_node("Player") as Player
_expect_equal(new_player.level, 1, "restart resets level")
_expect_equal(new_player.experience, 0, "restart resets experience")
_expect_equal(new_player.current_health, 10, "restart restores health")
_expect_equal(new_player.get_node("LancetWeapon").damage, 1, "restart resets weapon damage")
```

- [ ] **Step 2: Executar e confirmar falha porque o botão ainda não recarrega**

Expected: exit `1`, cena anterior permanece e/ou árvore continua pausada.

- [ ] **Step 3: Implementar reinício e recuperação de erro**

Adicionar:

```gdscript
func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var error: Error = get_tree().reload_current_scene()
	if error == OK:
		return
	get_tree().paused = true
	push_error("Falha ao reiniciar a partida: código %d" % error)
```

O painel já permanece visível porque a cena antiga não é substituída quando a recarga falha.

- [ ] **Step 4: Reexecutar até obter saída totalmente limpa**

Expected: `GAME_OVER_PANEL_TESTS_PASSED`, exit `0`, sem `ERROR` ou `WARNING`.

---

### Task 3: Regressão integrada e teste manual

**Files:**
- Verify: `scripts/game_over_panel.gd`
- Verify: `scripts/game_flow.gd`
- Verify: `scenes/game_over_panel.tscn`
- Verify: `scenes/main.tscn`
- Verify: `tests/`

- [ ] **Step 1: Executar todos os testes `verify_*.gd`**

Exigir exit `0`, marcador de sucesso e nenhuma linha `ERROR` ou `WARNING` em cada teste.

- [ ] **Step 2: Carregar o jogo completo por 180 frames**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 180
```

Expected: exit `0`, sem erro de parsing, cena, nó ou sinal.

- [ ] **Step 3: Conferir o diff sem alterar Git**

Executar `git diff --check` e `git status --short`. Não preparar nem criar commit.

- [ ] **Step 4: Entregar roteiro manual**

Solicitar validação por F5:

1. Morrer congela toda a ação e mostra o painel.
2. O nível alcançado está correto.
3. `Tentar novamente` responde durante a pausa.
4. A nova partida começa com HUD, vida, nível, XP e Lanceta nos valores iniciais.
5. Não restam inimigos, projéteis ou pickups da partida anterior.
