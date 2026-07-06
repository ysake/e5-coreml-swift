# E5 iOS Smoke App

`E5EmbeddingCore` を iOS アプリ target から利用し、iOS Simulator 上で test できることを確認するための最小 App です。

この App は、生成済み Core ML model / tokenizer assets を commit しなくても build と test ができるように、標準では deterministic embedder を実行します。Bundled Assets セクションでは `CoreMLTextEmbeddingAssets.appBundle().status()` も呼ぶため、後から assets を同梱した場合の app bundle lookup 状態も確認できます。

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

Test target は、iOS Simulator 上で deterministic embedding の出力を検証し、app bundle asset status を評価しても crash しないことを確認します。
