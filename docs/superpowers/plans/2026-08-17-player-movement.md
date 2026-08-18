# Player Movement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar uma cena vazia na qual um placeholder do jogador se move com WASD em velocidade constante enquanto uma `Camera2D` o acompanha.

**Architecture:** `main.tscn` será o ponto de entrada e instanciará uma cena independente `player.tscn`. O jogador será um `CharacterBody2D` composto por visual, colisão e câmera; `player.gd` cuidará somente do input e da movimentação física.

**Tech Stack:** Godot 4.7, GDScript com tipagem explícita, cenas `.tscn`, Windows desktop.

## Global Constraints

- Não criar commits, executar `git add`, alterar histórico ou fazer push; Git é responsabilidade exclusiva do usuário.
- Não adicionar dependências nem framework de testes.
- Usar somente as ações `move_left`, `move_right`, `move_up` e `move_down`, associadas respectivamente a A, D, W e S.
- Usar velocidade inicial exportada de `240.0 px/s`.
- Usar um `Polygon2D` quadrado vermelho-escuro de `32 × 32 px` como placeholder.
- Usar um `RectangleShape2D` de `32 × 32 px` para colisão.
- Não implementar nenhum sistema além de cena principal, jogador, placeholder, colisão, câmera e movimento.
- O Godot 4.7 não está disponível pelo `PATH` atual; o playtest final depende do editor instalado no ambiente do usuário.

## Mapa de arquivos

- Criar `scripts/player.gd`: ler input, calcular `velocity` e chamar `move_and_slide()`.
- Gerado pelo Godot: `scripts/player.gd.uid`, identidade persistente associada ao script.
- Criar `scenes/player.tscn`: compor corpo, visual, colisão e câmera do jogador.
- Criar `scenes/main.tscn`: fornecer o espaço de gameplay e instanciar o jogador.
- Modificar `project.godot`: definir a cena principal e cadastrar as quatro ações WASD.

---

### Task 1: Vertical slice de movimentação

**Files:**
- Create: `scripts/player.gd`
- Create: `scenes/player.tscn`
- Create: `scenes/main.tscn`
- Modify: `project.godot`

**Interfaces:**
- Consumes: ações do Input Map `move_left`, `move_right`, `move_up` e `move_down`.
- Produces: cena `res://scenes/player.tscn` instanciável e cena principal `res://scenes/main.tscn` executável.

- [ ] **Step 1: Registrar o estado inicial**

Executar:

```powershell
git status --short --branch
rg --files -g '!.godot/**'
```

Esperado: branch `main`; somente o documento do plano pode estar pendente; `scenes/` e `scripts/` ainda não contêm gameplay.

- [ ] **Step 2: Criar o script de movimentação**

Criar `scripts/player.gd` com:

```gdscript
class_name Player
extends CharacterBody2D

@export var speed: float = 240.0


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()
```

`Input.get_vector()` cancela direções opostas e limita o vetor a comprimento `1`, evitando ganho de velocidade na diagonal. `_delta` recebe prefixo porque movimento com `CharacterBody2D.velocity` e `move_and_slide()` já usa unidades por segundo e não exige multiplicação manual pelo delta.

- [ ] **Step 3: Criar a cena composta do jogador**

Criar `scenes/player.tscn` com:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_player"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_player"]
size = Vector2(32, 32)

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_player")

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
color = Color(0.55, 0.08, 0.12, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_player")

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(0, 0)
enabled = true
```

Verificar visualmente no editor que `Visual` e `CollisionShape2D` estão centralizados no nó raiz e possuem as mesmas dimensões.

- [ ] **Step 4: Criar a cena principal**

Criar `scenes/main.tscn` com:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1_player"]

[node name="Main" type="Node2D"]

[node name="Player" parent="." instance=ExtResource("1_player")]
```

Não adicionar mapa, limites, decoração ou outros nós.

- [ ] **Step 5: Configurar a cena principal no projeto**

Adicionar em `[application]` de `project.godot`:

```ini
run/main_scene="res://scenes/main.tscn"
```

Manter as configurações existentes intactas.

- [ ] **Step 6: Cadastrar as ações WASD**

No editor Godot 4.7, abrir **Project > Project Settings > Input Map** e cadastrar exatamente:

| Ação | Physical Key |
| --- | --- |
| `move_left` | A |
| `move_right` | D |
| `move_up` | W |
| `move_down` | S |

Usar **Physical Key** para manter os controles baseados na posição das teclas em diferentes layouts. Manter `Deadzone` no valor padrão `0.5`. Salvar o projeto e confirmar que `project.godot` ganhou uma seção `[input]` contendo somente essas quatro ações novas.

- [ ] **Step 7: Fazer a validação estática**

Executar:

```powershell
rg -n 'run/main_scene|move_left|move_right|move_up|move_down' project.godot
rg -n 'class_name Player|speed: float = 240.0|Input.get_vector|move_and_slide' scripts/player.gd
rg -n 'CharacterBody2D|Polygon2D|RectangleShape2D|Camera2D' scenes/player.tscn
rg -n 'Node2D|player.tscn' scenes/main.tscn
git diff --check
git status --short
```

Esperado: todas as buscas encontram os elementos indicados; `git diff --check` não retorna erros; há somente o plano, as cenas, o script, seu arquivo `.uid` gerado e `project.godot` como mudanças pendentes.

- [ ] **Step 8: Verificar importação no Godot**

Abrir o projeto no Godot 4.7. Aguardar a importação e confirmar:

- `main.tscn`, `player.tscn` e `player.gd` aparecem no FileSystem.
- Nenhum ícone de erro aparece no script.
- Abrir ambas as cenas não produz alerta de recurso ausente.
- A aba **Output** não contém erro de parser, recurso ou configuração.

Se o editor alterar a serialização de `.tscn` ou `project.godot`, aceitar somente mudanças mecânicas feitas pelo Godot e revisar o diff antes de continuar.

- [ ] **Step 9: Executar o playtest manual**

Pressionar **F6** em `main.tscn` e depois **F5** no projeto. Em ambos os casos, confirmar:

1. A cena abre com o quadrado vermelho-escuro centralizado.
2. W move para cima, A para a esquerda, S para baixo e D para a direita.
3. Soltar todas as teclas interrompe imediatamente o movimento.
4. W+S e A+D se cancelam nos respectivos eixos.
5. W+D, W+A, S+D e S+A produzem diagonais sem aumento perceptível de velocidade.
6. O quadrado permanece centralizado enquanto a câmera acompanha seu deslocamento.
7. Não há erros na aba **Output** ao iniciar, mover ou encerrar o jogo.

- [ ] **Step 10: Revisar escopo e entregar para o commit do usuário**

Executar:

```powershell
git diff -- project.godot scenes/main.tscn scenes/player.tscn scripts/player.gd
git status --short
```

Confirmar que não foram adicionados inimigos, ataques, HUD, arte definitiva, áudio, mapa, limites ou outros sistemas. Informar ao usuário os arquivos alterados, as verificações executadas e qualquer etapa manual ainda pendente.

Depois de testar e aprovar, o usuário poderá criar o commit sugerido:

```powershell
git add project.godot scenes/main.tscn scenes/player.tscn scripts/player.gd scripts/player.gd.uid docs/superpowers/plans/2026-08-17-player-movement.md
git commit -m "feat: add player movement"
```

Esses comandos são apenas uma sugestão de entrega; o agente não deve executá-los.
