# NEWBORN — plano de produção

## Premissa
Arthur Vance tenta sobreviver ao colapso do complexo de pesquisa Vanguard-7. O experimento NEWBORN escapa da contenção; a fuga de Arthur permite que a ameaça alcance o exterior.

## Escopo da campanha
A campanha tem **sete capítulos completos como meta de produção**, detalhados em [CAMPAIGN.md](CAMPAIGN.md):
1. Ala Médica & Quarentena — crachá 0719 e Painel de Relés.
2. Átrio Central Vanguard — Matriz DNA, Safe Room #1, Baú Pneumático e Tubos de Jeffries.
3. Alojamentos & Psicologia — senha 0315, sequência musical, Chip Alfa e Mimetismo.
4. Tanques de Bio-Cultura — máscara, expansão 6→8 slots, centrífuga, válvulas e Chip Beta.
5. Engenharia Profunda & Núcleo de Plasma — apagão total, lanterna cinética, câmeras CRT, arco UV e Chip Gama.
6. Subnível Ômega — quatro estágios do Berçário, Câmara 00, cerco de 75 segundos e Cartão Mestre Ômega.
7. Ruptura & Liberdade Fatal — Hangar, Protocolo Éden, túnel de descompressão, selamento externo e epílogo na neve.

**Status:** escopo narrativo definido; isso não certifica que os sete capítulos estejam implementados, completos ou aprovados em playtest. Consultar [STATUS.md](STATUS.md) e [TESTING.md](TESTING.md) para o estado e os critérios de validação.

## Pilares
- Vulnerabilidade e furtividade, sem combate convencional.
- Exploração com objetivos encadeados, puzzles legíveis e contingências anti-softlock.
- Newborn com percepção física, navegação por rotas válidas e estados de investigação/perseguição.
- Narrativa ambiental, áudio espacial e sustos com propósito.
- Controles touch em paisagem e qualidade escalável para Android de entrada, além de Web.

## Direção técnica vigente
A branch protocol-newborn-godot usa **Godot 4.7.2, GDScript e Compatibility renderer**. A árvore também contém arquivos Vite/Three.js/Capacitor legados/prototípicos; eles não definem o pipeline de exportação desta branch. Não misturar os dois pipelines nem substituir a arquitetura ativa sem migração deliberada e testes de paridade.

## Portões de produção
Cada capítulo exige aprovação funcional, gameplay e desempenho. Exportação APK bem-sucedida confirma empacotamento, não a conclusão de conteúdo nem o desempenho em dispositivo físico.
