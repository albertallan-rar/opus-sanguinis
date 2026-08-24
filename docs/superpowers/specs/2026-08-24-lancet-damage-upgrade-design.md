# Melhoria de dano da Lanceta

## Objetivo

Criar o primeiro fluxo de melhoria por nível do jogo. Cada nível ganho oferece uma melhoria obrigatória de dano da Lanceta, pausa a partida durante a escolha e mantém no HUD um contador do dano atual para facilitar a validação manual.

## Fluxo do jogador

1. O jogador coleta XP suficiente e sobe de nível.
2. A partida pausa e um painel central exibe `Subiu de nível!`.
3. O painel apresenta um único botão no formato `Dano da Lanceta: 1 → 2`.
4. Ao pressionar o botão, o dano atual da Lanceta aumenta em 1.
5. O contador permanente do HUD muda para `Dano da Lanceta: 2`.
6. Se não houver outra melhoria pendente, o painel fecha e a partida continua.
7. Se mais de um nível tiver sido ganho, o painel permanece aberto para a próxima melhoria e atualiza os valores do botão. A partida só continua depois que todas as melhorias pendentes forem escolhidas.

## Responsabilidades

### `LancetWeapon`

- Armazena o dano atual da arma, começando em 1.
- Expõe uma operação para aumentar o dano em 1.
- Emite um sinal sempre que o dano muda.
- Atribui o dano atual a cada projétil no momento de sua criação.

O projétil continua responsável apenas por movimentação, alcance, colisão e aplicação do valor recebido.

### Painel de melhoria

- Escuta os eventos de subida de nível do jogador.
- Mantém a quantidade de melhorias pendentes.
- Pausa a árvore quando existe ao menos uma melhoria pendente.
- Continua processando enquanto a árvore está pausada, permitindo interação com o botão.
- Localiza a `LancetWeapon` do jogador e aplica a melhoria selecionada.
- Nunca descarta níveis adicionais recebidos antes da conclusão das escolhas.
- Ao consumir a última melhoria pendente, oculta o painel e restaura o estado de pausa anterior à abertura. Assim, o painel não retoma uma partida que já estivesse pausada por outro motivo.

### HUD

- Mantém os indicadores atuais de nível e XP.
- Acrescenta o texto permanente `Dano da Lanceta: N`.
- Lê o valor inicial da arma ao entrar na árvore.
- Atualiza o texto por meio do sinal de mudança de dano da arma.

## Interface visual

O painel será funcional e provisório, usando controles nativos do Godot:

- fundo escurecido cobrindo toda a tela;
- caixa central;
- título `Subiu de nível!`;
- botão único mostrando o dano atual e o próximo valor.

O indicador de dano ficará abaixo de `Level` e `XP`, no canto superior esquerdo. Arte final, animações, ícones e identidade visual definitiva não fazem parte deste incremento.

## Regras e casos-limite

- O dano inicial é 1.
- Cada escolha aumenta exatamente 1 ponto.
- Todo projétil criado após a escolha usa o novo dano; projéteis que já estavam em voo mantêm o valor com que foram criados.
- Ganhar dois níveis gera duas escolhas consecutivas e dois aumentos de dano.
- O jogador, inimigos, spawner, projéteis e temporizadores ficam parados enquanto o painel está aberto.

## Validação

Os testes automatizados devem comprovar:

- aumento unitário do dano e emissão do valor atualizado;
- transferência do dano atual para um novo projétil;
- abertura e pausa ao subir de nível;
- consumo correto de várias melhorias pendentes;
- atualização do botão e do contador permanente;
- restauração correta do estado de pausa ao fechar o painel.

A validação manual deve confirmar que o painel pode ser operado durante a pausa e que inimigos, ataques e movimentação ficam congelados até a escolha.

## Fora do escopo

- múltiplas opções ou escolhas aleatórias;
- melhorias de cadência, alcance ou velocidade;
- raridades, reroll e evolução de armas;
- animações, áudio, ícones e arte definitiva;
- curva crescente de XP ou limite máximo de nível.
