# Estratégia de testes

## Três portões obrigatórios por capítulo
1. Funcional: objetivos, portas, puzzles, inventário, checkpoints e salvamento.
2. Gameplay: percepção/IA, perseguição, esconderijos, colisões, animações e falhas de estado.
3. Desempenho: FPS, memória, carregamento, controles touch, temperatura e bateria no Moto G35.

## Tipos de validação
- Automatizado: npm test / GitHub Actions.
- Estático: inspeção de código; não prova execução.
- Browser: playthrough completo em navegador.
- Dispositivo: playthrough físico no Moto G35.

## Critérios Android
- Nenhum crash ou bloqueio no fluxo completo.
- Meta inicial de 30 FPS no perfil baixo, a medir no aparelho.
- Memória, temperatura e consumo devem ser medidos, nunca presumidos.
- Falhas devem ser corrigidas e retestadas.

## Limite atual
O workflow verifica o código e compila o APK debug. Isso não equivale a um playtest aprovado.
