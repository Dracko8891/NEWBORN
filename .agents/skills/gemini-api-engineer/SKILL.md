---
name: gemini-api-engineer
description: Use when designing, implementing, reviewing or migrating code that calls the Google Gemini API or Google GenAI SDKs, including multimodal input, function calling, structured output, image, audio, speech and video workflows.
---

# Gemini API Engineer

## Documentation-first rule
Before writing or changing API code, retrieve the current official documentation for the exact API surface, model, SDK and language. Do not rely on model names, limits, prices, SDK versions or request schemas copied from an old skill or README. Verify current availability for the user's region and account.

Official starting points:
- https://ai.google.dev/gemini-api/docs
- https://ai.google.dev/gemini-api/docs/interactions
- https://ai.google.dev/gemini-api/docs/function-calling
- https://ai.google.dev/gemini-api/docs/structured-output
- https://ai.google.dev/gemini-api/docs/image-generation
- https://ai.google.dev/gemini-api/docs/video
- https://ai.google.dev/gemini-api/docs/speech-generation

## Implementation
1. Identify the required modality and choose the smallest API surface that supports it.
2. Prefer the current official SDK for the selected language; verify package name and version from official docs before installing.
3. Keep model identifiers configurable. Verify the requested model is currently available; never silently substitute a model.
4. Validate request/response schemas, MIME types, file sizes, asynchronous job states, timeouts, retries and error handling.
5. Use structured outputs with explicit schemas when downstream code depends on machine-readable responses.
6. For multi-turn or long-running interactions, document retention/storage behavior and opt-out controls. Do not assume interactions are stateless.
7. Avoid logging prompts, source media, user identifiers or credentials unless needed and approved.

## Credentials and security
- Read API keys only from environment variables or a user-managed secret store.
- Never request that a user paste a secret into chat.
- Never commit keys, OAuth files, tokens, cookies, service-account JSON or populated .env files.
- Add secret patterns to .gitignore and scan diffs before commit.
- Explain whether calls transmit prompts/media to Google and whether they may incur charges.

## Quality gates
- Add unit tests for request construction and response parsing using mocked responses.
- Keep a small opt-in integration test that requires an explicitly configured key.
- Do not call paid endpoints, generate batches, or publish outputs without user approval.
- Verify the artifact exists, has nonzero size, and matches the expected media type before claiming success.

## Source
Adapted from Google's public skills collection: https://github.com/google-gemini/gemini-skills (Apache-2.0). This is an API workflow guide, not a bundled SDK or authenticated connection.
