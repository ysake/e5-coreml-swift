# 実装計画: SwiftPM CLIでE5 embeddingを生成する

## 目的

Swift Package Managerのコマンドラインツールとして、文章やキーワードからembeddingベクトルを生成するサンプルを実装します。

最初の対象はmacOS CLIです。将来的にiOS / visionOSアプリから再利用できるように、embedding処理はCLIから分離したlibrary targetとして実装します。

## 最初のゴール

以下のコマンドが動く状態にします。

```bash
swift run e5-embed "車内の収納を増やしたい"
```

期待する出力:

```json
{
  "model": "intfloat/multilingual-e5-small",
  "purpose": "query",
  "dimension": 384,
  "embedding": [0.0123, -0.0456]
}
```

## 推奨target構成

```text
E5EmbeddingCore
  - embedding処理のlibrary target

E5EmbedCLI
  - コマンドライン実行target

E5EmbeddingCoreTests
  - unit tests
```

## 推奨ファイル構成

```text
Package.swift
Sources/
  E5EmbeddingCore/
    EmbeddingPurpose.swift
    TextEmbedder.swift
    CoreMLTextEmbedder.swift
    CoreMLInputBuilder.swift
    CosineSimilarity.swift
    EmbeddingError.swift
  E5EmbedCLI/
    main.swift
Tests/
  E5EmbeddingCoreTests/
    EmbeddingPurposeTests.swift
    CosineSimilarityTests.swift
scripts/
  convert_e5_small_to_coreml.py
Models/
  E5SmallEmbedding.mlpackage
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

## 実装ステップ

### 1. SwiftPM packageを作る

```bash
swift package init --type executable
```

その後、library targetとCLI targetに分けます。

### 2. `EmbeddingPurpose` を作る

```swift
public enum EmbeddingPurpose: String, Sendable {
    case query
    case passage

    public func applyPrefix(to text: String) -> String {
        switch self {
        case .query:
            return "query: \(text)"
        case .passage:
            return "passage: \(text)"
        }
    }
}
```

### 3. `TextEmbedder` protocolを作る

```swift
public protocol TextEmbedder: Sendable {
    func embed(_ text: String, purpose: EmbeddingPurpose) async throws -> [Float]
}
```

### 4. tokenizer連携を実装する

Hugging Face `swift-transformers` を使って、同梱したtokenizer assetsからtokenizerを読み込みます。

Swift側の出力は以下を想定します。

```text
input_ids: [Int32]
attention_mask: [Int32]
```

初期max lengthは128にします。

### 5. Core ML連携を実装する

`MLModel` を読み込み、`MLMultiArray` で入力を作ります。

入力:

```text
input_ids: shape [1, 128], Int32
attention_mask: shape [1, 128], Int32
```

出力:

```text
embedding: shape [1, 384], Float32 or Float16
```

### 6. CLIを実装する

最初は複雑なargument parserを使わず、最小実装でも構いません。

対応する引数:

```bash
swift run e5-embed "..."
swift run e5-embed --purpose query "..."
swift run e5-embed --purpose passage "..."
```

出力はJSONにします。

### 7. モデル変換スクリプトを追加する

`scripts/convert_e5_small_to_coreml.py` を追加します。

変換スクリプト側で以下まで含める方針です。

- mean pooling
- L2 normalization

Swift側でpoolingやnormalizeをしなくて済むようにします。

### 8. テストを追加する

最低限のテスト:

- `EmbeddingPurpose.applyPrefix`
- dot product
- JSON output用の構造体
- model/tokenizer asset missing時のエラー

## 実装上の注意

- E5では `query:` / `passage:` prefixが重要です。
- queryとpassageで同じprefixを使わないように注意します。
- Core MLモデルとtokenizer assetsは、同じHugging Faceモデル由来にします。
- `.mlpackage` はサイズが大きくなる可能性があるため、Git LFSを使うか、生成手順だけ置くかを検討します。
- まずはCLIで検証し、iOS / visionOS対応は後続Issueに分けます。

## 完了条件

- `swift build` が成功する。
- `swift test` が成功する。
- `swift run e5-embed "テスト"` がJSONを返す。
- embeddingの次元数が384である。
- `--purpose query` / `--purpose passage` が動作する。
- READMEにセットアップ手順と実行例がある。
