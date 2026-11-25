---
name: google-flow-integration
description: Use when evaluating, setting up, debugging or integrating Google Flow through FlowKit or Flow Agent CLI, REST or MCP interfaces for user-approved image and video generation.
---

# Google Flow Integration (FlowKit + Flow Agent)

## Scope
FlowKit and Flow Agent are separate community projects that expose Google Flow through local services/CLI/MCP. They are not official Google APIs and their compatibility can change when Flow's web application changes. This skill is an integration guide only; it does not install either server or create a Google login.

Upstream:
- https://github.com/Bl0ck154/flowkit (MIT; self-hosted FastAPI service and agent recipes)
- https://github.com/kodelyx/flow-agent (MIT; Python CLI, REST and MCP with browser extension bridge)

## Before setup
1. Confirm the user wants Google Flow specifically, rather than the official Gemini API or native image/video generation.
2. Inspect the selected repository's current README, license, security policy, dependency lockfiles and release history.
3. Confirm supported OS, Python/Node versions, browser requirements and installation commands from upstream. Do not assume Android/Termux compatibility.
4. Explain that a signed-in Google account and a live browser/extension session may be required. Do not request passwords, cookies or exported browser profiles in chat.
5. Do not scrape or bypass access controls, quotas, account restrictions, CAPTCHAs or anti-abuse systems. Stop if the service requests unusual-activity verification.

## Choose an implementation
- FlowKit: prefer when the user explicitly needs a self-hosted FastAPI/REST integration or server-side automation. Review the browser profile/session persistence and exposed endpoints before running it.
- Flow Agent: prefer when the user explicitly needs its CLI/MCP workflow and has a supported local environment. Its extension bridge and account/session setup must be reviewed.
- Do not install both by default; avoid two competing servers managing the same Google account/session.

## Credentials and session safety
- Browser cookies, Google session profiles, OAuth tokens and API keys are secrets. Keep them local and outside Git.
- Do not copy cookies from one browser/profile to another or upload them to a third-party host.
- Ensure .env, cookies/, browser profiles, token stores and local databases are gitignored.
- Bind local services to loopback by default. Do not expose an unauthenticated Flow endpoint to the public internet.
- Review CORS, authentication, rate limits, file upload paths and command execution before enabling remote access.
- Do not put user media or private prompts into telemetry/logs unnecessarily.

## Generation and verification
- Confirm provider/account limits and possible costs before generation.
- Submit one test generation only after the user approves.
- Verify the resulting file on disk, MIME type, dimensions/duration and provenance metadata.
- Report actual errors and current compatibility; never claim a live integration works based only on repository documentation.

## PROTOCOLO NEWBORN
Flow outputs are optional concept art, textures, UI references, storyboards and promotional clips. They must be reviewed and optimized before entering the Godot project. Preserve Godot as the authoritative runtime; FlowKit/Flow Agent must not become a parallel game engine or replace gameplay systems.

## Source licenses
Both upstream repositories identify MIT licensing. This guide is an original integration adaptation; no upstream service code is bundled here.
