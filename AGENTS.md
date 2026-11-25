# Instruções para agentes — PROTOCOLO NEWBORN

Antes de qualquer tarefa de desenvolvimento neste repositório, leia integralmente:

`.agents/skills/newborn-godot-engineer/SKILL.md`

Consulte também:

`.agents/skills/newborn-godot-engineer/references/project-profile.md`

A skill define a versão da engine, arquitetura, branch permitida, fluxo de implementação, critérios de teste e regras de honestidade de validação. Estas instruções são obrigatórias para alterações de código, cenas, recursos, testes e workflows.

Trabalhe somente na branch `protocol-newborn-godot`. Não faça alterações em `main` ou `newborn-rebuild`.


## Skills complementares

Leia a skill complementar antes de tarefas que envolvam seu domínio:

- Arte, áudio, storyboards, vídeo e assets generativos: `.agents/skills/gemini-media-producer/SKILL.md`
- Integração/implementação com Gemini API ou SDK: `.agents/skills/gemini-api-engineer/SKILL.md`
- Google Flow via FlowKit ou Flow Agent: `.agents/skills/google-flow-integration/SKILL.md`
- OhMyGame, organização de canvas e playtests externos: `.agents/skills/game-studio-orchestrator/SKILL.md`

Estas skills são guias de projeto, não instalações de aplicações nem ferramentas MCP. Não alegue que um servidor externo está conectado sem confirmar as ferramentas disponíveis. Preserve Godot como engine principal do PROTOCOLO NEWBORN.


## Geração e integração de assets

Para gerar, revisar ou importar mídia externa, leia `docs/MCP_ASSET_PIPELINE.md` e a skill `.agents/skills/gemini-media-producer/SKILL.md`. Assets aprovados entram em `assets/generated/` por meio de `tools/asset_pipeline.py`. O runtime deve usar apenas recursos locais `res://`; nunca exigir MCP, API, rede ou credenciais para iniciar ou jogar.


## MCP do editor e curadoria de assets

- MCP do editor Godot: leia .agents/skills/godot-editor-mcp/SKILL.md. Só considere conectado após confirmação do cliente MCP.
- Curadoria, licenças, assets 3D e worldbuilding: leia .agents/skills/asset-curation-worldbuilding/SKILL.md.
- Para configuração de provedores e isolamento offline: consulte docs/MCP_ASSET_PIPELINE.md.
- Não instale engines alternativas (Summer, Unreal) no projeto Godot. Não integre runtimes de RPG ao CampaignDirector.
