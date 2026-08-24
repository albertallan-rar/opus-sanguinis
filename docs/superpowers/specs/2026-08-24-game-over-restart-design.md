# Tela de derrota e reinício

## Objetivo

Completar o ciclo básico da partida: jogar, morrer, visualizar o resultado mínimo e reiniciar do estado inicial sem fechar o jogo.

## Fluxo do jogador

1. A vida do jogador chega a zero.
2. `Player.died` é emitido.
3. O `GameFlow` pausa a árvore, preservando o congelamento já implementado.
4. Um painel de derrota aparece acima de toda a interface.
5. O painel exibe `Você morreu`, o nível alcançado e o botão `Tentar novamente`.
6. Ao pressionar o botão, a pausa é removida e a cena atual é recarregada.
7. A nova partida começa com vida, nível, XP, atributos, inimigos e timers nos valores iniciais.

## Responsabilidades

### `GameFlow`

Continua responsável somente por pausar a árvore ao receber `Player.died`. Ele não controla textos, visibilidade ou reinício.

### `GameOverPanel`

- Localiza o jogador ao entrar na árvore.
- Escuta `Player.died`.
- Começa oculto.
- Ao receber a morte, lê `Player.level`, atualiza o texto e se torna visível.
- Processa interação mesmo com a árvore pausada.
- Ao pressionar `Tentar novamente`, remove a pausa e solicita `reload_current_scene()`.
- Fica em uma camada superior aos demais elementos da interface.

## Interface visual

O painel usa controles nativos provisórios do Godot:

- `CanvasLayer` com `layer = 20` e `process_mode = PROCESS_MODE_ALWAYS`;
- fundo preto semitransparente cobrindo a tela;
- caixa central de `440 × 240`;
- título `Você morreu` com fonte 32;
- texto `Nível alcançado: N` com fonte 22;
- botão `Tentar novamente` com altura 56 e fonte 20.

O fundo captura o mouse, impedindo interação acidental com painéis ou elementos abaixo dele.

## Ordem dos sinais e pausa

O painel e o `GameFlow` escutam o mesmo sinal `died`. A ordem de execução não altera o resultado:

- o painel usa `PROCESS_MODE_ALWAYS`, portanto continua interativo depois da pausa;
- tornar o painel visível funciona antes ou depois de `get_tree().paused = true`;
- todos os nós comuns continuam congelados.

## Reinício

Ao clicar no botão:

1. o painel define `get_tree().paused = false`;
2. chama `get_tree().reload_current_scene()`;
3. se o retorno não for `OK`, volta a pausar a árvore, mantém o painel visível e registra uma mensagem com o código do erro.

Remover a pausa antes da recarga impede que a nova cena comece congelada. A recarga recria todos os nós, eliminando inimigos, projéteis, pickups e melhorias da partida anterior.

## Casos-limite

- `died` emitido novamente não cria outro painel nem duplica conexões; apenas mantém a tela visível e atualiza o mesmo texto.
- O nível exibido é o valor existente no momento da morte.
- O botão só fica acessível quando o painel está visível.
- Uma falha de recarga não retoma o jogo antigo.
- O painel de upgrades permanece abaixo da derrota e não recebe cliques.

## Validação

Os testes automatizados devem comprovar:

- painel inicialmente oculto;
- abertura após `Player.died`;
- exibição do nível alcançado;
- árvore pausada com painel ainda processável;
- botão de reinício remove a pausa;
- recarga cria uma nova cena com jogador em nível 1, vida 10, XP 0 e dano 1;
- manutenção dos testes existentes de morte, vida, combate, HUD e upgrades.

A validação manual deve confirmar que toda a ação congela, que o botão responde durante a pausa e que uma nova partida começa limpa.

## Fora do escopo

- menu principal e botão de saída;
- tempo sobrevivido, inimigos derrotados e pontuação;
- recordes e persistência;
- animações, áudio e arte final;
- confirmação antes de reiniciar.
