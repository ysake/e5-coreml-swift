# iOS / iPadOS / visionOS App Integration

This package does not download the E5 model at app runtime. iOS, iPadOS, and visionOS apps must bundle the converted Core ML model and tokenizer assets with the app.

## Asset lifecycle

The expected flow is:

1. During development or release preparation, run the conversion script on a Mac.
2. The script downloads `intfloat/multilingual-e5-small` through Python/Hugging Face tooling, converts it to Core ML, and writes tokenizer files.
3. Add the generated model and tokenizer files to the app target as resources.
4. At app runtime, `E5EmbeddingCore` loads assets from the app bundle and performs local tokenization and Core ML inference.

`E5EmbeddingCore` itself does not contact Hugging Face, download model weights, or create model files at runtime.

## Supported app platforms

`E5EmbeddingCore` declares iOS 17+ and visionOS 1+ support. SwiftPM uses the `.iOS` platform declaration for both iPhone and iPad app targets, so iPadOS consumption is covered by the iOS platform support.

This package provides the reusable embedding library, macOS validation CLIs, and a minimal iOS smoke app under `Examples/E5iOSSmokeApp/`. It does not provide production iOS, iPadOS, or visionOS app UI targets.

## Minimal iOS smoke app

`Examples/E5iOSSmokeApp/` contains a small SwiftUI app target and an XCTest target. The app uses `E5EmbeddingCore` through the local Swift package dependency and expects generated assets at `Models/E5SmallEmbedding.mlpackage` and `Tokenizer/`. Its Xcode target fails the build if those assets are missing, then copies them into the app bundle.

Build the app:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run the iOS Simulator tests:

Replace the simulator name with any installed iOS Simulator if needed.

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

The simulator tests verify deterministic embedding output, app-bundle asset readiness, and asset-backed Core ML inference.

When running on Simulator, `CoreMLTextEmbedder` loads the Core ML model with CPU-only compute units to avoid simulator GPU/MPSGraph backend issues that can produce zero vectors.

## Generate assets

From this repository:

```bash
python3.11 -m venv .venv
. .venv/bin/activate
pip install -r requirements-convert.txt
python scripts/convert_e5_small_to_coreml.py --validate
```

The script writes:

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

The conversion script defaults to `FLOAT32`. Use that default for iOS, iPadOS, and visionOS integration; BrainCopy visionOS Simulator testing saw `FLOAT16` converted models return zero vectors with L2 norm `0.0000`.

## Add assets to the app target

Add these generated assets to the iOS, iPadOS, or visionOS app target:

```text
E5SmallEmbedding.mlpackage
Tokenizer/
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
```

Xcode may compile `E5SmallEmbedding.mlpackage` into `E5SmallEmbedding.mlmodelc` in the app bundle. Depending on how resources are added, tokenizer JSON files may stay under `Tokenizer/` or be flattened into the app bundle resource root.

`CoreMLTextEmbeddingAssets.appBundle()` checks these layouts:

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

## Add the package

Use the repository URL identity in the product dependency:

```swift
.package(url: "https://github.com/ysake/e5-coreml-swift", branch: "main")
```

```swift
.product(name: "E5EmbeddingCore", package: "e5-coreml-swift")
```

## Load from the app bundle

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

`assetStatus()` is intended for diagnostics and UI readiness reporting. It reports whether assets are ready, which model/tokenizer paths were selected, an approximate model size, and a missing-asset error message when resolution fails.

## Runtime behavior

- Tokenization runs locally through `swift-transformers` and local tokenizer JSON files.
- Core ML inference runs locally through the bundled model.
- E5 prefixes are applied in Swift with `query:` or `passage:`.
- Padding uses the E5/XLM-R `<pad>` token ID `1`.
- Padding positions use `attention_mask = 0`.
- Truncation preserves the terminal special token when possible.
- Core ML output extraction accepts `float16`, `float32`, and `double` `MLMultiArray` values and returns `[Float]`.

## Size and distribution notes

The generated `E5SmallEmbedding.mlpackage` was about 448 MB in the BrainCopy PoC, and tokenizer assets were about 16 MB. Bundling those assets increases app size. This package currently assumes bundled assets for iOS, iPadOS, and visionOS apps; on-demand downloads, asset packs, and remote model distribution are outside the current scope.
