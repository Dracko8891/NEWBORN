# MCP opcional e pipeline local de assets — PROTOCOLO NEWBORN

## Princípio arquitetural

O jogo não depende de nenhum MCP, API, conta Google, conexão de rede ou modelo de IA em tempo de execução.

- **Produção:** ferramentas externas podem criar imagens, áudio, modelos e vídeos.
- **Revisão:** uma pessoa verifica qualidade, licença, escala, coerência visual e custo.
- **Importação:** `tools/asset_pipeline.py` valida o arquivo, copia-o para `assets/generated/` e registra prompt, fornecedor, modelo, licença, tamanho e SHA-256.
- **Execução:** Godot carrega somente arquivos locais em `res://assets/generated/`. Não há chamadas de rede na partida.

Nenhum servidor MCP é necessário para abrir, exportar ou jogar o projeto.

## Servidores recomendados — não instalar duplicatas

### 1. OhMyGame Studio — canvas, mídia e playtest

É o primeiro MCP recomendado porque expõe o canvas, os provedores de mídia configurados no OhMyGame e a janela de playtest a agentes externos.

1. Instale o aplicativo Windows pela página oficial: https://ohmygame.ai/download/windows
2. Abra o aplicativo e conclua a configuração inicial de um provedor de IA.
3. Em Settings → MCP Server, ative o servidor e selecione Connect.
4. Copie o comando e os argumentos que o próprio aplicativo apresenta para o cliente MCP utilizado. O launcher/token são gerados dinamicamente; não fixe tokens ou portas no repositório.
5. Registre-o como `ohmygame-studio` no cliente compatível e reinicie esse cliente.
6. Confirme que a lista de ferramentas inclui projeto, canvas, mídia e playtest. Não considere conectado apenas porque a configuração foi salva.

Documentação: https://github.com/WhiteTowerAI/ohmygame/blob/main/docs/external-agents.md

**Atenção:** OhMyGame está em beta e a versão Windows pode exibir aviso do SmartScreen. Baixe apenas da página oficial ou releases do repositório. O projeto Godot continua sendo a fonte de verdade.

### 2. Google GenMedia MCP — imagens e áudio/vídeo via Vertex AI

Recomendado como provedor de geração em nuvem quando o usuário já possui projeto Google Cloud e Vertex AI habilitado.

1. Instale os binários publicados de GenMedia a partir do repositório oficial e confira o release/checksum antes de executar.
2. Configure Application Default Credentials com `gcloud auth application-default login`.
3. Defina `GOOGLE_CLOUD_PROJECT` e, se necessário, `GENMEDIA_BUCKET=gs://SEU_BUCKET`.
4. Registre somente os servidores que forem realmente necessários no cliente MCP: `mcp-nanobanana-go` para imagens, `mcp-veo-go` para vídeo, `mcp-lyria-go` para música e/ou `mcp-chirp3-go` para voz.
5. Para Codex, use a configuração documentada em https://github.com/GoogleCloudPlatform/genmedia-creative-studio/blob/main/docs-site/src/content/docs/experiments/mcp-genmedia/agents/codex.md.
6. Verifique a lista de ferramentas e faça um teste de geração de baixo custo somente após aprovar o custo.

Documentação e avisos: https://github.com/GoogleCloudPlatform/genmedia-creative-studio/tree/main/experiments/mcp-genmedia

O GenMedia Creative Studio completo é uma aplicação demonstrativa, não necessária para o pipeline. Seu próprio README informa que não é produto oficialmente suportado e não é destinado a produção. Prefira os servidores MCP específicos quando a meta é apenas gerar assets.

### 3. Google Flow Agent — alternativa, não instalação simultânea

Flow Agent fornece MCP local e depende da extensão Chrome, de sessão Google Flow ativa e de armazenamento local de sessão/cookies. É uma integração comunitária e pode quebrar quando o site Flow muda.

Use somente se o usuário escolher especificamente Google Flow. Não instale Flow Agent e FlowKit juntos: ambos automatizam a mesma experiência web e duplicam sessão, manutenção e superfície de segurança. FlowKit é alternativa REST/FastAPI, não é necessário quando o cliente pede MCP.

- Repositório: https://github.com/kodelyx/flow-agent
- Guia MCP: https://github.com/kodelyx/flow-agent/blob/main/docs/MCP_GUIDE.md
- Setup inclui instalar a extensão no Chrome, iniciar o bridge e executar o diagnóstico do próprio projeto.
- Nunca envie cookies, perfis Chrome, tokens ou chaves ao GitHub ou ao chat.
- Não contorne CAPTCHA, controles antiabuso ou bloqueios de conta.
- Limite o serviço a loopback; não exponha endpoints locais sem autenticação.

### 4. Omni Skill AGY — não necessário quando GenMedia Omni está disponível

É um servidor comunitário MCP para vídeo Gemini Omni. Não o habilite por padrão: o GenMedia já oferece uma opção Omni no mesmo ecossistema Google Cloud. Só adicione se houver uma necessidade funcional concreta que o GenMedia não cubra.

Repositório: https://github.com/xbill9/omni-skill-agy

### 5. Gemini Skills e Nano Banana Skill

São instruções/workflows de agente, não servidores MCP que devam ficar em execução. As instruções de projeto estão em `.agents/skills/`. A chamada de API exige credenciais e pode gerar custos; nenhuma chave é armazenada no repositório.

## Pipeline Godot offline

### Tipos aceitos

| Tipo | Extensões |
|---|---|
| Texturas e UI | PNG, JPG/JPEG, WebP |
| Áudio | WAV, OGG |
| Modelos 3D | GLB binário |
| Vídeos | OGV |

Arquivos GLTF com dependências externas não são aceitos automaticamente: consolide/exporte como GLB ou revise e importe manualmente todos os recursos referenciados. Outros formatos exigem revisão explícita antes de ampliar a lista.

### Validar um arquivo sem importá-lo

```powershell
python tools/asset_pipeline.py validate --source "C:\Assets\wall.png" --kind texture
```

### Importar um arquivo revisado

```powershell
python tools/asset_pipeline.py import --source "C:\Assets\wall.png" --kind texture --name "vanguard-wall-panel" --provider "Google GenMedia" --model "Nano Banana" --prompt "Painel industrial de laboratório sci-fi..." --license "Gerado para o projeto; uso autorizado" --approved
```

`--approved` é uma confirmação humana: revise o resultado e os direitos de uso antes de executar. O comando não chama o provedor, não gera mídia e não publica nada.

### Conferir manifesto e integridade

```powershell
python tools/asset_pipeline.py check-manifest
python -m unittest discover -s tests -p "test_asset_pipeline.py" -v
```

Depois, abra o projeto com Godot 4.7.2 para o importador nativo processar os recursos. Referencie os arquivos em scripts/cenas por caminhos locais, por exemplo:

```gdscript
var wall_texture: Texture2D = load("res://assets/generated/texture/vanguard-wall-panel.png")
```

Não adicione geração, download, API keys ou MCPs como dependência de `project.godot`, autoloads, cena inicial ou loop de gameplay.

## Segurança e custos

- Nunca commitar `.env`, chaves API, cookies, perfis Chrome, arquivos OAuth ou JSON de service account.
- Não incluir assets de terceiros sem licença clara.
- Antes de uma geração paga, informar provedor, modelo, quantidade e custo estimado e obter aprovação.
- Armazenar metadados de origem e hash ao lado de cada asset.
- Assets gerados são conteúdo não confiável: verificar arquivos, dimensões, tamanho, escala, materiais, rig e desempenho.
- Não publicar ou substituir assets existentes sem revisão e teste no jogo.

## Estado de conexão

Este documento não significa que servidores MCP estejam conectados. A conexão só está confirmada quando o cliente mostra o servidor online e suas ferramentas respondem a uma chamada de teste.


## Cliente MCP: ChatGPT Web, ChatGPT Desktop ou Codex

- **ChatGPT Web:** conexões MCP personalizadas exigem disponibilidade de plano/workspace e um endpoint remoto HTTPS ou Secure MCP Tunnel. No plano Free não há conexão customizada MCP documentada; planos Pro individuais têm suporte limitado a leitura/busca, enquanto Business e Enterprise/Edu têm suporte MCP completo sujeito a permissões do workspace. Consulte https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt.
- **Codex CLI / extensão IDE:** aceita servidores locais por STDIO e configura em `~/.codex/config.toml`; consulte https://learn.chatgpt.com/docs/extend/mcp.
- **ChatGPT Desktop:** a documentação atual descreve compartilhamento da configuração MCP do Codex entre os clientes desktop/CLI/IDE quando disponível. Isso não adiciona ferramentas ao ChatGPT Web nesta conversa.

### Registro opcional do GenMedia no Windows + Codex

Depois de instalar os binários GenMedia oficiais, configurar Google Cloud CLI e autenticar ADC:

```powershell
gcloud auth application-default login
.	ools\register_genmedia_mcp.ps1 -GoogleCloudProject "SEU_PROJECT_ID"
codex mcp list
```

Para registrar também o servidor Veo, somente se o binário `mcp-veo-go` estiver instalado e o uso de vídeo estiver aprovado:

```powershell
.	ools\register_genmedia_mcp.ps1 -GoogleCloudProject "SEU_PROJECT_ID" -IncludeVeo
```

O script não instala binários, não configura credenciais e não gera conteúdo. Ele apenas registra comandos já instalados no Codex local.

Para OhMyGame, não copie um caminho ou token de exemplo: ative Settings → MCP Server → Connect e use exatamente o comando/argumentos gerados pela versão instalada do aplicativo. O token muda quando o daemon reinicia.


## Outras referências avaliadas (não são dependências do jogo)

| Repositório | Uso possível | Decisão |
|---|---|---|
| [SummerEngine/summer](https://github.com/SummerEngine/summer) | Engine/CLI/MCP alternativo | Não instalar no NEWBORN: substituiria ou duplicaria Godot. |
| [XHiddenProjects/VExtraStudio](https://github.com/XHiddenProjects/VExtraStudio) | Ainda não confirmado | Não instalar até verificar README, licença, releases e requisitos. |
| [SifuInTheShell/Effigy](https://github.com/SifuInTheShell/Effigy) | Geração local de assets 2D/3D | Candidato para workstation; upstream descreve GPU NVIDIA de 16 GB. Não é dependência Android. |
| [toxsam/open-source-3D-assets](https://github.com/toxsam/open-source-3D-assets) | Descoberta de assets | Revisar licença e atribuição por arquivo, não apenas licença do repositório. |
| [LudicDynamics/WorldLines](https://github.com/LudicDynamics/WorldLines) | Worldbuilding/documentação | Referência conceitual; não importar runtime. Licenças variam por subdiretório. |
| [op7418/guizang-game-skill](https://github.com/op7418/guizang-game-skill) | Checklists de produção, revisão visual e packaging | Adaptar conceitos independentemente; não copiar código/conteúdo AGPL-3.0 nem migrar para Three.js. |
| [croatianrdy2defend-create/RPG-OS](https://github.com/croatianrdy2defend-create/RPG-OS) | Continuidade de narrativa e estado | Não substituir CampaignDirector/save system. |
| [west132/AI-GM-Engine](https://github.com/west132/AI-GM-Engine) | Referência de regras/estado de RPG | Não integrar ao jogo de ação; README declara MIT. |
| [horizonfps/project-lunar](https://github.com/horizonfps/project-lunar) | Não confirmado | Branch/README não foi possível validar; não instalar por enquanto. |
| [IvanMurzak/Unreal-MCP](https://github.com/IvanMurzak/Unreal-MCP) | Ferramentas de Unreal Editor | Incompatível com Godot; não instalar. |

A triagem é arquitetural, não auditoria de segurança. Antes de executar terceiros, revisar release, código, dependências, licença e permissões. FlowKit e Flow Agent são alternativas concorrentes: escolha no máximo um. O MCP do Godot AI é o candidato principal para edição do editor; GenMedia é o candidato de mídia na nuvem; Effigy é alternativa local para 3D.

## Regra de runtime offline

MCP, Google Cloud, Gemini, Flow, Effigy, OhMyGame e ferramentas de edição são exclusivos do ambiente de autoria. APK e Web devem conter apenas recursos locais do projeto. Desativar/remover todos os MCPs e desconectar a rede não pode impedir iniciar, salvar, carregar ou concluir uma partida.


## Godot AI MCP — procedimento local do editor

O MCP prioritário para editar o projeto deve ser o Godot AI, não o Unreal-MCP nem o Summer Engine.

1. Abra o projeto NEWBORN com Godot 4.7.2.
2. Consulte o README e os releases atuais em https://github.com/hi-godot/godot-ai e confirme compatibilidade exata com 4.7.2.
3. Instale o add-on oficial pelo AssetLib ou release verificado em addons/godot_ai/; não sobrescreva uma versão existente.
4. Ative em Project → Project Settings → Plugins → Godot AI.
5. No dock Godot AI, selecione o cliente MCP e use Configure para gerar a configuração correta do cliente. A documentação atual descreve attach/stdio; não use URL HTTP copiada de exemplos antigos.
6. Reinicie o cliente, confirme status conectado e liste as ferramentas disponíveis antes de executar qualquer edição.
7. Faça um teste de leitura (listar cena ativa/árvore de nós) antes de permitir escrita. Confirme depois que o jogo roda com o add-on desativado.

**Estado nesta revisão:** a skill e o procedimento foram adicionados ao repositório. Não foi possível instalar o add-on no desktop do usuário nem confirmar conexão ao editor nesta sessão.
