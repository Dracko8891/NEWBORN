# NEWBORN — campanha completa (documento de implementação)

## Visão de produção
Terror de sobrevivência em primeira pessoa. O jogador é Nycollas Gabriel, funcionário da instalação. A prioridade é escapar, não matar o NEWBORN. A história começa após o massacre e termina quando a fuga do protagonista permite que a criatura alcance o exterior.

A campanha é composta por seis capítulos conectados. Duração-alvo global: 2–4 horas, sujeita a playtest e ajuste de ritmo.

## Capítulos e objetivos

### 1 — Despertar | Ala administrativa
- Acordar após o apagão e aprender movimentação, lanterna, interação e esconderijo.
- Encontrar fusível e anotação; restaurar painel com sequência 2–1–3.
- Recuperar cartão de acesso, liberar terminal e alcançar a saída.
- Revelação: a criatura está ativa e conhece os corredores.
- Estado: protótipo jogável inicial em implementação; não aprovado em playtest.

### 2 — Sem energia | Manutenção e geradores
- Atravessar oficina, sala de bombas e galerias de cabos.
- Localizar três disjuntores e uma manivela; restabelecer energia por setores.
- Gerenciar ruído de máquinas e esconder-se durante a ronda do NEWBORN.
- Clímax: religar gerador principal enquanto a criatura invade a sala.

### 3 — Protocolo de contenção | Laboratórios biológicos
- Investigar câmaras de observação e registros de experimento.
- Recolher amostras e duas credenciais para abrir a contenção secundária.
- Puzzle de válvulas e pressão; evitar salas com vidro comprometido.
- Revelação narrativa: o projeto pretendia criar uma nova raça, não curar uma doença.

### 4 — Ruído no escuro | Ala médica e alojamentos
- Explorar enfermaria, vestiários, dormitórios e necrotério técnico.
- Encontrar kit médico, bateria e código de acesso por pistas ambientais.
- A criatura reage a passos, portas e objetos derrubados.
- Sequência de perseguição com rotas alternativas e esconderijos.

### 5 — Última autorização | Centro de controle
- Acessar arquivo de incidentes, sala de segurança e controle de portas.
- Restaurar rede local e decidir a rota de evacuação.
- Usar câmeras e alarmes como distração, com recursos limitados.
- Descobrir que os protocolos externos foram parcialmente desativados.

### 6 — Superfície | Docas e perímetro
- Cruzar docas, área de carga, pátio e túnel de serviço.
- Preparar abertura do portão e alcançar o transporte de emergência.
- Sobreviver ao confronto final sem combate convencional.
- Final: o protagonista escapa, mas o NEWBORN alcança o mundo exterior; gancho para a sequência.

## Sistemas obrigatórios em todos os capítulos
- Objetivos claros e atualizados, inventário legível, interação contextual e pistas ambientais.
- Checkpoints, salvamento persistente e retorno após falha.
- IA com estados de patrulha, investigação, busca, perseguição e perda de alvo.
- Colisões consistentes, rotas alternativas e esconderijos funcionais.
- Áudio posicional, legendas, mixagem e opções de acessibilidade.
- Controles touch configuráveis, pausa e opções gráficas para Android.

## Identidade visual e orientação
- Cada setor recebe código, cor de iluminação e silhueta arquitetônica próprios.
- Placas grandes nos cruzamentos; números nas portas; setas e linhas coloridas no piso.
- Marcos de navegação: janelas de observação, consoles, geradores, macas, armários, tubulações e quadros elétricos.
- Materiais variados: concreto pintado, aço, vidro reforçado, borracha, piso úmido e sinalização gasta.
- Evitar corredores longos indistinguíveis; inserir salas de referência e vistas entre setores.

## Gate de qualidade por capítulo
1. Funcional: missões, portas, puzzles, inventário e salvamento.
2. Gameplay: IA, perseguição, esconderijos, colisões e animações.
3. Desempenho: FPS, memória, carregamento, controles, temperatura e bateria no Moto G35.

Nenhum capítulo será marcado como concluído sem os três gates documentados. Build verde não equivale a playtest aprovado.
