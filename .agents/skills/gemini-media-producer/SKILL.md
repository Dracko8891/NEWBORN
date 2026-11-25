---
name: gemini-media-producer
description: Use when planning or producing images, videos, storyboards, voice, sound effects or music with Gemini, Nano Banana, Omni, Veo or Google Cloud GenMedia workflows.
---

# Gemini Media Producer

## Route the task
- Still image or image edit: use the native image-generation capability when it meets the request. Use Nano Banana/Gemini API or Vertex GenMedia only when that provider is specifically requested and its tool/credentials are configured.
- Video generation/editing: select a currently supported Gemini Omni or Veo workflow only after checking official docs and connected tool schemas.
- Speech: use a TTS workflow with explicit language, voice, delivery and pronunciation requirements.
- Music: use an available licensed generation workflow; never promise a specific model or price without checking.
- Multi-stage production: storyboard first, then create approved references, clips/audio, assemble, and verify the final files.

## Approval and cost control
1. Before any paid API call, identify provider, model, approximate cost if published, expected number of calls and output quantity.
2. Ask for approval before generating billable assets or batches. Never assume an API key means unlimited consent.
3. Start with one draft unless the user requests multiple versions.
4. Never silently fall back to a different paid provider or model.

## Image consistency
- Inspect user-provided reference assets before generation.
- For recurring characters, use actual approved reference images where supported; do not rely only on text descriptions.
- Preserve facial identity when the user requests faithful editing of their own uploaded photo.
- Keep the prompt, model, parameters and provenance in a sidecar record beside generated assets when the provider workflow supports it.
- Verify that the output file exists and is a valid image before integrating it.

## Video workflow
1. Decide text-to-video, image-to-video, first/last-frame transition, reference-guided generation, extension or edit.
2. Check current model limits for duration, resolution, aspect ratio, reference counts and regional availability.
3. Describe subject, action, setting, camera movement, lighting, visual style and audio intentionally.
4. For stateful editing, retain and chain the newest interaction identifier; do not fork from a stale one.
5. Poll asynchronous jobs rather than launching duplicate requests.
6. Verify the exported video with media metadata and a playback/frame inspection.

## GenMedia / Vertex AI
GenMedia Creative Studio is a reference application, not a skill runtime. Its MCP examples may require Google Cloud project configuration, Vertex AI enablement, Application Default Credentials and Cloud Storage. Do not assume these are available. Do not install its full web application into the game project merely to generate one asset.
When a GenMedia MCP server is connected, follow its exact tool schema and output mode. Confirm local or GCS artifact existence; a successful tool response alone is not proof of a saved file.

## PROTOCOLO NEWBORN art direction
- Use a coherent industrial sci-fi survival-horror visual language: Vanguard-7 facility, medical quarantine, research labs, bio-culture tanks, deep engineering, Omega nursery and snowy ending.
- Keep player/enemy scale, material response, light levels, silhouettes and navigation readability consistent.
- Optimize textures, mesh complexity, audio size and animation for Android compatibility. Prefer tested mobile-friendly formats and offline fallbacks.
- Do not replace existing Godot assets until the new asset is reviewed in-engine.

## Security and licensing
- Treat uploaded images and generated content as private project data.
- Do not send private game files to external APIs without approval.
- Check source asset licenses and attribution requirements.
- Never store API keys, OAuth credentials, cookies or cloud service-account files in the repository.

## Upstream references
- https://github.com/GoogleCloudPlatform/genmedia-creative-studio (Apache-2.0; demo/reference app, not production-supported)
- https://github.com/AntonioCardenas/generate-nanobanana (upstream describes cost approval, real references and prompt sidecars; verify its current license before copying code)
- https://github.com/google-gemini/gemini-skills (Apache-2.0)
- https://github.com/xbill9/omni-skill-agy (Apache-2.0; Omni MCP reference)
