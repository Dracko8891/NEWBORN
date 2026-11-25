import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import asset_pipeline as pipeline


class AssetPipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source = self.root / "sample.png"
        self.source.write_bytes(b"\x89PNG\r\n\x1a\n" + b"test-image")
        self.generated = self.root / "assets" / "generated"
        self.manifest = self.generated / "manifest.json"

    def tearDown(self):
        self.temp.cleanup()

    def test_validate_accepts_png_signature(self):
        result = pipeline.validate_file(self.source, "texture")
        self.assertEqual(result["extension"], ".png")
        self.assertGreater(result["size_bytes"], 0)

    def test_validate_rejects_mismatched_signature(self):
        self.source.write_bytes(b"not a png")
        with self.assertRaises(pipeline.AssetPipelineError):
            pipeline.validate_file(self.source, "texture")

    def test_import_records_provenance_and_hash(self):
        with patch.object(pipeline, "ROOT", self.root), patch.object(pipeline, "ASSET_ROOT", self.generated), patch.object(pipeline, "MANIFEST", self.manifest):
            entry = pipeline.import_asset(self.source, "texture", "Vanguard wall", "Gemini", "Nano Banana", "industrial wall texture", "generated; approved for project")
            self.assertTrue((self.root / entry["path"]).is_file())
            self.assertTrue((self.root / (entry["path"] + ".asset.json")).is_file())
            data = json.loads(self.manifest.read_text(encoding="utf-8"))
            self.assertEqual(data["assets"][0]["id"], "texture/vanguard-wall")
            self.assertEqual(pipeline.check_manifest(), [])

    def test_import_requires_valid_license_and_prompt(self):
        with self.assertRaises(pipeline.AssetPipelineError):
            pipeline.import_asset(self.source, "texture", "wall", "Gemini", "Nano Banana", "prompt", "")

    def test_manifest_detects_tampering(self):
        with patch.object(pipeline, "ROOT", self.root), patch.object(pipeline, "ASSET_ROOT", self.generated), patch.object(pipeline, "MANIFEST", self.manifest):
            entry = pipeline.import_asset(self.source, "texture", "wall", "Gemini", "Nano Banana", "prompt", "approved")
            (self.root / entry["path"]).write_bytes(b"changed")
            self.assertTrue(any("Hash divergente" in item for item in pipeline.check_manifest()))


if __name__ == "__main__":
    unittest.main()
