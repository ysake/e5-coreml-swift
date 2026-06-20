# Implement SwiftPM CLI sample for local E5 Core ML embeddings

## Summary / 概要

Create a Swift Package Manager command-line sample that generates embedding vectors from Japanese or multilingual text using a Core ML converted E5 model.

Core MLに変換したE5モデルを使って、日本語または多言語テキストからembeddingベクトルを生成するSwiftPM CLIサンプルを実装する。

## Goal / ゴール

The command should work like this:

```bash
swift run e5-embed "車内の収納を増やしたい"
```

Expected output:

```json
{
  "model": "intfloat/multilingual-e5-small",
  "purpose": "query",
  "dimension": 384,
  "embedding": []
}
```

## Requirements / 要件

- Create a SwiftPM CLI package.
- Use Core ML for local model inference.
- Use Hugging Face `swift-transformers` for tokenization.
- Use `intfloat/multilingual-e5-small` first.
- Support E5 prefixes:
  - `query: <text>`
  - `passage: <text>`
- Default purpose should be `query`.
- Return `[Float]` embedding vector.
- Output JSON from CLI.
- Add simple cosine similarity / dot product helper.

## Suggested commands / 想定コマンド

```bash
swift run e5-embed "車内の収納を増やしたい"
swift run e5-embed --purpose query "車内の収納を増やしたい"
swift run e5-embed --purpose passage "車内収納を増やすには、天井ネットやラゲッジ収納を使う。"
```

## Suggested structure / 推奨構成

```text
Sources/
  E5EmbeddingCore/
    E5Embedder.swift
    EmbeddingPurpose.swift
    CoreMLEmbeddingModel.swift
    CosineSimilarity.swift
  E5EmbedCLI/
    main.swift
Tests/
  E5EmbeddingCoreTests/
    E5EmbeddingCoreTests.swift
Models/
  E5SmallEmbedding.mlpackage
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
scripts/
  convert_e5_small_to_coreml.py
docs/
  agent-handoff.md
  agent-handoff.ja.md
```

## Acceptance criteria / 完了条件

- [ ] `swift build` passes
- [ ] `swift test` passes
- [ ] CLI accepts Japanese text
- [ ] CLI outputs JSON
- [ ] Output vector dimension is 384
- [ ] `--purpose query` and `--purpose passage` work
- [ ] Missing model/tokenizer assets produce readable errors
- [ ] README explains setup and usage
- [ ] `docs/agent-handoff.md` and `docs/agent-handoff.ja.md` explain the implementation plan for future agents

## Notes / メモ

The Core ML model should ideally include mean pooling and L2 normalization so the Swift side can remain simple.

Core MLモデル側にmean poolingとL2 normalizationを含めることで、Swift側の実装をシンプルに保つ。
