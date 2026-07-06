# E5 iOS / visionOS Smoke App

`E5EmbeddingCore` を Apple platform app target から利用し、生成済み local assets を同梱できることを確認するための最小 App です。

この App は、repository root に以下の生成済み assets があることを前提にします。

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

Xcode target は assets がない場合に build error にし、存在する場合は Resources build phase で app bundle に同梱します。App では query と passage の入力文字列を編集でき、deterministic、Core ML、similarity validation の結果を表示します。

## 実行

Xcode で project を開きます。

```bash
open Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj
```

CLI から iOS Simulator 向けに build する場合:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

visionOS Simulator 向けに build する場合:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=visionOS Simulator' \
  build
```

iOS Simulator 上で smoke test を実行する場合:

必要に応じて、Simulator 名は手元に install されている iOS Simulator に置き換えてください。

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

Test target は、iOS Simulator 上で deterministic embedding の出力、app bundle asset readiness、asset-backed Core ML inference、related/unrelated similarity validation を検証します。実機検証では、同じ app target を iOS または visionOS で利用できます。

実機での FLOAT16/FLOAT32 検証は [`../../docs/float16-device-validation.ja.md`](../../docs/float16-device-validation.ja.md) を参照してください。
