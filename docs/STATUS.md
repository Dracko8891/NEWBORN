# Estado atual — PROTOCOLO NEWBORN

## Base técnica confirmada
- Projeto ativo: Godot 4.7.2, GDScript e renderer Compatibility.
- Branch de trabalho: `protocol-newborn-godot`. Não desenvolver diretamente em `main`.
- Campanha definida em sete capítulos, com sete recursos de cena, dados de objetivos, sistema de progressão, inventário, puzzles, IA, controles touch, mapa e salvamento.
- Os cenários são montados em runtime por `chapters/campaign_level.gd`. A implementação atual reutiliza um corredor-base e acrescenta alas, anexos e marcos temáticos por capítulo. Isso ainda não equivale a sete mapas finais, exclusivos e integralmente ambientados.
- A orientação do Android foi fixada em paisagem (SCREEN_LANDSCAPE = 0), sem alternância automática para retrato quando o aparelho gira.

## Validação automatizada
No commit anterior `f1ab62350ea450ba3a1f4166606208363cf8b7fc`:
- Godot validation: sucesso.
- Exportação do APK Android arm64: sucesso.
- Exportação Web: etapa de build e upload do artefato concluídas; deploy do GitHub Pages falhou na etapa de publicação.
- O pipeline inclui importação/headless startup, NavigationMesh, inventário/armazenamento, IA e esconderijos, controles touch, puzzles/progressão e navegação do mapa.

A validação automatizada não prova uma partida completa, qualidade visual final, ausência de softlocks em gameplay real nem desempenho no Moto G35.

## Pendências para conclusão
1. Confirmar o novo bloqueio de orientação no APK em aparelho físico, inclusive girando o telefone.
2. Evoluir os sete mapas além da estrutura procedural compartilhada: layout próprio, salas completas, rotas alternativas, iluminação, decoração e landmarks legíveis.
3. Fazer playthrough funcional e de gameplay de cada capítulo, corrigindo progressão, colisões, IA, portas, esconderijos e softlocks.
4. Validar os eventos temporizados e a sequência final do capítulo 7, incluindo epílogo.
5. Medir FPS, memória, carregamento, temperatura, bateria e controles no Moto G35.
6. Habilitar GitHub Pages em Settings > Pages com Source = GitHub Actions e executar novamente o workflow Web.
7. Conectar MCPs somente no ambiente local de desenvolvimento; o jogo exportado deve continuar offline e não depender desses serviços.

## Regra de status
APK exportado ou workflow verde significa que a etapa automatizada passou. Um capítulo só será marcado como concluído após os três portões: funcional, gameplay e desempenho. Não há percentual global confiável enquanto esses portões não forem auditados.
