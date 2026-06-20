# エージェント向けプロンプト

あなたはこのリポジトリの実装担当エージェントです。

## 目的

SwiftPM CLIとして、ローカルCore MLモデルを使ってテキストembeddingを生成できるサンプルを実装してください。

## 最初に読むファイル

- `README.md`
- `docs/agent-handoff.ja.md`
- `docs/implementation-plan.ja.md`
- `docs/model-conversion-notes.ja.md`
- `AGENTS.ja.md`

## 最初の完了条件

- `swift build` が成功する
- `swift test` が成功する
- `swift run e5-embed "テスト"` がJSONを返す
- `query` / `passage` のprefix処理がある
- model/tokenizer assetが未配置でも、読みやすいエラーを返す

## 注意

最初からiOS / visionOSサンプルを作らず、まずCLIを完成させてください。
