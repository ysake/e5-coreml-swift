# CLI の使い方

このドキュメントでは、この package が提供するコマンドラインツールの使い方を説明します。

## 前提

デフォルトの Core ML backend を使う前に、ローカルの Core ML モデルと tokenizer assets を生成します。

```bash
python3.11 -m venv .venv
. .venv/bin/activate
pip install -r requirements-convert.txt
python scripts/convert_e5_small_to_coreml.py --validate
```

生成される assets:

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

生成された assets は git 管理対象外です。

## `e5-embed`

1つの embedding vector を生成し、JSON を出力します。

```bash
swift run e5-embed [options] <text>
```

### オプション

| Option | Values | Default | Description |
| --- | --- | --- | --- |
| `--purpose` | `query`, `passage` | `query` | E5 の入力 prefix を指定します。検索クエリは `query`、文書や候補テキストは `passage` を使います。 |
| `--backend` | `coreml`, `deterministic` | `coreml` | embedding backend を選びます。`deterministic` は開発用 smoke test 専用です。 |
| `--model` | path | `Models/E5SmallEmbedding.mlpackage` または `.mlmodelc` | Core ML model の path です。 |
| `--tokenizer` | path | `Tokenizer` | tokenizer assets のディレクトリです。 |
| `--max-length` | positive integer | `128` | padding / truncation に使う token sequence length です。変換済み Core ML model と一致させる必要があります。 |
| `--model-name` | string | `intfloat/multilingual-e5-small` | JSON output の `model` field を上書きします。 |

### Query Embedding

```bash
swift run e5-embed "車内の収納を増やしたい"
```

以下と同じ意味です。

```bash
swift run e5-embed --purpose query "車内の収納を増やしたい"
```

### Passage Embedding

```bash
swift run e5-embed \
  --purpose passage \
  "セレナの荷室容量を増やすには、車内収納やルーフボックスを検討する。"
```

### Asset Path を明示する

```bash
swift run e5-embed \
  --model Models/E5SmallEmbedding.mlpackage \
  --tokenizer Tokenizer \
  --max-length 128 \
  "テスト"
```

### 開発用 Smoke Test

model assets がない状態で CLI の JSON 出力だけ確認したい場合に使います。この vector は deterministic ですが、意味検索用の embedding ではありません。

```bash
swift run e5-embed --backend deterministic "テスト"
```

## `e5-embed-similarity`

query と passage を embedding し、dot product を JSON で出力します。変換済み E5 model は L2-normalized vector を返すため、dot product は cosine similarity として扱えます。

```bash
swift run e5-embed-similarity [options] --query <text> --passage <text>
```

### オプション

| Option | Values | Default | Description |
| --- | --- | --- | --- |
| `--query` | text | required | query text です。CLI は `purpose = query` で embedding します。 |
| `--passage` | text | required | 候補テキストです。CLI は `purpose = passage` で embedding します。 |
| `--backend` | `coreml`, `deterministic` | `coreml` | embedding backend を選びます。 |
| `--model` | path | `Models/E5SmallEmbedding.mlpackage` または `.mlmodelc` | Core ML model の path です。 |
| `--tokenizer` | path | `Tokenizer` | tokenizer assets のディレクトリです。 |
| `--max-length` | positive integer | `128` | padding / truncation に使う token sequence length です。 |
| `--model-name` | string | `intfloat/multilingual-e5-small` | JSON output の `model` field を上書きします。 |

### 類似度の例

```bash
swift run e5-embed-similarity \
  --query "車内の収納を増やしたい" \
  --passage "セレナの荷物積載量を増やす方法"
```

### 無関係な passage と比較する

```bash
swift run e5-embed-similarity \
  --query "車内の収納を増やしたい" \
  --passage "量子力学における波動関数の解釈を説明する"
```

## 出力メモ

`e5-embed` は以下を返します。

```json
{
  "dimension": 384,
  "embedding": [0.0123, -0.0456],
  "model": "intfloat/multilingual-e5-small",
  "purpose": "query"
}
```

`e5-embed-similarity` は以下を返します。

```json
{
  "model": "intfloat/multilingual-e5-small",
  "query": "車内の収納を増やしたい",
  "passage": "セレナの荷物積載量を増やす方法",
  "queryDimension": 384,
  "passageDimension": 384,
  "score": 0.851
}
```

score は相対的に比較する値です。単一の絶対しきい値を固定するより、同じ query に対する複数 passage の順位付けとして扱う方が堅実です。
