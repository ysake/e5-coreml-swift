# FLOAT16 実機検証

[English](float16-device-validation.md)

`FLOAT16` 変換 assets を iOS / visionOS 実機で使ってよいか判断するためのチェックリストです。Simulator の結果は比較データとしては有用ですが、実機結果としては扱いません。

## Assets を準備する

`FLOAT32` baseline を生成します。

```bash
python scripts/convert_e5_small_to_coreml.py \
  --compute-precision FLOAT32 \
  --validate
```

`FLOAT16` candidate は、local の ignored assets を置き換えて生成します。

```bash
python scripts/convert_e5_small_to_coreml.py \
  --compute-precision FLOAT16 \
  --validate
```

`Examples/E5iOSSmokeApp/` は以下の生成済み assets を参照します。

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

precision を切り替えた後は、意図した model が app bundle に入るように Xcode の build folder を clean してから実機で実行します。

## 実機で実行する

以下を開きます。

```bash
open Examples/E5iOSSmokeApp/E5iOSSmokeApp.xcodeproj
```

iOS または visionOS の物理デバイスを選択し、`E5iOSSmokeApp` を実行します。

App は以下を表示します。

- model readiness と model size
- embedding dimension
- L2 norm
- finite / all-zero checks
- query、related passage、unrelated passage の inference time
- related / unrelated similarity score
- similarity margin

precision と device を変えても、入力 text は同じものを使ってください。

## 比較表に記録する

| Platform | Device / OS | Precision | Model size | Dimension | L2 norm | Finite | All zero | Related sim | Unrelated sim | Margin | Inference time | Memory notes | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iOS device |  | FLOAT32 |  |  |  |  |  |  |  |  |  |  |  |
| iOS device |  | FLOAT16 |  |  |  |  |  |  |  |  |  |  |  |
| visionOS device |  | FLOAT32 |  |  |  |  |  |  |  |  |  |  |  |
| visionOS device |  | FLOAT16 |  |  |  |  |  |  |  |  |  |  |  |
| Simulator / macOS comparison |  | FLOAT32 |  |  |  |  |  |  |  |  |  |  |  |
| Simulator / macOS comparison |  | FLOAT16 |  |  |  |  |  |  |  |  |  |  |  |

Memory notes は Xcode の memory gauge または Instruments で記録します。Smoke app の表示だけでは memory を pass/fail 判定しません。

## 判定基準

precision / device の組み合わせは、以下を満たす場合だけ利用可能と判断します。

- embedding dimension が `384`
- L2 norm が `1.0` 付近
- 全値が finite
- all-zero vector ではない
- related similarity が unrelated similarity より高い
- inference time と memory が対象 app に対して許容範囲

`FLOAT16` が実機では通り、Simulator でだけ失敗する場合は、標準は `FLOAT32` のままにしつつ docs の警告を Simulator 限定の挙動へ狭めます。物理デバイスでも `FLOAT16` が失敗する場合は、その platform では `FLOAT32` 推奨を維持します。
