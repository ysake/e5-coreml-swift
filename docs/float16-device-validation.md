# FLOAT16 Device Validation

[日本語版](float16-device-validation.ja.md)

Use this checklist to decide whether `FLOAT16` converted assets are safe for iOS and visionOS devices. Simulator results are useful comparison data, but they should not be treated as device results.

## Prepare Assets

Generate a `FLOAT32` baseline:

```bash
python scripts/convert_e5_small_to_coreml.py \
  --compute-precision FLOAT32 \
  --validate
```

Generate a `FLOAT16` candidate by replacing the local ignored assets:

```bash
python scripts/convert_e5_small_to_coreml.py \
  --compute-precision FLOAT16 \
  --validate
```

`Examples/E5iOSSmokeApp/` reads the generated assets from:

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

After switching precision, clean the Xcode build folder before running on a device so the app bundle contains the intended model.

## Run On Device

Open:

```bash
open Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj
```

Select a physical iOS or visionOS device, then run `E5iOSSmokeApp`.

The app reports:

- model readiness and model size
- embedding dimension
- L2 norm
- finite / all-zero checks
- query, related-passage, and unrelated-passage inference time
- related and unrelated similarity scores
- similarity margin

Use the same input texts for every precision and device run.

## Record Matrix

| Platform | Device / OS | Precision | Model size | Dimension | L2 norm | Finite | All zero | Related sim | Unrelated sim | Margin | Inference time | Memory notes | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iOS device |  | FLOAT32 |  |  |  |  |  |  |  |  |  |  |  |
| iOS device |  | FLOAT16 |  |  |  |  |  |  |  |  |  |  |  |
| visionOS device |  | FLOAT32 |  |  |  |  |  |  |  |  |  |  |  |
| visionOS device |  | FLOAT16 |  |  |  |  |  |  |  |  |  |  |  |
| Simulator / macOS comparison |  | FLOAT32 |  |  |  |  |  |  |  |  |  |  |  |
| Simulator / macOS comparison |  | FLOAT16 |  |  |  |  |  |  |  |  |  |  |  |

For memory notes, use Xcode's memory gauge or Instruments. The smoke app does not treat memory as a pass/fail signal by itself.

## Pass Criteria

Treat a precision/device pair as usable only when:

- embedding dimension is `384`
- L2 norm is close to `1.0`
- all values are finite
- the vector is not all zero
- related similarity is greater than unrelated similarity
- inference time and memory are acceptable for the target app

If `FLOAT16` passes on devices but fails only on Simulator, keep `FLOAT32` as the default and narrow the docs warning to Simulator behavior. If `FLOAT16` fails on a physical device, keep the stronger `FLOAT32` recommendation for that platform.
