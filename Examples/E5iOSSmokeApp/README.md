# E5 iOS / visionOS Smoke App

Minimal iOS / visionOS app target for checking that `E5EmbeddingCore` can be consumed from an Apple platform app and bundled with generated local assets.

The app expects generated assets at the repository root:

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

The Xcode target fails the build if those assets are missing, then bundles them through the Resources build phase. The app lets you edit the query and passage texts, then shows deterministic, Core ML, and similarity validation results.

## Run

Open the project in Xcode:

```bash
open Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj
```

Or build for iOS Simulator from the command line:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Build for visionOS Simulator:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=visionOS Simulator' \
  build
```

Run the simulator smoke tests:

Replace the simulator name with any installed iOS Simulator if needed.

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

The test target verifies deterministic embedding output, app-bundle asset readiness, asset-backed Core ML inference, and related/unrelated similarity validation on iOS Simulator. Physical device validation can use the same app target on iOS or visionOS. After running the app, use **Copy Report** to paste the asset status, embedding checks, similarity values, and timings into the validation issue.

For physical-device FLOAT16/FLOAT32 validation, see [`../../docs/float16-device-validation.md`](../../docs/float16-device-validation.md).
