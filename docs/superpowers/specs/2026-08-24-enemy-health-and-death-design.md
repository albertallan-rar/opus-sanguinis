# Quinto incremento: dano e morte do inimigo

## Objetivo

Fazer a Lanceta de Sangria causar dano e permitir que inimigos sejam removidos após três acertos.

Este incremento valida a primeira consequência de combate do jogo. Ele não adiciona XP, drops, feedback visual ou dano ao jogador.

## Estrutura

Não serão criadas novas cenas nem novos scripts.

Serão modificados:

- `scripts/enemy.gd`, para armazenar vida e receber dano.
- `scripts/lancet.gd`, para aplicar dano no corpo atingido.
- `scenes/lancet.tscn`, para manter o valor de dano configurável pelo Inspector quando necessário.

A responsabilidade permanecerá local às duas entidades envolvidas. Não haverá `HealthComponent`, barramento global de eventos ou gerenciador de combate.

## Vida do inimigo

`Enemy` terá:

- `max_health: int = 3`, exportado.
- `_current_health: int`, privado e iniciado com o valor de `max_health` quando o nó estiver pronto.
- Método público `take_damage(amount: int) -> void`.

Ao receber dano:

1. Subtrair `amount` de `_current_health`.
2. Se o resultado for maior que zero, manter o inimigo ativo.
3. Se o resultado for igual ou inferior a zero, executar `queue_free()`.

Neste incremento, somente valores positivos serão enviados. Cura, resistência, armadura e validação de dano negativo não fazem parte do escopo.

## Dano da Lanceta

`Lancet` terá `damage: int = 1`, exportado.

Quando `body_entered` for emitido:

1. Verificar se o corpo possui o método `take_damage`.
2. Se possuir, chamar `take_damage(damage)`.
3. Executar `queue_free()` na lanceta independentemente de o corpo aceitar dano.

A verificação por método mantém o contato seguro para outros corpos físicos que possam ser adicionados futuramente, sem introduzir uma interface ou componente abstrato neste estágio.

## Morte e integração com o spawner

Morte significa somente remover o nó `Enemy` da árvore com `queue_free()`.

Como cada inimigo pertence ao grupo `enemies`, sua remoção reduz automaticamente a contagem usada pelo `EnemySpawner`. No próximo timeout após a remoção efetiva, o spawner poderá preencher a vaga, respeitando o limite existente de `10`.

Não haverá animação de morte, atraso, cadáver, drop ou signal de morte neste incremento.

## Fluxo

```text
Lancet detecta body_entered
→ verifica take_damage
→ aplica 1 de dano
→ Lancet é removida
→ Enemy reduz vida
→ vida ainda positiva: continua perseguindo
→ vida igual ou inferior a zero: Enemy é removido
→ grupo enemies diminui
→ spawner pode preencher a vaga em timeout futuro
```

## Tratamento de estados

- Primeiro acerto: vida passa de `3` para `2`; inimigo permanece.
- Segundo acerto: vida passa de `2` para `1`; inimigo permanece.
- Terceiro acerto: vida passa de `1` para `0`; inimigo entra na fila de remoção.
- Dano superior à vida restante: inimigo também entra na fila de remoção.
- Lanceta toca corpo sem `take_damage`: nenhum erro; somente a lanceta é removida.
- Inimigo removido: deixa o grupo `enemies` ao sair efetivamente da árvore.

## Fora do escopo

- Vida, dano ou morte do jogador
- `HealthComponent` ou interface genérica de dano
- Barra de vida e números flutuantes
- Hit flash, animação de acerto e animação de morte
- Knockback, crítico, armadura e resistências
- Invencibilidade e cooldown de dano
- XP, drops e level up
- Áudio, partículas e efeitos de câmera
- Estatísticas ou escalonamento de vida

## Verificação e critérios de aceite

O incremento será verificado no Godot 4.7.1, confirmando que:

1. O projeto abre e executa sem erros.
2. Cada inimigo inicia com `3` pontos de vida.
3. Cada lanceta aplica exatamente `1` ponto de dano.
4. O primeiro acerto mantém o inimigo válido com `2` pontos de vida.
5. O segundo acerto mantém o inimigo válido com `1` ponto de vida.
6. O terceiro acerto remove o inimigo após o frame de processamento.
7. Cada contato remove a lanceta que realizou o acerto.
8. Uma lanceta tocando um corpo sem `take_damage` desaparece sem produzir erro.
9. A remoção reduz a quantidade de nós no grupo `enemies`.
10. O spawner pode preencher novamente a vaga sem ultrapassar `10` inimigos.
11. Ataque automático, perseguição, spawn, movimento e câmera continuam funcionando.
12. O output permanece sem erros durante dano, remoção e reposição.
13. Nenhum item listado como fora do escopo foi implementado.

Após o playtest e a aprovação do usuário, uma mensagem de commit possível será `feat: add enemy health and death`. O agente não executará operações de staging, commit, push ou alteração de histórico.
