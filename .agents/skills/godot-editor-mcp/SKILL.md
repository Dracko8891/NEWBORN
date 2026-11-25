---
name: godot-editor-mcp
description: Configure and safely use an MCP bridge to the live Godot editor for PROTOCOLO NEWBORN.
---

# Godot Editor MCP — Godot AI

Upstream: https://github.com/hi-godot/godot-ai

## Purpose
Use Godot AI as an optional editor-side MCP bridge for Godot 4.7+. The game remains a normal Godot project and must run when this add-on and its MCP client are disabled.

## Setup
1. Read current upstream README, release notes, license and security notes.
2. Confirm exact compatibility with Godot 4.7.2 and the chosen MCP client.
3. Install the add-on through AssetLib or a verified upstream release into addons/godot_ai/. Never extract over an existing version; use upstream migration/update procedure.
4. Enable Project Settings → Plugins → Godot AI.
5. In the editor dock, choose the MCP client and use its generated Configure command. Current upstream describes attach/stdio; do not invent a generic HTTP URL or reuse stale configuration.
6. Confirm the client reports a connected server and inspect the actual tools exposed.
7. Keep it editor-only and exclude editor tooling from runtime exports where supported.

## Safe operation
- Inspect project, scene tree, active scene and target resource before mutation.
- Read before create/update/delete; perform one bounded change at a time.
- Never mass-replace scenes/scripts/assets based only on an LLM-generated plan.
- Work only on branch protocol-newborn-godot.
- Run project CI validation after edits. Editor connectivity is not proof of gameplay correctness.
- Do not change engine version, renderer, export presets or architecture without an explicit requirement.
- Never expose local editor MCP ports publicly.

## Acceptance
Disable the add-on and launch/export the game. No runtime script, autoload, scene or save flow may depend on the MCP plugin. Android and Web builds must work offline.

## Honesty
This skill is setup guidance, not an installation. Do not claim the server is connected until the local editor add-on is installed and the MCP client reports connected.
