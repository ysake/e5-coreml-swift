from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS_DIR))

from model_provenance import (  # noqa: E402
    CORE_ML_METADATA_PREFIX,
    DEFAULT_MODEL_ID,
    DEFAULT_MODEL_LICENSE_ID,
    build_provenance,
    core_ml_metadata,
    ensure_provenance_output_is_separate,
    normalize_revision,
    resolve_license_id,
    resolve_revision,
    sha256_directory,
    sha256_file,
    write_provenance,
)


REVISION = "a" * 40


class ModelProvenanceTests(unittest.TestCase):
    def test_revision_requires_full_commit_sha(self) -> None:
        self.assertEqual(normalize_revision("A" * 40), REVISION)
        with self.assertRaisesRegex(ValueError, "40-character commit SHA"):
            normalize_revision("main")

    def test_custom_model_requires_explicit_revision(self) -> None:
        self.assertEqual(
            resolve_revision(DEFAULT_MODEL_ID, None),
            "614241f622f53c4eeff9890bdc4f31cfecc418b3",
        )
        self.assertEqual(resolve_revision("owner/model", REVISION), REVISION)
        with self.assertRaisesRegex(ValueError, "--revision is required"):
            resolve_revision("owner/model", None)

    def test_custom_model_requires_explicit_license(self) -> None:
        self.assertEqual(
            resolve_license_id(DEFAULT_MODEL_ID, None),
            DEFAULT_MODEL_LICENSE_ID,
        )
        self.assertEqual(resolve_license_id("owner/model", "Apache-2.0"), "Apache-2.0")
        with self.assertRaisesRegex(ValueError, "--license-id is required"):
            resolve_license_id("owner/model", None)

    def test_provenance_output_must_not_be_inside_hashed_assets(self) -> None:
        root = Path("/tmp/provenance-test")
        ensure_provenance_output_is_separate(
            root / "E5ModelProvenance.json",
            root / "Models" / "E5SmallEmbedding.mlpackage",
            root / "Tokenizer",
        )
        with self.assertRaisesRegex(ValueError, "must be outside"):
            ensure_provenance_output_is_separate(
                root / "Tokenizer" / "E5ModelProvenance.json",
                root / "Models" / "E5SmallEmbedding.mlpackage",
                root / "Tokenizer",
            )

    def test_file_and_directory_hashes_are_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            first = root / "a.txt"
            second = root / "nested" / "b.txt"
            second.parent.mkdir()
            first.write_bytes(b"abc")
            second.write_bytes(b"def")

            self.assertEqual(
                sha256_file(first),
                hashlib.sha256(b"abc").hexdigest(),
            )
            initial_digest, file_count = sha256_directory(root)
            repeated_digest, _ = sha256_directory(root)
            self.assertEqual(initial_digest, repeated_digest)
            self.assertEqual(file_count, 2)

            second.rename(root / "nested" / "renamed.txt")
            renamed_digest, _ = sha256_directory(root)
            self.assertNotEqual(initial_digest, renamed_digest)

    def test_builds_and_writes_complete_provenance(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            model_output = root / "Models" / "E5SmallEmbedding.mlpackage"
            tokenizer_output = root / "Tokenizer"
            model_output.mkdir(parents=True)
            tokenizer_output.mkdir()
            (model_output / "Manifest.json").write_text("{}", encoding="utf-8")
            (model_output / "Data.bin").write_bytes(b"model")
            (tokenizer_output / "tokenizer_config.json").write_text(
                "{}", encoding="utf-8"
            )
            (tokenizer_output / "tokenizer.json").write_text("{}", encoding="utf-8")

            provenance = build_provenance(
                model_id=DEFAULT_MODEL_ID,
                requested_revision=REVISION,
                resolved_revision=REVISION,
                license_id="MIT",
                max_sequence_length=128,
                compute_precision="FLOAT32",
                output_feature_name="embedding",
                embedding_dimension=384,
                tool_versions={"torch": "2.7.0", "python": "3.11.0"},
                model_output=model_output,
                tokenizer_output=tokenizer_output,
            )

            self.assertEqual(provenance["schema_version"], 1)
            self.assertEqual(provenance["source"]["resolved_revision"], REVISION)
            self.assertEqual(
                provenance["conversion"]["tool_versions"],
                {"python": "3.11.0", "torch": "2.7.0"},
            )
            self.assertEqual(
                provenance["artifacts"]["core_ml_model"]["hash_algorithm"],
                "sha256-tree-v1",
            )
            self.assertEqual(
                [entry["path"] for entry in provenance["artifacts"]["tokenizer_files"]],
                ["Tokenizer/tokenizer.json", "Tokenizer/tokenizer_config.json"],
            )

            output = root / "E5ModelProvenance.json"
            write_provenance(output, provenance)
            self.assertEqual(json.loads(output.read_text(encoding="utf-8")), provenance)
            self.assertTrue(output.read_bytes().endswith(b"\n"))

    def test_core_ml_metadata_uses_stable_namespaced_keys(self) -> None:
        metadata = core_ml_metadata(
            model_id=DEFAULT_MODEL_ID,
            revision=REVISION,
            license_id="MIT",
            max_sequence_length=128,
            compute_precision="FLOAT32",
        )
        self.assertEqual(
            metadata[f"{CORE_ML_METADATA_PREFIX}.source_model_revision"],
            REVISION,
        )
        self.assertEqual(
            metadata[f"{CORE_ML_METADATA_PREFIX}.max_sequence_length"],
            "128",
        )


if __name__ == "__main__":
    unittest.main()
