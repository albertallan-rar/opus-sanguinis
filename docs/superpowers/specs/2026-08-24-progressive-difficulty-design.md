# Dificuldade progressiva por tempo

## Objetivo

Concluir o MVP técnico aumentando gradualmente a pressão da partida. A progressão usará somente densidade de inimigos — frequência de spawn e limite simultâneo — sem alterar atributos de combate.

## Estágios

| Estágio | Tempo da partida | Intervalo de spawn | Limite de inimigos |
|---|---|---:|---:|
| I | `00:00–00:59` | `2,0s` | `10` |
| II | `01:00–01:59` | `1,5s` | `15` |
| III | `02:00+` | `1,0s` | `20` |

O estágio III permanece ativo até o fim da partida. Não existe quarto estágio neste incremento.

## Fonte e fluxo dos dados

`GameFlow` continua sendo a fonte única do tempo. `EnemySpawner`:

- obtém seu nó pai como `GameFlow`;
- escuta `survival_time_changed(total_seconds)`;
- mantém `difficulty_level`, começando em 1;
- calcula o estágio correspondente ao total recebido;
- altera `Timer.wait_time` e `max_enemies` somente quando o estágio muda;
- emite `difficulty_changed(level: int)` após aplicar um novo estágio.

O spawner permanece responsável pelos valores que controlam sua própria geração. O `GameFlow` não passa a conhecer regras de dificuldade.

## Transições

- Em 60 segundos, o estágio muda de I para II.
- Em 120 segundos, muda de II para III.
- Valores repetidos dentro do mesmo estágio não reaplicam configuração nem emitem sinal.
- Um salto direto de tempo, como `30 → 130`, aplica imediatamente o estágio III e emite apenas `difficulty_changed(3)`.
- O estágio nunca diminui durante uma partida, pois o cronômetro também não diminui.

Alterar `Timer.wait_time` afeta os ciclos seguintes. O timeout já em andamento não precisa ser reiniciado no instante da transição.

## Pausa e reinício

O sistema não possui timer próprio de dificuldade. Como depende do cronômetro:

- pausa de upgrade congela a progressão;
- morte congela a progressão;
- reiniciar cria um novo spawner no estágio I, com intervalo `2,0s` e limite `10`.

## HUD

O HUD acrescenta um indicador abaixo do cronômetro:

- `Ameaça: I`;
- `Ameaça: II`;
- `Ameaça: III`.

O HUD localiza `EnemySpawner` como irmão na cena principal, lê `difficulty_level` na inicialização e escuta `difficulty_changed`. A representação usa numerais romanos fixos para os três valores conhecidos.

## Valores e configuração

Os valores dos três estágios ficam declarados no `EnemySpawner` como constantes, mantendo o primeiro balanceamento explícito e simples. Os valores atuais de `spawn_radius = 700` e da cena de inimigo não mudam.

## Casos-limite

- Sem `GameFlow` pai, o spawner mantém o estágio I e continua funcionando sem erro.
- Um valor de tempo negativo é tratado como estágio I e não produz transição.
- Receber o estágio atual novamente não emite sinal.
- Se já existirem mais inimigos que o novo limite, nenhum inimigo é removido; o spawner apenas aguarda a contagem cair abaixo do limite.
- Reinício restaura estágio I e `Ameaça: I`.

## Validação

Os testes automatizados devem comprovar:

- estado inicial: estágio I, `2,0s`, limite 10;
- permanência no estágio I em 59 segundos;
- transição para II em 60 segundos;
- transição para III em 120 segundos;
- ausência de sinais duplicados no mesmo estágio;
- salto direto para III com uma única emissão;
- atualização do indicador do HUD;
- reinício no estágio I;
- manutenção de todos os testes existentes.

A validação manual deve confirmar visualmente `Ameaça: I → II → III` e perceber o aumento de densidade sem mudança repentina nos atributos individuais do inimigo.

## Fora do escopo

- aumento de vida, velocidade ou dano dos inimigos;
- novos tipos de inimigo e elites;
- crescimento contínuo por fórmula;
- quarto estágio e progressão até 15 minutos;
- diretor de dificuldade adaptativa;
- efeitos visuais ou sonoros nas transições.
