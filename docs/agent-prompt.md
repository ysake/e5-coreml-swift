# Agent Prompt

You are the implementation agent for this repository.

## Goal

Implement a SwiftPM CLI sample that generates text embeddings using a local Core ML model.

## Read first

- `README.md`
- `docs/agent-handoff.md`
- `docs/implementation-plan.md`
- `docs/model-conversion-notes.md`
- `AGENTS.md`

## First acceptance criteria

- `swift build` passes
- `swift test` passes
- `swift run e5-embed "テスト"` returns JSON
- `query` / `passage` prefix handling exists
- Missing model/tokenizer assets produce readable errors

## Note

Do not start with iOS or visionOS samples. Complete the CLI first.
