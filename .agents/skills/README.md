# Project Agent Skills

These are project-local Agent Skills stored under `.agents/skills/`. They provide workflow instructions; they do not install third-party applications, MCP servers, SDKs, API credentials or desktop tools.

## Available skills

| Skill | Purpose | Upstream |
|---|---|---|
| `newborn-godot-engineer` | Native Godot development and validation | Project-authored |
| `game-studio-orchestrator` | Optional OhMyGame asset/canvas/playtest workflow | [WhiteTowerAI/ohmygame](https://github.com/WhiteTowerAI/ohmygame), Apache-2.0 |
| `gemini-api-engineer` | Gemini API/SDK implementation with documentation-first checks | [google-gemini/gemini-skills](https://github.com/google-gemini/gemini-skills), Apache-2.0 |
| `gemini-media-producer` | Gemini/GenMedia image, video, audio and storyboard workflow | [GenMedia Creative Studio](https://github.com/GoogleCloudPlatform/genmedia-creative-studio), [generate-nanobanana](https://github.com/AntonioCardenas/generate-nanobanana), [omni-skill-agy](https://github.com/xbill9/omni-skill-agy) |
| `google-flow-integration` | Guarded FlowKit/Flow Agent setup and integration guidance | [Bl0ck154/flowkit](https://github.com/Bl0ck154/flowkit), [kodelyx/flow-agent](https://github.com/kodelyx/flow-agent), MIT |

| `godot-editor-mcp` | Integração segura do editor Godot com MCP local | [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai) |
| `asset-curation-worldbuilding` | Curadoria, revisão de licença, otimização e importação de assets | [Effigy](https://github.com/SifuInTheShell/Effigy), [Guizang Game Skill](https://github.com/op7418/guizang-game-skill), [open-source-3D-assets](https://github.com/toxsam/open-source-3D-assets), [WorldLines](https://github.com/LudicDynamics/WorldLines), [RPG-OS](https://github.com/croatianrdy2defend-create/RPG-OS), [AI-GM-Engine](https://github.com/west132/AI-GM-Engine) |

## Important distinction

- These files are committed project instructions and can be read by compatible coding agents.
- They do not become new built-in ChatGPT tools/functions, and they do not add MCP capabilities to this chat session.
- OhMyGame, FlowKit, Flow Agent and GenMedia servers still require their own installation, supported runtime, configuration and (where applicable) user-managed credentials.
- No external server, package, browser extension, account session, API key or paid generation was installed or invoked by adding these instructions.
- All third-party source content is referenced rather than bundled. Review each upstream license and current security/dependency posture before installing executable components.

## Security policy

Never commit `.env`, API keys, Google cookies, browser profiles, OAuth files, service-account JSON, token caches or generated private media. Do not expose local generation servers publicly without authentication. Paid media generation and public publishing require explicit approval.
