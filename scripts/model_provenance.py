"""Build deterministic provenance metadata for generated E5 assets."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path, PurePosixPath
from typing import Any
from urllib.parse import quote


SCHEMA_VERSION = 1
DEFAULT_MODEL_ID = "intfloat/multilingual-e5-small"
DEFAULT_MODEL_REVISION = "614241f622f53c4eeff9890bdc4f31cfecc418b3"
DEFAULT_MODEL_LICENSE_ID = "MIT"
CORE_ML_METADATA_PREFIX = "com.github.ysake.e5-coreml-swift"
_COMMIT_SHA_PATTERN = re.compile(r"^[0-9a-fA-F]{40}$")


def normalize_revision(revision: str) -> str:
    """Require a full commit SHA so a conversion never follows a moving ref."""
    normalized = revision.strip().lower()
    if not _COMMIT_SHA_PATTERN.fullmatch(normalized):
        raise ValueError("--revision must be a full 40-character commit SHA")
    return normalized


def resolve_revision(model_id: str, revision: str | None) -> str:
    """Use the pinned default only for the model it belongs to."""
    if revision is not None and revision.strip():
        return normalize_revision(revision)
    if model_id == DEFAULT_MODEL_ID:
        return DEFAULT_MODEL_REVISION
    raise ValueError("--revision is required when --model-id is overridden")


def resolve_license_id(model_id: str, license_id: str | None) -> str:
    """Return an explicit license ID, with a safe default only for the known model."""
    if license_id is not None and license_id.strip():
        return license_id.strip()
    if model_id == DEFAULT_MODEL_ID:
        return DEFAULT_MODEL_LICENSE_ID
    raise ValueError("--license-id is required when --model-id is overridden")


def ensure_provenance_output_is_separate(
    provenance_output: Path,
    model_output: Path,
    tokenizer_output: Path,
) -> None:
    """Prevent the manifest from invalidating a hash by describing itself."""
    provenance = provenance_output.resolve(strict=False)
    for artifact_path in (model_output, tokenizer_output):
        artifact = artifact_path.resolve(strict=False)
        if provenance == artifact or provenance.is_relative_to(artifact):
            raise ValueError(
                "--provenance-output must be outside the model and tokenizer outputs"
            )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _directory_files(path: Path) -> list[Path]:
    files = sorted(
        (candidate for candidate in path.rglob("*") if candidate.is_file()),
        key=lambda candidate: candidate.relative_to(path).as_posix(),
    )
    if not files:
        raise ValueError(f"artifact directory is empty: {path}")
    return files


def sha256_directory(path: Path) -> tuple[str, int]:
    """Hash sorted relative paths and file digests using sha256-tree-v1."""
    digest = hashlib.sha256()
    files = _directory_files(path)
    for file_path in files:
        relative_path = file_path.relative_to(path).as_posix().encode("utf-8")
        file_digest = bytes.fromhex(sha256_file(file_path))
        digest.update(len(relative_path).to_bytes(8, byteorder="big"))
        digest.update(relative_path)
        digest.update(file_digest)
    return digest.hexdigest(), len(files)


def _artifact_record(path: Path, display_path: str) -> dict[str, Any]:
    if path.is_dir():
        digest, file_count = sha256_directory(path)
        return {
            "path": display_path,
            "kind": "directory",
            "hash_algorithm": "sha256-tree-v1",
            "sha256": digest,
            "file_count": file_count,
        }
    if path.is_file():
        return {
            "path": display_path,
            "kind": "file",
            "hash_algorithm": "sha256",
            "sha256": sha256_file(path),
        }
    raise FileNotFoundError(f"artifact does not exist: {path}")


def _tokenizer_artifacts(tokenizer_output: Path) -> list[dict[str, Any]]:
    if not tokenizer_output.is_dir():
        raise FileNotFoundError(
            f"tokenizer output directory does not exist: {tokenizer_output}"
        )
    artifacts: list[dict[str, Any]] = []
    for file_path in _directory_files(tokenizer_output):
        relative_path = PurePosixPath(
            tokenizer_output.name,
            file_path.relative_to(tokenizer_output).as_posix(),
        ).as_posix()
        artifacts.append(_artifact_record(file_path, relative_path))
    return artifacts


def source_url(model_id: str, revision: str) -> str:
    encoded_model_id = quote(model_id, safe="/")
    encoded_revision = quote(revision, safe="")
    return f"https://huggingface.co/{encoded_model_id}/tree/{encoded_revision}"


def core_ml_metadata(
    *,
    model_id: str,
    revision: str,
    license_id: str,
    max_sequence_length: int,
    compute_precision: str,
) -> dict[str, str]:
    return {
        f"{CORE_ML_METADATA_PREFIX}.provenance_schema_version": str(SCHEMA_VERSION),
        f"{CORE_ML_METADATA_PREFIX}.source_model_id": model_id,
        f"{CORE_ML_METADATA_PREFIX}.source_model_revision": revision,
        f"{CORE_ML_METADATA_PREFIX}.source_model_license": license_id,
        f"{CORE_ML_METADATA_PREFIX}.max_sequence_length": str(max_sequence_length),
        f"{CORE_ML_METADATA_PREFIX}.compute_precision": compute_precision,
    }


def build_provenance(
    *,
    model_id: str,
    requested_revision: str,
    resolved_revision: str,
    license_id: str,
    max_sequence_length: int,
    compute_precision: str,
    output_feature_name: str,
    embedding_dimension: int,
    tool_versions: dict[str, str],
    model_output: Path,
    tokenizer_output: Path,
) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "source": {
            "model_id": model_id,
            "requested_revision": requested_revision,
            "resolved_revision": resolved_revision,
            "url": source_url(model_id, resolved_revision),
            "license_id": license_id,
        },
        "conversion": {
            "max_sequence_length": max_sequence_length,
            "compute_precision": compute_precision,
            "output_feature_name": output_feature_name,
            "embedding_dimension": embedding_dimension,
            "tool_versions": dict(sorted(tool_versions.items())),
        },
        "artifacts": {
            "core_ml_model": _artifact_record(model_output, model_output.name),
            "tokenizer_files": _tokenizer_artifacts(tokenizer_output),
        },
    }


def write_provenance(path: Path, provenance: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(provenance, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
