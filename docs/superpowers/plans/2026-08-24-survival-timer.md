# Survival Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Contar somente o tempo ativo da partida, exibi-lo no HUD e apresentar o valor final na tela de derrota.

**Architecture:** `GameFlow` acumulará o tempo e emitirá somente mudanças de segundos completos. HUD e `GameOverPanel` permanecerão responsáveis por suas próprias formatações `MM:SS`, lendo a mesma fonte sem introduzir persistência ou dependências externas.

**Tech Stack:** Godot 4.7.1, GDScript, cenas `.tscn`, testes headless com `SceneTree`.

**Spec:** `docs/superpowers/specs/2026-08-24-survival-timer-design.md`

## Global Constraints

- Tempo inicial exatamente zero e preservação interna de frações.
- Deltas não positivos são ignorados.
- Sinal emitido somente quando o segundo inteiro muda, uma vez por atualização.
- Formato exato `MM:SS`, com minutos sem limite de 59.
- Cronômetro usa processamento normal para respeitar pausas da árvore.
- Fonte padrão do Godot permanece; nenhuma fonte é importada.
- Não executar `git add`, `git commit`, `git push` nem alterações de histórico.

---

### Task 1: Adicionar o cronômetro ao `GameFlow`

**Files:**
- Modify: `scripts/game_flow.gd`
- Modify: `tests/verify_game_flow.gd`

**Interfaces:**
- Produces: `signal survival_time_changed(total_seconds: int)`
- Produces: `var survival_seconds: int = 0`
- Produces: `func _process(delta: float) -> void`

- [ ] **Step 1: Escrever testes vermelhos de acumulação e emissão**

Usar `GameFlow.new()` fora da árvore para evitar avanço automático. Confirmar zero inicial, conectar o sinal e executar:

```gdscript
flow._process(0.4)
_expect_equal(flow.survival_seconds, 0, "fractional time does not complete a second")
flow._process(0.6)
_expect_equal(flow.survival_seconds, 1, "fractions accumulate into a complete second")
_expect_equal(events, [1], "first completed second emits once")
flow._process(0.25)
_expect_equal(events, [1], "same displayed second emits no event")
flow._process(3.0)
_expect_equal(flow.survival_seconds, 4, "large delta advances directly to final second")
_expect_equal(events, [1, 4], "large delta emits one final value")
```

Chamar `0.0` e `-1.0`, confirmando ausência de mudança e emissão.

- [ ] **Step 2: Executar e confirmar falha pela API ausente**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://tests/verify_game_flow.gd'
```

Expected: exit `1` porque sinal, propriedade e `_process` ainda não existem.

- [ ] **Step 3: Implementar a fonte do tempo**

Adicionar:

```gdscript
signal survival_time_changed(total_seconds: int)

var survival_seconds: int = 0
var _elapsed_time: float = 0.0


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_elapsed_time += delta
	var completed_seconds: int = floori(_elapsed_time)
	if completed_seconds == survival_seconds:
		return
	survival_seconds = completed_seconds
	survival_time_changed.emit(survival_seconds)
```

Manter o modo de processamento herdado para que a pausa suspenda `_process`.

- [ ] **Step 4: Reexecutar até obter saída limpa**

Expected: `GAME_FLOW_TESTS_PASSED`, exit `0`, sem `ERROR` ou `WARNING`, preservando o teste de pausa na morte.

---

### Task 2: Mostrar o tempo no HUD

**Files:**
- Modify: `scripts/hud.gd`
- Modify: `scenes/hud.tscn`
- Modify: `tests/verify_hud_weapon_damage.gd`

**Interfaces:**
- Consumes: `GameFlow.survival_seconds: int`
- Consumes: `GameFlow.survival_time_changed(total_seconds: int)`
- Produces: `$SurvivalTimeLabel`

- [ ] **Step 1: Adaptar o fixture e escrever teste vermelho do HUD**

Alterar o mundo do teste de `Node2D` para `GameFlow`, adicionando `Player` e `HUD` antes de inserir o mundo na raiz, para que ambos tenham o mesmo pai usado na cena principal.

Confirmar `SurvivalTimeLabel.text == "Tempo: 00:00"`; chamar `world._process(65.0)` e confirmar atualização para `Tempo: 01:05`.

- [ ] **Step 2: Executar e confirmar falha pelo label ausente**

Expected: exit `1` porque `SurvivalTimeLabel` ainda não existe.

- [ ] **Step 3: Implementar conexão e formatação**

Adicionar ao HUD:

```gdscript
var _game_flow: GameFlow
@onready var _survival_time_label: Label = $SurvivalTimeLabel


func _on_survival_time_changed(total_seconds: int) -> void:
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	_survival_time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]
```

Em `_ready()`, obter `_game_flow = get_parent() as GameFlow`, conectar o sinal quando não for nulo e inicializar com `survival_seconds`.

- [ ] **Step 4: Adicionar label no canto superior direito**

Adicionar a `hud.tscn`:

```ini
[node name="SurvivalTimeLabel" type="Label" parent="."]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -216.0
offset_top = 16.0
offset_right = -16.0
offset_bottom = 50.0
grow_horizontal = 0
theme_override_font_sizes/font_size = 24
text = "Tempo: 00:00"
horizontal_alignment = 2
```

- [ ] **Step 5: Reexecutar até obter saída limpa**

Expected: `HUD_WEAPON_DAMAGE_TESTS_PASSED`, exit `0`, sem erros ou avisos.

---

### Task 3: Mostrar tempo final e zerar ao reiniciar

**Files:**
- Modify: `scripts/game_over_panel.gd`
- Modify: `scenes/game_over_panel.tscn`
- Modify: `tests/verify_game_over_panel.gd`

**Interfaces:**
- Consumes: `GameFlow.survival_seconds: int`
- Produces: `$Overlay/PanelContainer/MarginContainer/VBoxContainer/TimeLabel`

- [ ] **Step 1: Escrever teste vermelho do resultado e reinício**

Antes de matar o jogador no teste existente, chamar `main._process(65.0)`. Após a morte, confirmar `TimeLabel.text == "Tempo sobrevivido: 01:05"`.

Depois do botão de reinício e troca de cena, confirmar:

```gdscript
var new_flow: GameFlow = current_scene as GameFlow
_expect_equal(new_flow.survival_seconds, 0, "restart resets survival time")
var new_hud: HUD = current_scene.get_node("HUD") as HUD
_expect_equal(new_hud.get_node("SurvivalTimeLabel").text, "Tempo: 00:00", "restarted HUD displays zero time")
```

- [ ] **Step 2: Executar e confirmar falha pelo resultado ausente**

Expected: exit `1` porque `TimeLabel` ainda não existe.

- [ ] **Step 3: Implementar leitura e formatação no painel**

Adicionar:

```gdscript
var _game_flow: GameFlow
@onready var _time_label: Label = $Overlay/PanelContainer/MarginContainer/VBoxContainer/TimeLabel


func _format_time(total_seconds: int) -> String:
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
```

Em `_ready()`, definir `_game_flow = get_parent() as GameFlow`. Em `_on_player_died()`, atualizar:

```gdscript
_time_label.text = "Tempo sobrevivido: %s" % _format_time(_game_flow.survival_seconds)
```

- [ ] **Step 4: Adicionar o texto à cena**

Inserir `TimeLabel` entre `LevelLabel` e `RestartButton`, com fonte 22, centralização e texto inicial `Tempo sobrevivido: 00:00`. Aumentar a caixa central para `Vector2(440, 280)` e offsets verticais para `-140/140`.

- [ ] **Step 5: Reexecutar até obter saída limpa**

Expected: `GAME_OVER_PANEL_TESTS_PASSED`, exit `0`, sem erros ou avisos.

---

### Task 4: Regressão integrada e teste manual

**Files:**
- Verify: `scripts/game_flow.gd`
- Verify: `scripts/hud.gd`
- Verify: `scripts/game_over_panel.gd`
- Verify: `scenes/hud.tscn`
- Verify: `scenes/game_over_panel.tscn`
- Verify: `tests/`

- [ ] **Step 1: Executar todos os testes `verify_*.gd`**

Exigir exit `0`, marcador de sucesso e nenhuma linha `ERROR` ou `WARNING` em cada teste.

- [ ] **Step 2: Carregar o jogo completo por 180 frames**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --quit-after 180
```

Expected: exit `0`, sem erros de parsing, cena, nó ou sinal.

- [ ] **Step 3: Conferir o diff sem alterar Git**

Executar `git diff --check` e `git status --short`. Não preparar nem criar commit.

- [ ] **Step 4: Entregar roteiro manual**

Solicitar validação por F5:

1. HUD inicia em `Tempo: 00:00` e avança a cada segundo.
2. Abrir upgrade congela o cronômetro; escolher retoma a contagem.
3. Morrer congela o valor e mostra o mesmo tempo na derrota.
4. `Tentar novamente` inicia em `Tempo: 00:00`.
