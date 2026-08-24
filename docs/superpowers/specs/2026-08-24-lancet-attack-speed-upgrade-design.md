# Escolha de velocidade de ataque da Lanceta

## Objetivo

Transformar o painel de nível em uma escolha real entre dano e velocidade de ataque. O jogador deve conseguir reduzir o intervalo entre disparos, observar o valor no HUD e continuar usando a melhoria de dano já existente.

## Fluxo do jogador

1. Ao subir de nível, a partida pausa e o painel abre como atualmente.
2. O painel mostra duas opções simultâneas:
   - `Dano da Lanceta: 1 → 2`;
   - `Intervalo de ataque: 1,00s → 0,90s`.
3. O jogador escolhe exatamente uma opção para consumir uma melhoria pendente.
4. Dano ou intervalo é atualizado imediatamente na arma e no HUD.
5. Se houver outra melhoria pendente, o painel permanece aberto e atualiza os valores dos dois botões.
6. Sem melhorias pendentes, o painel fecha e restaura o estado de pausa anterior.

## Modelo de velocidade de ataque

`LancetWeapon` será a fonte única do intervalo de ataque:

- intervalo inicial: `1,00s`;
- multiplicador por melhoria: `0,90`, equivalente a uma redução de 10% sobre o valor atual;
- limite mínimo: `0,20s`;
- cálculo: `max(intervalo_atual * 0,90, 0,20)`;
- o `AttackTimer.wait_time` recebe o novo intervalo imediatamente.

Os valores internos permanecem em `float`. Textos de interface são arredondados para duas casas decimais e usam vírgula decimal. O cálculo de melhorias futuras usa o valor interno, não o texto arredondado.

## Limite mínimo

Uma melhoria pode levar o intervalo diretamente ao limite, mas nunca abaixo dele. Quando o intervalo atual estiver no limite, o botão de velocidade:

- mostra `Intervalo de ataque: 0,20s (máximo)`;
- fica desabilitado;
- não consome uma melhoria pendente.

O botão de dano permanece disponível, garantindo que sempre exista uma escolha válida nesta versão.

## Responsabilidades

### `LancetWeapon`

- Expõe o intervalo atual e o limite mínimo.
- Calcula o próximo intervalo sem alterar o estado, para uso do painel.
- Aplica uma melhoria de velocidade.
- Atualiza o `AttackTimer.wait_time`.
- Emite o sinal `attack_interval_changed(current_interval: float)` após uma mudança efetiva.

### `UpgradePanel`

- Mantém toda a lógica atual de fila e pausa.
- Acrescenta um segundo botão para velocidade.
- Atualiza os textos de dano e intervalo sempre que o painel abre ou uma escolha é consumida.
- Consome uma melhoria somente quando a operação selecionada é válida.
- Desabilita o botão de intervalo no limite mínimo.

### `HUD`

- Mantém nível, XP e dano.
- Acrescenta `Intervalo da Lanceta: 1,00s` abaixo do dano.
- Inicializa o texto a partir da arma.
- Atualiza o texto pelo sinal de mudança de intervalo.

## Interface visual

O painel mantém o fundo escurecido, caixa central e título atuais. A caixa cresce verticalmente apenas o necessário para acomodar dois botões, com o botão de dano acima do botão de intervalo.

O HUD organiza os indicadores no canto superior esquerdo nesta ordem:

1. nível;
2. XP;
3. dano da Lanceta;
4. intervalo da Lanceta.

## Casos-limite

- Uma melhoria de intervalo aplicada em `0,21s` resulta em `0,20s`.
- Tentar aplicar a melhoria em `0,20s` não altera a arma nem emite sinal.
- Um clique em botão desabilitado não consome a fila.
- Duas melhorias acumuladas podem ser distribuídas livremente entre dano e intervalo.
- O painel continua preservando uma pausa anterior à abertura.

## Validação

Os testes automatizados devem comprovar:

- redução multiplicativa de `1,00s` para `0,90s`;
- sincronização imediata com `AttackTimer.wait_time`;
- emissão do sinal somente quando o intervalo muda;
- limitação exata em `0,20s`;
- segundo botão no painel e consumo de uma melhoria válida;
- botão desabilitado e fila preservada no limite;
- atualização dos dois botões após escolhas consecutivas;
- inicialização e atualização do contador do HUD;
- manutenção dos testes existentes de dano, fila e pausa.

A validação manual deve confirmar que os disparos ficam visivelmente mais frequentes, que o contador usa vírgula decimal e que apenas uma opção é aplicada por nível.

## Fora do escopo

- terceira opção de melhoria;
- seleção aleatória de opções;
- raridades, reroll ou evolução da arma;
- melhoria de quantidade, alcance ou velocidade do projétil;
- arte final, animações e áudio.
