# E5 iOS Smoke App

`E5EmbeddingCore` を iOS アプリ target から利用し、生成済み local assets を同梱して、iOS Simulator 上で test できることを確認するための最小 App です。

この App は、repository root に以下の生成済み assets があることを前提にします。

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

Xcode target は assets がない場合に build error にし、存在する場合は Resources build phase で app bundle に同梱します。App では確認用文字列を編集でき、deterministic smoke result と Core ML smoke result の両方を表示します。

## 実行

Xcode で project を開きます。

```bash
open Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj
```

CLI から build する場合:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=iOS Simulator' \
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

Test target は、iOS Simulator 上で deterministic embedding の出力、app bundle asset readiness、asset-backed Core ML inference を検証します。
