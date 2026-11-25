#!/usr/bin/env python3
"""Import approved AI/generated media into Godot as local, versionable resources.

This tool never calls an AI provider, never downloads files, and never reads credentials.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "generated"
MANIFEST = ASSET_ROOT / "manifest.json"
ALLOWED = {
    "texture": {".png", ".jpg", ".jpeg", ".webp"},
    "ui": {".png", ".jpg", ".jpeg", ".webp"},
    "audio": {".wav", ".ogg"},
    "model": {".glb"},
    "video": {".ogv"},
}
MAX_BYTES = {"texture": 30, "ui": 15, "audio": 50, "model": 100, "video": 150}


class AssetPipelineError(Exception):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_file(source: Path, kind: str) -> dict:
    source = source.expanduser().resolve(strict=True)
    if not source.is_file():
        raise AssetPipelineError("A origem precisa ser um arquivo.")
    if kind not in ALLOWED:
        raise AssetPipelineError(f"Tipo inválido: {kind}")
    suffix = source.suffix.lower()
    if suffix not in ALLOWED[kind]:
        raise AssetPipelineError(f"Extensão {suffix or '(sem extensão)'} não aceita para {kind}.")
    size = source.stat().st_size
    if size <= 0 or size > MAX_BYTES[kind] * 1024 * 1024:
        raise AssetPipelineError(f"Tamanho inválido para {kind}: {size} bytes.")

    with source.open("rb") as stream:
        head = stream.read(32)
    valid = False
    if suffix == ".png":
        valid = head.startswith(b"\\x89PNG\\r\\n\\x1a\\n")
    elif suffix in {".jpg", ".jpeg"}:
        valid = head.startswith(b"\\xff\\xd8\\xff")
    elif suffix == ".webp":
        valid = len(head) >= 12 and head[:4] == b"RIFF" and head[8:12] == b"WEBP"
    elif suffix == ".wav":
        valid = len(head) >= 12 and head[:4] == b"RIFF" and head[8:12] == b"WAVE"
    elif suffix == ".ogg":
        valid = head.startswith(b"OggS")
    elif suffix == ".glb":
        valid = len(head) >= 12 and head[:4] == b"glTF" and struct.unpack("<I", head[8:12])[0] == size
    elif suffix == ".ogv":
        valid = head.startswith(b"OggS")
    if not valid:
        raise AssetPipelineError(f"Assinatura do arquivo não corresponde a {suffix}.")
    return {"source": str(source), "extension": suffix, "size_bytes": size, "sha256": sha256_file(source)}


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.strip().lower()).strip("-")
    if not slug or len(slug) > 64:
        raise AssetPipelineError("Nome inválido: use 1 a 64 caracteres alfanuméricos.")
    return slug


def import_asset(source: Path, kind: str, name: str, provider: str, model: str, prompt: str, license_name: str) -> dict:
    details = validate_file(source, kind)
    slug = slugify(name)
    for value, label in ((provider, "provider"), (model, "model"), (prompt, "prompt"), (license_name, "license")):
        if not value.strip():
            raise AssetPipelineError(f"Campo obrigatório ausente: {label}")
    target_dir = ASSET_ROOT / kind
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{slug}{details['extension']}"
    sidecar = target.with_suffix(target.suffix + ".asset.json")
    if target.exists() or sidecar.exists():
        raise AssetPipelineError(f"Já existe um asset com esse nome: {target.relative_to(ROOT)}")

    entry = {
        "id": f"{kind}/{slug}",
        "kind": kind,
        "path": target.relative_to(ROOT).as_posix(),
        "sha256": details["sha256"],
        "size_bytes": details["size_bytes"],
        "provider": provider.strip(),
        "model": model.strip(),
        "prompt": prompt.strip(),
        "license": license_name.strip(),
        "source_filename": Path(details["source"]).name,
        "approved": True,
        "approved_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    try:
        shutil.copy2(details["source"], target)
        sidecar.write_text(json.dumps(entry, ensure_ascii=False, indent=2) + "\\n", encoding="utf-8")
        manifest_data = {"schema_version": 1, "assets": []}
        if MANIFEST.exists():
            manifest_data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        if any(item.get("id") == entry["id"] for item in manifest_data.get("assets", [])):
            raise AssetPipelineError(f"ID já registrado no manifesto: {entry['id']}")
        manifest_data.setdefault("assets", []).append(entry)
        MANIFEST.parent.mkdir(parents=True, exist_ok=True)
        MANIFEST.write_text(json.dumps(manifest_data, ensure_ascii=False, indent=2) + "\\n", encoding="utf-8")
    except Exception:
        target.unlink(missing_ok=True)
        sidecar.unlink(missing_ok=True)
        raise
    return entry


def check_manifest() -> list[str]:
    if not MANIFEST.exists():
        return ["Manifesto ainda não existe; nenhum asset gerado foi importado."]
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    errors = []
    for item in data.get("assets", []):
        path = (ROOT / item["path"]).resolve()
        if ROOT not in path.parents:
            errors.append(f"Caminho fora do projeto: {item.get('path')}")
            continue
        if not path.is_file():
            errors.append(f"Arquivo ausente: {item.get('path')}")
        elif sha256_file(path) != item.get("sha256"):
            errors.append(f"Hash divergente: {item.get('path')}")
        if not item.get("approved") or not item.get("license"):
            errors.append(f"Asset sem aprovação/licença: {item.get('id')}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    validate = sub.add_parser("validate", help="Valida um arquivo sem copiá-lo.")
    validate.add_argument("--source", type=Path, required=True)
    validate.add_argument("--kind", choices=sorted(ALLOWED), required=True)
    add = sub.add_parser("import", help="Importa um arquivo já revisado e aprovado.")
    add.add_argument("--source", type=Path, required=True)
    add.add_argument("--kind", choices=sorted(ALLOWED), required=True)
    add.add_argument("--name", required=True)
    add.add_argument("--provider", required=True)
    add.add_argument("--model", required=True)
    add.add_argument("--prompt", required=True)
    add.add_argument("--license", dest="license_name", required=True)
    add.add_argument("--approved", action="store_true", help="Confirma revisão humana e aprovação do asset.")
    sub.add_parser("check-manifest", help="Confere arquivos e hashes do manifesto local.")
    args = parser.parse_args()
    try:
        if args.command == "validate":
            print(json.dumps(validate_file(args.source, args.kind), ensure_ascii=False, indent=2))
        elif args.command == "import":
            if not args.approved:
                raise AssetPipelineError("Importação bloqueada: revise o arquivo e informe --approved.")
            print(json.dumps(import_asset(args.source, args.kind, args.name, args.provider, args.model, args.prompt, args.license_name), ensure_ascii=False, indent=2))
            print("Godot: execute Import/Reload ou abra o projeto para importar o recurso.")
        else:
            errors = check_manifest()
            for error in errors:
                print(error)
            if any(not error.startswith("Manifesto ainda não existe") for error in errors):
                return 1
            print("Manifesto verificado.")
        return 0
    except (AssetPipelineError, OSError, json.JSONDecodeError, KeyError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
