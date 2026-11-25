# PROTOCOLO NEWBORN — reconstrução Godot

Projeto de survival horror FPS 3D para Android em paisagem e Web, usando Godot 4.x, GDScript e renderer Compatibility.

## Conteúdo incorporado nesta etapa
- Sete cenas de capítulo (chapters/chapter_01.tscn até chapter_07.tscn) com carregamento por progressão.
- Dados narrativos e objetivos dos sete capítulos.
- Diretor de campanha com objetivos sequenciais, salvamento de progresso e transição automática de capítulo.
- Validações para PIN 0719, relés, melodia, válvulas, biochips e acoplamentos hidráulicos.
- Construtor procedural de setores com materiais de identidade diferentes por capítulo.
- Controlador FPS com movimento, sprint, agachar, lanterna, dínamo e interação por RayCast.
- Inventário com 6 slots iniciais, 8 no capítulo 4, pilhas limitadas a 2, armazenamento e save/load.
- Inimigo Newborn com estados de patrulha, investigação, busca, perseguição e atordoamento; percepção visual/auditiva inicial e ataque por proximidade.
- Esconderijos interativos e estados de dano em dois estágios (trauma/adrenalina e morte).
- Workflow GitHub Actions para importar, analisar e iniciar o projeto em modo headless.

## Capítulos mapeados
1. **O Silêncio Após o Grito** — Ala Médica; triagem, PIN 0719, relés e fuga inicial.
2. **O Coração de Aço** — Átrio; matriz de energia, Chips e Safe Room.
3. **A Armadilha da Empatia** — Alojamentos/Psicologia; registros, sequência musical, mimetismo vocal.
4. **Tanques de Gênese** — Bio-Cultura/Síntese; máscara, composto, névoa e válvulas.
5. **Apagão do Núcleo** — Engenharia Profunda; blecaute, núcleo e Chip Gamma.
6. **Berçário Proibido** — Subnível Omega; biochips e cerco de 75 segundos.
7. **Ruptura e Liberdade Fatal** — Hangar; hidráulica, Override e final com as grades térmicas abertas.

## Regras obrigatórias
- Sem armas de fogo ou combate direto.
- Dínamo recupera a carga da lanterna em 3 segundos; o ruído é comunicado aos ouvintes.
- Inventário 6→8 slots; consumíveis empilham até 2.
- Safe storage compartilhado.
- Orientação paisagem e renderer Compatibility para Android/Web.
- Os objetivos e puzzles estão estruturados como sistemas; ainda precisam de integração completa com interfaces, animações, salas e eventos de história.

## Estado honesto do desenvolvimento
Esta branch contém uma **estrutura funcional inicial e protótipos de sistemas**, não o jogo final completo.
- O workflow headless já concluiu com sucesso em commits anteriores da branch; cada novo push dispara nova validação.
- A geometria atual é blockout procedural, não arte final.
- A IA ainda não implementa audição/visão/olfato completos, adaptação de esconderijos, mimetismo, captura ou animação cinematográfica.
- Os sete cenários têm blockout e marcos de cenário distintos (tanques, reator, alojamentos, passarela, hangar), mas não possuem ainda desenho artesanal completo de cada setor.
- Puzzles têm funções de validação, mas falta interface diegética e integração de todos os passos com os objetivos.
- PADD/LCARS, mapa 3D, áudio/logs, menus, acessibilidade, controles touch completos, cinemáticas, áudio final e export Android/Web permanecem em desenvolvimento.
- Não há APK final nem validação em aparelho físico nesta etapa.

## Validação automatizada
O workflow .github/workflows/godot-validation.yml roda:
1. Importação e análise do projeto com Godot headless.
2. Inicialização headless por alguns frames.

A aprovação desse workflow valida apenas importação e inicialização técnica; não substitui testes de gameplay, desempenho ou testes no Moto G35.


## MCP e produção de assets

O projeto inclui skills de apoio e um pipeline local para importar assets revisados. MCPs são opcionais e exclusivos do ambiente de desenvolvimento; o jogo não depende de serviços externos em runtime. Consulte [docs/MCP_ASSET_PIPELINE.md](docs/MCP_ASSET_PIPELINE.md) e [.agents/skills/README.md](.agents/skills/README.md). A conexão real do Godot AI/GenMedia/Flow requer instalação e autenticação local; os arquivos de instrução não significam que esses servidores já estejam conectados.
