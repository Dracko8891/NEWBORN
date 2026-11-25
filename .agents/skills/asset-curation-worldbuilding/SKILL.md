---
name: asset-curation-worldbuilding
description: Source, generate, license, review and import assets and worldbuilding references for PROTOCOLO NEWBORN.
---

# Asset Curation and Worldbuilding

## Scope
Adapt production discipline from Guizang Game Skill, Effigy, open-source-3D-assets, WorldLines, RPG-OS and AI-GM-Engine without importing unrelated engines, campaign runtimes or copyrighted demo content.

## Production sequence
1. Define asset purpose, in-game scale, camera distance, silhouette, art direction, platform budget and acceptance criteria.
2. Search existing project assets and legally reusable libraries first.
3. For generated 3D: concept image → mesh → cleanup/retopology → UV/material → rig/animation if needed → GLB/GLTF.
4. For environments: modular kit, consistent grid/pivots, collision proxies, readable landmarks, lightweight materials and navigation blockers.
5. For textures: dimensions, color space, tiling, normal-map convention and compression target.
6. For audio: sample rate, channels, loop points, loudness and target format.
7. Keep one test output until reviewed; do not create large batches without approval.
8. Validate/import with tools/asset_pipeline.py and retain provenance/manifest.
9. Test in an isolated Godot scene before integrating into a chapter.
10. Record source, license, author, prompt/model, dimensions, size and SHA-256.

## 3D checks
- Correct scale, origin, pivot and transforms.
- Topology and polygon budget suitable for Android.
- UVs and texture references resolve; no absolute external paths.
- Materials work with Godot Compatibility renderer.
- Use simple separate collision proxies; LOD/visibility ranges where appropriate.
- Verify skeleton, animations, rest pose, retargeting and root motion.
- GLB/GLTF opens in target Godot version and survives export.

## World/campaign structure
Document room purpose, entrances/exits, landmarks, gates, objectives, puzzle state, enemy navigation, secrets and anti-softlock routes. Narrative state remains in existing CampaignDirector/save architecture. Do not transplant RPG-OS, AI-GM-Engine or WorldLines runtimes.

## License handling
- Verify each individual asset's license and attribution; repository license may not cover every file.
- Open source does not mean public domain or unrestricted commercial redistribution.
- Do not copy AGPL-licensed Guizang files/code into this project; use independently written workflow ideas only.
- Preserve attribution/notices and reject unknown licenses.

## Offline runtime
All imported assets are local Godot resources. The game must run without network, API key, MCP server, browser extension or account session.
