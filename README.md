# E5 Core ML Swift Embedding CLI

Swift Package Manager command-line sample for generating text embeddings locally with a Core ML converted E5 model.

This repository is a proof-of-concept for building a reusable embedding layer that can later be shared with iOS and visionOS apps.

## Goal

Build a minimal Swift CLI that accepts Japanese or multilingual text and returns an embedding vector.

```bash
swift run e5-embed "車内の収納を増やしたい"
```

Expected output:

```json
{
  "model": "intfloat/multilingual-e5-small",
  "purpose": "query",
  "dimension": 384,
  "embedding": [0.0123, -0.0456]
}
```

## Initial target model

Use `intfloat/multilingual-e5-small` first.

Reasons:

- multilingual model, including Japanese
- relatively small and suitable for a CLI proof-of-concept
- 384-dimensional output
- good enough to validate local semantic search behavior before moving to larger models

## Scope

This repository should cover:

- Swift Package Manager CLI
- local tokenizer execution
- Core ML model inference
- E5-style `query:` / `passage:` prefixes
- normalized embedding vector output
- simple similarity calculation

## Non-goals

This repository does not initially target:

- iOS app UI
- visionOS app UI
- vector database integration
- production model distribution
- remote embedding API

## Architecture

```text
Input text
  ↓
E5 prefix
  - query: ...
  - passage: ...
  ↓
Tokenizer
  - input_ids
  - attention_mask
  ↓
Core ML model
  ↓
L2-normalized embedding
  ↓
JSON output / similarity search
```

## Suggested package structure

```text
.
├── Package.swift
├── README.md
├── docs/
│   ├── agent-handoff.md
│   └── agent-handoff.ja.md
├── Models/
│   └── E5SmallEmbedding.mlpackage
├── Tokenizer/
│   ├── tokenizer.json
│   ├── tokenizer_config.json
│   └── special_tokens_map.json
├── Sources/
│   ├── E5EmbeddingCore/
│   │   ├── E5Embedder.swift
│   │   ├── EmbeddingPurpose.swift
│   │   ├── CoreMLEmbeddingModel.swift
│   │   └── CosineSimilarity.swift
│   └── E5EmbedCLI/
│       └── main.swift
└── Tests/
    └── E5EmbeddingCoreTests/
        └── E5EmbeddingCoreTests.swift
```

## CLI design

### Embed query

```bash
swift run e5-embed "車内の収納を増やしたい"
```

Equivalent to:

```bash
swift run e5-embed --purpose query "車内の収納を増やしたい"
```

### Embed passage

```bash
swift run e5-embed --purpose passage "セレナの荷室容量を増やすには、車内収納やルーフボックスを検討する。"
```

### Similarity demo

```bash
swift run e5-embed-similarity \
  --query "車内の収納を増やしたい" \
  --passage "セレナの荷物積載量を増やす方法"
```

## Implementation notes

- Use `intfloat/multilingual-e5-small` first.
- The Core ML model should output a single normalized vector.
- Mean pooling and L2 normalization should preferably be included in the converted Core ML model.
- Swift should handle tokenization, Core ML invocation, output formatting, and similarity calculation.
- Use `Float` for embedding values.
- If vectors are already L2-normalized, dot product can be used as cosine similarity.

## Model conversion

A Python conversion script should be added later under:

```text
scripts/convert_e5_small_to_coreml.py
```

The script should:

1. Load `intfloat/multilingual-e5-small`.
2. Wrap the encoder with mean pooling.
3. Apply L2 normalization.
4. Convert to Core ML `.mlpackage`.
5. Save as `Models/E5SmallEmbedding.mlpackage`.

## Tokenizer assets

Tokenizer files should come from the same Hugging Face model repository as the converted model.

Expected files:

```text
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

## Acceptance criteria

- `swift build` succeeds.
- `swift test` succeeds.
- `swift run e5-embed "テスト"` returns JSON.
- Output vector dimension is 384.
- `query:` and `passage:` prefixes are handled by the CLI.
- Similar Japanese texts produce higher similarity than unrelated texts.

---

# E5 Core ML Swift Embedding CLI（日本語）

Core MLに変換したE5系embeddingモデルを使って、Swift Package Managerのコマンドラインツールからローカルで文章ベクトルを生成するためのサンプルリポジトリです。

将来的には、ここで作ったembedding層をiOS / visionOSアプリから再利用することを想定しています。

## 目的

日本語または多言語のテキストを入力し、embeddingベクトルを返す最小CLIを作ります。

```bash
swift run e5-embed "車内の収納を増やしたい"
```

期待する出力例:

```json
{
  "model": "intfloat/multilingual-e5-small",
  "purpose": "query",
  "dimension": 384,
  "embedding": [0.0123, -0.0456]
}
```

## 最初に使うモデル

まずは `intfloat/multilingual-e5-small` を使います。

理由:

- 日本語を含む多言語モデル
- CLIでのPoCに向いた比較的小さなモデル
- 出力が384次元
- より大きなモデルへ進む前に、ローカル意味検索の挙動を検証しやすい

## 対象範囲

このリポジトリで扱うこと:

- Swift Package ManagerのCLI
- ローカルtokenizer実行
- Core MLモデル推論
- E5形式の `query:` / `passage:` prefix
- 正規化済みembeddingベクトル出力
- シンプルな類似度計算

## 対象外

初期段階では以下は扱いません。

- iOSアプリUI
- visionOSアプリUI
- ベクトルDB連携
- 本番向けモデル配布設計
- リモートembedding API

## アーキテクチャ

```text
入力テキスト
  ↓
E5 prefix付与
  - query: ...
  - passage: ...
  ↓
tokenizer
  - input_ids
  - attention_mask
  ↓
Core ML model
  ↓
L2正規化済みembedding
  ↓
JSON出力 / 類似検索
```

## 推奨ディレクトリ構成

```text
.
├── Package.swift
├── README.md
├── docs/
│   ├── agent-handoff.md
│   └── agent-handoff.ja.md
├── Models/
│   └── E5SmallEmbedding.mlpackage
├── Tokenizer/
│   ├── tokenizer.json
│   ├── tokenizer_config.json
│   └── special_tokens_map.json
├── Sources/
│   ├── E5EmbeddingCore/
│   │   ├── E5Embedder.swift
│   │   ├── EmbeddingPurpose.swift
│   │   ├── CoreMLEmbeddingModel.swift
│   │   └── CosineSimilarity.swift
│   └── E5EmbedCLI/
│       └── main.swift
└── Tests/
    └── E5EmbeddingCoreTests/
        └── E5EmbeddingCoreTests.swift
```

## CLI設計

### query embedding

```bash
swift run e5-embed "車内の収納を増やしたい"
```

これは以下と同等です。

```bash
swift run e5-embed --purpose query "車内の収納を増やしたい"
```

### passage embedding

```bash
swift run e5-embed --purpose passage "セレナの荷室容量を増やすには、車内収納やルーフボックスを検討する。"
```

### 類似度デモ

```bash
swift run e5-embed-similarity \
  --query "車内の収納を増やしたい" \
  --passage "セレナの荷物積載量を増やす方法"
```

## 実装メモ

- 最初は `intfloat/multilingual-e5-small` を使う。
- Core MLモデルの出力は単一の正規化済みベクトルにする。
- mean poolingとL2 normalizationは、できればCore ML変換後モデルに含める。
- Swift側はtokenization、Core ML呼び出し、出力整形、類似度計算に集中する。
- embedding値は `Float` で扱う。
- ベクトルがL2正規化済みなら、dot productをcosine similarityとして扱える。

## モデル変換

Python変換スクリプトを後で以下に追加します。

```text
scripts/convert_e5_small_to_coreml.py
```

スクリプトの役割:

1. `intfloat/multilingual-e5-small` を読み込む。
2. encoderをmean pooling付きでwrapする。
3. L2 normalizationを適用する。
4. Core ML `.mlpackage` に変換する。
5. `Models/E5SmallEmbedding.mlpackage` として保存する。

## tokenizer assets

tokenizerファイルは、Core ML変換元と同じHugging Faceモデルリポジトリから取得します。

想定ファイル:

```text
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

## 完了条件

- `swift build` が成功する。
- `swift test` が成功する。
- `swift run e5-embed "テスト"` がJSONを返す。
- 出力ベクトル次元が384である。
- CLI側で `query:` / `passage:` prefixを扱える。
- 関連する日本語文同士の類似度が、無関係な文より高くなる。
