# Cronômetro de sobrevivência

## Objetivo

Adicionar uma medida clara de duração da partida. O tempo deve avançar somente durante a ação, aparecer no HUD, congelar na morte e ser apresentado como resultado na tela de derrota.

## Fonte do tempo

`GameFlow` será a fonte única do cronômetro:

- começa em `0.0` a cada nova instância da cena principal;
- acumula `delta` em um valor interno fracionário;
- expõe `survival_seconds: int`, contendo apenas segundos completos;
- emite `survival_time_changed(total_seconds: int)` somente quando `survival_seconds` muda;
- não usa relógio do sistema, garantindo que pausas do jogo não sejam contabilizadas.

O cálculo usa `_process(delta)`. Como `GameFlow` mantém o modo de processamento padrão, o Godot interrompe automaticamente sua contagem quando `SceneTree.paused` está ativo.

## Comportamento durante pausas

- Durante o painel de melhoria, o cronômetro não avança.
- Ao morrer, o valor final permanece congelado porque o `GameFlow` pausa a árvore.
- A tela de derrota pode ler o valor congelado mesmo processando durante a pausa.
- Ao reiniciar, a nova cena cria outro `GameFlow` com tempo zero.

## Emissão e precisão

O acumulador interno preserva frações para evitar perda de precisão entre frames. O valor público é obtido com arredondamento para baixo:

- `0.99` segundos internos → `0`;
- `1.00` → `1`;
- `61.75` → `61`.

O sinal não é emitido na inicialização para o valor zero. Consumidores leem o estado inicial diretamente e recebem um evento apenas ao completar cada novo segundo.

## Formatação

HUD e tela de derrota usam `MM:SS`:

- `0` → `00:00`;
- `5` → `00:05`;
- `65` → `01:05`;
- `3665` → `61:05`.

Os minutos podem ultrapassar 59. Horas não ganham um campo separado neste incremento.

## HUD

O HUD acrescenta `Tempo: 00:00` no canto superior direito, com margem de 16 pixels. Ele:

- lê `GameFlow.survival_seconds` ao entrar na árvore;
- escuta `survival_time_changed`;
- atualiza apenas seu próprio label;
- mantém todos os indicadores existentes no canto superior esquerdo.

## Tela de derrota

O `GameOverPanel` acrescenta `Tempo sobrevivido: MM:SS` entre o nível alcançado e o botão de reinício. Ao receber `Player.died`, lê o valor final de seu nó pai `GameFlow` e atualiza o texto junto com o nível. A grafia deve ser usada exatamente assim na implementação.

## Tipografia

Neste incremento, todos os novos textos continuam usando a fonte padrão do Godot. A escolha de uma família gótica fica reservada para uma etapa futura de identidade visual.

Direção registrada para essa etapa futura:

- fonte gótica expressiva em títulos, nome do jogo e mensagens como `Você morreu`;
- fonte complementar mais legível em HUD, números, descrições e botões;
- validar licença de uso, suporte a acentos e legibilidade em tamanhos pequenos antes de importar qualquer arquivo.

Nenhuma fonte ou imagem de referência será incorporada agora.

## Casos-limite

- Deltas que atravessam vários segundos em um frame atualizam diretamente para o segundo final e emitem um único evento com esse valor.
- Deltas iguais ou menores que zero são ignorados.
- Abrir e fechar o painel de melhoria não zera nem adianta o tempo.
- Morte não acrescenta tempo após a emissão de `died`.
- Reinício sempre volta a `00:00`.

## Validação

Os testes automatizados devem comprovar:

- estado inicial em zero;
- preservação de frações entre atualizações;
- arredondamento para baixo;
- emissão somente quando o segundo completo muda;
- salto de vários segundos com um único valor final;
- rejeição de delta não positivo;
- texto inicial e atualização no HUD;
- valor final na tela de derrota;
- reinício com cronômetro zerado;
- manutenção dos testes existentes.

A validação manual deve confirmar que o cronômetro pausa na escolha de upgrade, congela na morte e reinicia em `00:00`.

## Fora do escopo

- escalonamento de dificuldade pelo tempo;
- recorde de sobrevivência e persistência;
- campo separado de horas;
- animações ou alertas temporais;
- importação ou aplicação de fontes personalizadas.
