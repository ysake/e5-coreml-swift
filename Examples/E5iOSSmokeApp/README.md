# E5 iOS Smoke App

Minimal iOS app target for checking that `E5EmbeddingCore` can be consumed from an iOS app and tested on iOS Simulator.

The app intentionally runs the deterministic embedder by default, so it can be built and tested without committing generated Core ML model or tokenizer assets. The bundled asset section still calls `CoreMLTextEmbeddingAssets.appBundle().status()` so app-bundle asset lookup can be inspected when assets are added later.

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

The test target verifies deterministic embedding output on iOS Simulator and checks that app-bundle asset status can be evaluated without crashing.
