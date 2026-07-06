# E5 iOS Smoke App

Minimal iOS app target for checking that `E5EmbeddingCore` can be consumed from an iOS app, bundled with generated local assets, and tested on iOS Simulator.

The app expects generated assets at the repository root:

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

The Xcode target fails the build if those assets are missing, then bundles them through the Resources build phase. The app lets you edit the smoke text and shows both a deterministic smoke result and a Core ML smoke result.

## Run

Open the project in Xcode:

```bash
open Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj
```

Or build from the command line:

```bash
xcodebuild \
  -project Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj \
  -scheme E5iOSSmokeApp \
  -destination 'generic/platform=iOS Simulator' \
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

The test target verifies deterministic embedding output, app-bundle asset readiness, and asset-backed Core ML inference on iOS Simulator.
