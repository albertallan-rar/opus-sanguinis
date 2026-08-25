# Progressive Difficulty Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aumentar a frequência e o limite de inimigos em três estágios temporais e mostrar o estágio atual no HUD.

**Architecture:** `GameFlow` continuará fornecendo somente o tempo. `EnemySpawner` converterá o tempo em configuração de densidade e emitirá mudanças de estágio; o HUD observará esse sinal para exibir o nível de ameaça.

**Tech Stack:** Godot 4.7.1, GDScript, cenas `.tscn`, testes headless com `SceneTree`.

**Spec:** `docs/superpowers/specs/2026-08-24-progressive-difficulty-design.md`

## Global Constraints

- Estágio I: `< 60s`, intervalo `2.0`, limite `10`.
- Estágio II: `60–119s`, intervalo `1.5`, limite `15`.
- Estágio III: `>= 120s`, intervalo `1.0`, limite `20`.
- Uma transição emite somente o estágio final aplicado.
- Estágio não diminui nem reaplica configuração durante a partida.
- Nenhum atributo individual do inimigo muda.
- Não executar `git add`, `git commit`, `git push` nem alterações de histórico.

---

### Task 1: Aplicar estágios no `EnemySpawner`

**Files:**
- Create: `tests/verify_enemy_spawner_difficulty.gd`
- Modify: `scripts/enemy_spawner.gd`

**Interfaces:**
- Produces: `signal difficulty_changed(level: int)`
- Produces: `var difficulty_level: int = 1`
- Produces: `func _on_survival_time_changed(total_seconds: int) -> void`
- Consumes: `GameFlow.survival_time_changed(total_seconds: int)`

- [ ] **Step 1: Escrever teste vermelho das transições**

Montar `GameFlow` real com `Player` e `EnemySpawner` filhos antes de inseri-lo na árvore. Aguardar `_ready()`, conectar `difficulty_changed` e confirmar valores iniciais.

Avançar o `GameFlow` para 59, 60, 119 e 120 segundos e confirmar literalmente:

```gdscript
_expect_equal(spawner.difficulty_level, 1, "59 seconds remains at threat I")
_expect_float(timer.wait_time, 2.0, "threat I keeps two-second interval")

_expect_equal(spawner.difficulty_level, 2, "60 seconds activates threat II")
_expect_float(timer.wait_time, 1.5, "threat II reduces spawn interval")
_expect_equal(spawner.max_enemies, 15, "threat II raises enemy cap")

_expect_equal(spawner.difficulty_level, 3, "120 seconds activates threat III")
_expect_float(timer.wait_time, 1.0, "threat III reduces interval to one second")
_expect_equal(spawner.max_enemies, 20, "threat III raises enemy cap")
_expect_equal(events, [2, 3], "each stage transition emits once")
```

Em um segundo fixture, saltar diretamente de zero para 130 e confirmar apenas `[3]`.

- [ ] **Step 2: Executar e confirmar falha pela API ausente**

```powershell
& 'C:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Projetos\opus-sanguinis' --script 'res://tests/verify_enemy_spawner_difficulty.gd'
```

Expected: exit `1` porque sinal e estado de dificuldade ainda não existem.

- [ ] **Step 3: Implementar as constantes e conexão**

Adicionar:

```gdscript
signal difficulty_changed(level: int)

const STAGE_TWO_TIME: int = 60
const STAGE_THREE_TIME: int = 120
const STAGE_ONE_INTERVAL: float = 2.0
const STAGE_TWO_INTERVAL: float = 1.5
const STAGE_THREE_INTERVAL: float = 1.0
const STAGE_ONE_MAX_ENEMIES: int = 10
const STAGE_TWO_MAX_ENEMIES: int = 15
const STAGE_THREE_MAX_ENEMIES: int = 20

var difficulty_level: int = 1

@onready var _spawn_timer: Timer = $Timer
```

Em `_ready()`, depois de localizar o jogador, obter `get_parent() as GameFlow` e conectar `survival_time_changed` quando o cast funcionar.

- [ ] **Step 4: Implementar aplicação sem duplicação**

```gdscript
func _on_survival_time_changed(total_seconds: int) -> void:
	var new_level: int = 1
	if total_seconds >= STAGE_THREE_TIME:
		new_level = 3
	elif total_seconds >= STAGE_TWO_TIME:
		new_level = 2
	if new_level <= difficulty_level:
		return
	difficulty_level = new_level
	match difficulty_level:
		2:
			_spawn_timer.wait_time = STAGE_TWO_INTERVAL
			max_enemies = STAGE_TWO_MAX_ENEMIES
		3:
			_spawn_timer.wait_time = STAGE_THREE_INTERVAL
			max_enemies = STAGE_THREE_MAX_ENEMIES
	difficulty_changed.emit(difficulty_level)
```

O estágio I continua usando os valores iniciais existentes da cena e da propriedade exportada.

- [ ] **Step 5: Reexecutar até obter saída limpa**

Expected: `ENEMY_SPAWNER_DIFFICULTY_TESTS_PASSED`, exit `0`, sem `ERROR` ou `WARNING`.

---

### Task 2: Mostrar ameaça no HUD

**Files:**
- Modify: `scripts/hud.gd`
- Modify: `scenes/hud.tscn`
- Modify: `tests/verify_hud_weapon_damage.gd`

**Interfaces:**
- Consumes: `EnemySpawner.difficulty_level: int`
- Consumes: `EnemySpawner.difficulty_changed(level: int)`
- Produces: `$ThreatLevelLabel`

- [ ] **Step 1: Acrescentar o spawner ao fixture e escrever teste vermelho**

Adicionar uma instância real de `enemy_spawner.tscn` ao `GameFlow` do teste antes do HUD. Confirmar `Ameaça: I`; avançar o fluxo para 60 segundos e confirmar `Ameaça: II`; avançar mais 60 e confirmar `Ameaça: III`.

- [ ] **Step 2: Executar e confirmar falha pelo label ausente**

Expected: exit `1` porque `ThreatLevelLabel` ainda não existe.

- [ ] **Step 3: Implementar conexão e numerais fixos**

Adicionar:

```gdscript
var _enemy_spawner: EnemySpawner
@onready var _threat_level_label: Label = $ThreatLevelLabel


func _on_difficulty_changed(level: int) -> void:
	var roman_level: String = ["I", "II", "III"][clampi(level, 1, 3) - 1]
	_threat_level_label.text = "Ameaça: %s" % roman_level
```

Em `_ready()`, usar `_enemy_spawner = get_parent().get_node_or_null("EnemySpawner") as EnemySpawner`, conectar o sinal e inicializar com `difficulty_level` quando não for nulo.

- [ ] **Step 4: Adicionar label abaixo do cronômetro**

Adicionar a `hud.tscn` com anchors à direita, offsets `left = -216`, `top = 46`, `right = -16`, `bottom = 80`, fonte 24, alinhamento direito e texto `Ameaça: I`.

- [ ] **Step 5: Reexecutar HUD e spawner até obter saída limpa**

Expected: `HUD_WEAPON_DAMAGE_TESTS_PASSED` e `ENEMY_SPAWNER_DIFFICULTY_TESTS_PASSED`, ambos exit `0` e sem erros ou avisos.

---

### Task 3: Validar reinício no estágio I

**Files:**
- Modify: `tests/verify_game_over_panel.gd`

**Interfaces:**
- Consumes: `EnemySpawner.difficulty_level: int`
- Consumes: `$HUD/ThreatLevelLabel`

- [ ] **Step 1: Acrescentar asserções de reinício**

No teste real de recarga já existente, após obter a nova cena, confirmar:

```gdscript
var new_spawner: EnemySpawner = current_scene.get_node("EnemySpawner") as EnemySpawner
_expect_equal(new_spawner.difficulty_level, 1, "restart resets threat level")
_expect_equal(new_spawner.max_enemies, 10, "restart resets enemy cap")
_expect_float(new_spawner.get_node("Timer").wait_time, 2.0, "restart resets spawn interval")
_expect_equal(new_hud.get_node("ThreatLevelLabel").text, "Ameaça: I", "restarted HUD displays threat I")
```

- [ ] **Step 2: Executar e confirmar o comportamento integrado**

Expected: `GAME_OVER_PANEL_TESTS_PASSED`, exit `0`, sem erros ou avisos. Essas asserções devem passar com as implementações das Tasks 1 e 2, sem novo código de produção.

---

### Task 4: Regressão completa e encerramento do MVP técnico

**Files:**
- Verify: `scripts/enemy_spawner.gd`
- Verify: `scripts/hud.gd`
- Verify: `scenes/enemy_spawner.tscn`
- Verify: `scenes/hud.tscn`
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

1. HUD inicia em `Ameaça: I`.
2. Em `01:00`, muda para `Ameaça: II` e a densidade cresce.
3. Em `02:00`, muda para `Ameaça: III` e cresce novamente.
4. Upgrade e morte congelam tempo e progressão.
5. Reiniciar volta para `Ameaça: I`.

Após essa validação, considerar concluída a lista do MVP técnico original.
