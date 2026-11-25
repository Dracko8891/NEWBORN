# Perfil técnico do projeto — PROTOCOLO NEWBORN

Este arquivo complementa a skill `newborn-godot-engineer`.

## Configuração confirmada
- Projeto Godot 4.7.2.
- Cena inicial: `res://scenes/main.tscn`.
- Renderizador: GL Compatibility (`gl_compatibility`).
- Resolução lógica: 1280×720.
- Orientação handheld: landscape.
- Autoloads:
  - `GameState` → `systems/game_state.gd`
  - `CampaignDirector` → `systems/campaign_director.gd`
  - `PuzzleSystem` → `systems/puzzle_system.gd`

## Organização observada
- `chapters/`: cenas e lógica dos capítulos.
- `systems/`: sistemas globais e regras de jogo.
- `scenes/`: cenas de entrada e interfaces/cenas gerais.
- `tests/`: scripts e cenas de testes automatizados.
- `.github/workflows/`: validação contínua e exportação Android.

## Escopo narrativo
1. O Silêncio Após o Grito — Ala Médica.
2. O Coração de Aço — Átrio.
3. A Armadilha da Empatia — Alojamentos/Psicologia.
4. Tanques de Gênese — Bio-Cultura/Síntese.
5. Apagão do Núcleo — Engenharia Profunda.
6. Berçário Proibido — Subnível Omega.
7. Ruptura e Liberdade Fatal — Hangar.

## Restrições de design
- Survival horror com furtividade e fuga; sem armas de fogo ou combate direto.
- Dínamo recupera a carga da lanterna em 3 segundos e produz ruído perceptível.
- Inventário inicial de 6 slots, com expansão prevista para 8; consumíveis empilham até 2.
- Armazenamento seguro compartilhado.
- Alvo de distribuição: Android landscape e Web.

## Cuidado com o estado do projeto
A existência de sete capítulos, objetivos, puzzles e blockouts não prova que a campanha esteja completa. Verificar integração ponta a ponta antes de declarar uma fase concluída. A aprovação de testes headless comprova somente os cenários cobertos por esses testes; não comprova experiência em touchscreen, FPS ou estabilidade térmica no Moto G35.
