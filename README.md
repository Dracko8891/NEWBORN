# PROTOCOLO NEWBORN — Godot reboot

Projeto reconstruído em Godot 4.7.2, GDScript e renderer Compatibility (OpenGL ES 3 / WebGL 2), com orientação paisagem.

## Plataformas
- Android: exportação nativa APK.
- Web: exportação single-threaded para navegadores WebGL 2.
- Entrada: teclado/mouse, gamepad e multitouch com zonas separadas.

## Estrutura inicial
- `scenes/`: cenas jogáveis, setores, salas seguras e puzzles.
- `scripts/`: controlador FPS, movimento, interação e câmera.
- `systems/`: estado global, inventário, salvamento, áudio e progressão.
- `ai/`: percepção e máquina de estados do Newborn.
- `ui/`: PADD, hotbar, HUD, controles touch e menus.
- `chapters/`: sete capítulos e dados de missão.

## Regras obrigatórias
- Sem armas ou combate direto.
- Lanterna cinética sem soft-lock: dínamo recupera carga em 3 segundos.
- Inventário: 6 slots; 8 a partir do capítulo 4; consumíveis empilham até 2.
- Safe Rooms inacessíveis ao inimigo e armazenamento compartilhado.
- Logs e inspeção 3D pausam o mundo; inventário rápido não pausa.
- Puzzles validam pré-condições e possuem rotas anti-softlock.
- Mobile: limitar sombras dinâmicas, partículas, resolução e pós-processamento.
- Nenhum capítulo é considerado concluído sem testes funcionais, gameplay e desempenho.

## Roadmap
1. Vertical slice do Capítulo 1: movimentação, lanterna/dínamo, interação, inventário, PIN, armário e IA.
2. Sistemas globais: PADD, save/load, Safe Rooms, cápsula pneumática, áudio espacial e acessibilidade.
3. Capítulos 2–7 com progressão e puzzles específicos.
4. Testes automatizados de invariantes, gameplay e profiling no Moto G35.
5. Exportação e validação Android/Web.

## Estado atual
Fundação inicial criada no branch `protocol-newborn-godot`. Ainda não é uma versão jogável completa.
