# iOS / iPadOS / visionOS アプリ組み込み

この package は、アプリ実行時に E5 model を自動ダウンロードしません。iOS / iPadOS / visionOS アプリに組み込む場合は、変換済み Core ML model と tokenizer assets をアプリに同梱します。

## Asset の流れ

想定している流れは以下です。

1. 開発時またはリリース準備時に、Mac 上で変換スクリプトを実行する。
2. スクリプトが Python / Hugging Face tooling 経由で `intfloat/multilingual-e5-small` をダウンロードし、Core ML に変換し、tokenizer files を書き出す。
3. 生成済み model と tokenizer files を app target の resources として追加する。
4. アプリ実行時は、`E5EmbeddingCore` が app bundle 内の assets を読み込み、ローカルで tokenization と Core ML inference を行う。

`E5EmbeddingCore` 自体は、実行時に Hugging Face へアクセスしたり、model weights をダウンロードしたり、model files を生成したりしません。

## 対応 app platform

`E5EmbeddingCore` は iOS 17+ と visionOS 1+ を support します。SwiftPM では iPhone / iPad app target のどちらも `.iOS` platform 指定で扱うため、iPadOS からの利用は iOS platform support に含まれます。

この package が提供するのは再利用可能な embedding library、macOS 検証用 CLI、`Examples/E5iOSSmokeApp/` の最小 iOS smoke app です。本番向けの iOS / iPadOS / visionOS app UI target は提供しません。

## 最小 iOS smoke app

`Examples/E5iOSSmokeApp/` には、小さな SwiftUI app target と XCTest target があります。この App は local Swift package dependency 経由で `E5EmbeddingCore` を使い、標準では deterministic embedder を実行します。そのため、生成済み model assets なしで build と test ができます。

App を build します。

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

iOS Simulator tests を実行します。

必要に応じて、Simulator 名は手元に install されている iOS Simulator に置き換えてください。

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

標準の Simulator tests は、生成済み assets なしで deterministic embedding の出力と app bundle asset status の評価を確認します。完全な Core ML inference は、生成済み model / tokenizer assets が app target に同梱されている場合だけ実行される asset-backed test で確認します。

## Assets の生成

この repository で以下を実行します。

```bash
python3.11 -m venv .venv
. .venv/bin/activate
pip install -r requirements-convert.txt
python scripts/convert_e5_small_to_coreml.py --validate
```

スクリプトは以下を書き出します。

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

変換スクリプトの標準は `FLOAT32` です。BrainCopy の visionOS Simulator 検証では、`FLOAT16` 変換 model が L2 norm `0.0000` のゼロベクトルを返したため、iOS / iPadOS / visionOS 組み込みでは `FLOAT32` から始めてください。

## App target への asset 追加

以下の生成済み assets を iOS / iPadOS / visionOS app target に追加します。

```text
E5SmallEmbedding.mlpackage
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

Xcode は `E5SmallEmbedding.mlpackage` を app bundle 内の `E5SmallEmbedding.mlmodelc` に compile する場合があります。また、resource の追加方法によっては tokenizer JSON files が `Tokenizer/` 配下ではなく app bundle root に flatten される場合があります。

`CoreMLTextEmbeddingAssets.appBundle()` は以下の layout を探します。

```text
E5SmallEmbedding.mlmodelc
E5SmallEmbedding.mlpackage
Tokenizer/tokenizer.json
Tokenizer/tokenizer_config.json
Tokenizer/special_tokens_map.json
tokenizer.json
tokenizer_config.json
special_tokens_map.json
```

## Package の追加

SwiftPM の URL identity に合わせて product dependency を指定します。

```swift
.package(url: "https://github.com/ysake/e5-coreml-swift", branch: "main")
```

```swift
.product(name: "E5EmbeddingCore", package: "e5-coreml-swift")
```

## App bundle から読み込む

```swift
import E5EmbeddingCore
import Foundation

let assets = CoreMLTextEmbeddingAssets.appBundle(.main)
let embedder = try CoreMLTextEmbedder(assets: assets)

let status = embedder.assetStatus()
guard status.isReady else {
    throw NSError(
        domain: "E5Embedding",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: status.errorDescription ?? "Missing E5 assets"]
    )
}

let embedding = try await embedder.embed(
    "車内の収納を増やしたい",
    purpose: .query
)
```

`assetStatus()` は diagnostics や UI readiness 表示のための API です。asset が使える状態か、どの model/tokenizer path が選ばれたか、概算 model size、asset が見つからない場合の説明を返します。

## Runtime behavior

- Tokenization は `swift-transformers` と local tokenizer JSON files でローカル実行する。
- Core ML inference は bundle に同梱した model でローカル実行する。
- E5 prefix は Swift 側で `query:` または `passage:` を付与する。
- Padding は E5/XLM-R の `<pad>` token ID `1` を使う。
- Padding 位置は `attention_mask = 0` にする。
- Truncation 時は可能な限り終端 special token を保持する。
- Core ML output は `float16` / `float32` / `double` の `MLMultiArray` を `[Float]` として読み出す。

## サイズと配布上の注意

BrainCopy PoC では、生成済み `E5SmallEmbedding.mlpackage` は約 448 MB、tokenizer assets は約 16 MB でした。これらを同梱すると app size が増えます。この package は現時点では iOS / iPadOS / visionOS app の bundle 同梱 assets を前提にしています。on-demand download、asset packs、remote model distribution は現在の scope 外です。
