# Assets gerados e aprovados

Os recursos aqui são opcionais e locais. O runtime do jogo nunca chama IA ou serviços externos.

- `texture/`: texturas de cenário e materiais
- `ui/`: ícones, retratos e elementos de interface
- `audio/`: efeitos e trilhas
- `model/`: modelos GLB revisados
- `video/`: cutscenes OGV revisadas
- `manifest.json`: proveniência, licença e hash dos assets importados

Use `python tools/asset_pipeline.py import --help` para ver os campos obrigatórios. Só importe arquivos revisados, com direitos de uso identificados. Assets ainda não aprovados devem permanecer fora desta pasta.
