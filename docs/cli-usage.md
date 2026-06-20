# CLI Usage

This document describes the command-line tools provided by this package.

## Prerequisites

Generate the local Core ML model and tokenizer assets before using the default Core ML backend.

```bash
python3.11 -m venv .venv
. .venv/bin/activate
pip install -r requirements-convert.txt
python scripts/convert_e5_small_to_coreml.py --validate
```

Expected local assets:

```text
Models/E5SmallEmbedding.mlpackage
Tokenizer/
```

The generated assets are ignored by git.

## `e5-embed`

Generates one embedding vector and prints JSON.

```bash
swift run e5-embed [options] <text>
```

### Options

| Option | Values | Default | Description |
| --- | --- | --- | --- |
| `--purpose` | `query`, `passage` | `query` | Applies the E5 input prefix. Use `query` for search queries and `passage` for documents or candidate text. |
| `--backend` | `coreml`, `deterministic` | `coreml` | Selects the embedding backend. `deterministic` is only for development smoke tests. |
| `--model` | path | `Models/E5SmallEmbedding.mlpackage` or `.mlmodelc` | Core ML model path. |
| `--tokenizer` | path | `Tokenizer` | Directory containing tokenizer assets. |
| `--max-length` | positive integer | `128` | Token sequence length used for padding and truncation. It must match the converted Core ML model. |
| `--model-name` | string | `intfloat/multilingual-e5-small` | Overrides the `model` field in JSON output. |

### Query Embedding

```bash
swift run e5-embed "Find more storage space inside my car"
```

Equivalent:

```bash
swift run e5-embed --purpose query "Find more storage space inside my car"
```

### Passage Embedding

```bash
swift run e5-embed \
  --purpose passage \
  "Use seat-back organizers, cargo boxes, or roof storage to increase vehicle storage capacity."
```

### Custom Asset Paths

```bash
swift run e5-embed \
  --model Models/E5SmallEmbedding.mlpackage \
  --tokenizer Tokenizer \
  --max-length 128 \
  "Find more storage space inside my car"
```

### Development Smoke Test

Use this when model assets are not present. The vector is deterministic but not semantically meaningful.

```bash
swift run e5-embed --backend deterministic "Smoke test"
```

## `e5-embed-similarity`

Embeds a query and a passage, then prints their dot product as JSON. Because the converted E5 model returns L2-normalized vectors, the dot product is cosine similarity.

```bash
swift run e5-embed-similarity [options] --query <text> --passage <text>
```

### Options

| Option | Values | Default | Description |
| --- | --- | --- | --- |
| `--query` | text | required | Query text. The CLI embeds it with `purpose = query`. |
| `--passage` | text | required | Candidate text. The CLI embeds it with `purpose = passage`. |
| `--backend` | `coreml`, `deterministic` | `coreml` | Selects the embedding backend. |
| `--model` | path | `Models/E5SmallEmbedding.mlpackage` or `.mlmodelc` | Core ML model path. |
| `--tokenizer` | path | `Tokenizer` | Directory containing tokenizer assets. |
| `--max-length` | positive integer | `128` | Token sequence length used for padding and truncation. |
| `--model-name` | string | `intfloat/multilingual-e5-small` | Overrides the `model` field in JSON output. |

### Similarity Example

```bash
swift run e5-embed-similarity \
  --query "Find more storage space inside my car" \
  --passage "Cargo organizers and roof boxes can increase available storage in a vehicle."
```

### Compare Against an Unrelated Passage

```bash
swift run e5-embed-similarity \
  --query "Find more storage space inside my car" \
  --passage "Explain the interpretation of wave functions in quantum mechanics."
```

## Output Notes

`e5-embed` returns:

```json
{
  "dimension": 384,
  "embedding": [0.0123, -0.0456, "... 382 more values"],
  "model": "intfloat/multilingual-e5-small",
  "purpose": "query"
}
```

The `embedding` array contains exactly `dimension` values. The example is truncated for readability.

`e5-embed-similarity` returns:

```json
{
  "model": "intfloat/multilingual-e5-small",
  "query": "Find more storage space inside my car",
  "passage": "Cargo organizers and roof boxes can increase available storage in a vehicle.",
  "queryDimension": 384,
  "passageDimension": 384,
  "score": 0.851
}
```

Scores are relative. Compare multiple passages for the same query instead of treating one absolute threshold as universal.
