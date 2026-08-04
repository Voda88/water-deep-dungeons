#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime
from pathlib import Path


ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "generated"
DEFAULT_REFERENCE_IMAGE_DIR = Path(__file__).resolve().parent.parent / "assets" / "characters" / "heroes" / "fighter"
PREVIEW_API_VERSION = "2025-04-01-preview"


def load_env_file(env_path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not env_path.exists():
        return values
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("'").strip('"')
    return values


def resolve_env() -> dict[str, str]:
    file_values = load_env_file(ENV_PATH)
    resolved = dict(file_values)
    resolved.update({k: v for k, v in os.environ.items() if v})
    return resolved


def require_env(env: dict[str, str], *names: str) -> str:
    for name in names:
        value = env.get(name, "").strip()
        if value:
            return value
    expected = ", ".join(names)
    raise SystemExit(f"Missing required environment variable. Tried: {expected}")


def normalize_base_url(raw_base_url: str) -> str:
    return raw_base_url.strip().rstrip("/")


def build_request(
    base_url: str,
    deployment_name: str,
    api_key: str,
    prompt: str,
    size: str,
    quality: str,
    background: str,
) -> tuple[str, dict[str, str], dict]:
    normalized_base = normalize_base_url(base_url)
    body = {
        "prompt": prompt,
        "size": size,
        "quality": quality,
        "output_format": "png",
    }
    if background != "auto":
        body["background"] = background

    headers = {
        "Content-Type": "application/json",
        "api-key": api_key,
    }

    if "/openai/v1" in normalized_base:
        body["model"] = deployment_name
        return f"{normalized_base}/images/generations", headers, body

    if "/openai/deployments/" in normalized_base:
        root = normalized_base.split("/openai/deployments/", 1)[0]
    elif normalized_base.endswith("/openai"):
        root = normalized_base[: -len("/openai")]
    else:
        root = normalized_base

    encoded_deployment = urllib.parse.quote(deployment_name, safe="")
    url = f"{root}/openai/deployments/{encoded_deployment}/images/generations?api-version={PREVIEW_API_VERSION}"
    return url, headers, body


def resolve_reference_image_path(raw_path: str) -> Path:
    candidate = Path(raw_path)
    if candidate.exists():
        return candidate
    if not candidate.is_absolute() and candidate.parent == Path("."):
        fallback = DEFAULT_REFERENCE_IMAGE_DIR / candidate.name
        if fallback.exists():
            return fallback
    raise SystemExit(f"Reference image not found: {raw_path}")


def build_multipart_form_data(fields: dict[str, str], file_field_name: str, file_path: Path) -> tuple[str, bytes]:
    boundary = f"----copilot-boundary-{uuid.uuid4().hex}"
    line_break = b"\r\n"
    parts: list[bytes] = []
    for key, value in fields.items():
        parts.append(f"--{boundary}".encode("utf-8"))
        parts.append(f"Content-Disposition: form-data; name=\"{key}\"".encode("utf-8"))
        parts.append(b"")
        parts.append(str(value).encode("utf-8"))

    mime_type = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
    parts.append(f"--{boundary}".encode("utf-8"))
    parts.append(
        f"Content-Disposition: form-data; name=\"{file_field_name}\"; filename=\"{file_path.name}\"".encode("utf-8")
    )
    parts.append(f"Content-Type: {mime_type}".encode("utf-8"))
    parts.append(b"")
    parts.append(file_path.read_bytes())

    parts.append(f"--{boundary}--".encode("utf-8"))
    body = line_break.join(parts) + line_break
    content_type = f"multipart/form-data; boundary={boundary}"
    return content_type, body


def build_edit_request(
    base_url: str,
    deployment_name: str,
    api_key: str,
    prompt: str,
    size: str,
    quality: str,
    background: str,
    reference_image_path: Path,
) -> tuple[str, dict[str, str], bytes]:
    normalized_base = normalize_base_url(base_url)
    fields: dict[str, str] = {
        "prompt": prompt,
        "size": size,
        "quality": quality,
    }
    if background != "auto":
        fields["background"] = background

    if "/openai/v1" in normalized_base:
        url = f"{normalized_base}/images/edits"
        fields["model"] = deployment_name
        headers = {
            "api-key": api_key,
        }
        content_type, body = build_multipart_form_data(fields, "image", reference_image_path)
        headers["Content-Type"] = content_type
        return url, headers, body

    if "/openai/deployments/" in normalized_base:
        root = normalized_base.split("/openai/deployments/", 1)[0]
    elif normalized_base.endswith("/openai"):
        root = normalized_base[: -len("/openai")]
    else:
        root = normalized_base

    encoded_deployment = urllib.parse.quote(deployment_name, safe="")
    url = f"{root}/openai/deployments/{encoded_deployment}/images/edits?api-version={PREVIEW_API_VERSION}"
    content_type, body = build_multipart_form_data(fields, "image", reference_image_path)
    headers = {
        "Content-Type": content_type,
        "api-key": api_key,
    }
    return url, headers, body


def decode_image_bytes(response_json: dict) -> bytes:
    data = response_json.get("data", [])
    if isinstance(data, list) and data:
        first = data[0]
        if isinstance(first, dict):
            b64_value = first.get("b64_json") or first.get("base64_data")
            if isinstance(b64_value, str) and b64_value:
                return base64.b64decode(b64_value)
            url_value = first.get("url")
            if isinstance(url_value, str) and url_value:
                with urllib.request.urlopen(url_value) as response:
                    return response.read()
    raise ValueError("Could not find image bytes in response payload.")


def request_image(url: str, headers: dict[str, str], body: dict) -> dict:
    request = urllib.request.Request(
        url=url,
        headers=headers,
        data=json.dumps(body).encode("utf-8"),
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        payload = response.read().decode("utf-8")
    return json.loads(payload)


def request_image_bytes(url: str, headers: dict[str, str], body_bytes: bytes) -> dict:
    request = urllib.request.Request(
        url=url,
        headers=headers,
        data=body_bytes,
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        payload = response.read().decode("utf-8")
    return json.loads(payload)


def sanitize_stem(text: str) -> str:
    cleaned = "".join(ch.lower() if ch.isalnum() else "-" for ch in text.strip())
    while "--" in cleaned:
        cleaned = cleaned.replace("--", "-")
    return cleaned.strip("-")[:48] or "sprite"


def output_path_for_prompt(output_dir: Path, prompt: str) -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return output_dir / f"{stamp}-{sanitize_stem(prompt)}.png"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a sprite image through an Azure Foundry / Azure OpenAI image deployment.")
    parser.add_argument("prompt", nargs="+", help="Text prompt for the image model.")
    parser.add_argument("--reference-image", dest="reference_image", help="Optional source image path for edit mode. If only a filename is provided, tools/../assets/characters/heroes/fighter is searched.")
    parser.add_argument("--out", dest="out_path", help="Optional output PNG path.")
    parser.add_argument("--size", default="1024x1024", help="Image size, for example 1024x1024.")
    parser.add_argument("--quality", choices=["low", "medium", "high"], default="low", help="Model quality tier.")
    parser.add_argument("--background", choices=["auto", "transparent", "opaque"], default="auto", help="Background mode if supported by the deployment.")
    parser.add_argument("--dry-run", action="store_true", help="Print resolved request details without calling the API.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    prompt = " ".join(args.prompt).strip()
    if not prompt:
        raise SystemExit("Prompt cannot be empty.")

    env = resolve_env()
    deployment_name = require_env(env, "AI_FOUNDRY_IMAGE_DEPLOYMENT_NAME")
    base_url = require_env(env, "LOCAL_COPILOT_SDK_AZURE_OPENAI_BASE_URL", "AZURE_OPENAI_BASE_URL", "AZURE_OPENAI_ENDPOINT")
    api_key = require_env(env, "LOCAL_AZURE_OPENAI_API_KEY", "AZURE_OPENAI_API_KEY")

    use_edit_mode = bool(args.reference_image)
    reference_image_path: Path | None = None
    if use_edit_mode:
        reference_image_path = resolve_reference_image_path(str(args.reference_image))
        url, headers, body_bytes = build_edit_request(
            base_url=base_url,
            deployment_name=deployment_name,
            api_key=api_key,
            prompt=prompt,
            size=args.size,
            quality=args.quality,
            background=args.background,
            reference_image_path=reference_image_path,
        )
    else:
        url, headers, body = build_request(
            base_url=base_url,
            deployment_name=deployment_name,
            api_key=api_key,
            prompt=prompt,
            size=args.size,
            quality=args.quality,
            background=args.background,
        )

    if args.dry_run:
        dry_run_payload = {
            "url": url,
            "headers": {
                "Content-Type": headers.get("Content-Type", "multipart/form-data"),
                "api-key": "***",
            },
            "mode": "edit" if use_edit_mode else "generate",
        }
        if use_edit_mode and reference_image_path is not None:
            dry_run_payload["reference_image"] = str(reference_image_path)
            dry_run_payload["multipart_size_bytes"] = len(body_bytes)
        else:
            dry_run_payload["body"] = body
        print(json.dumps(dry_run_payload, indent=2))
        return 0

    output_dir = DEFAULT_OUTPUT_DIR
    output_dir.mkdir(parents=True, exist_ok=True)
    out_path = Path(args.out_path) if args.out_path else output_path_for_prompt(output_dir, prompt)

    try:
        if use_edit_mode:
            response_json = request_image_bytes(url, headers, body_bytes)
        else:
            response_json = request_image(url, headers, body)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        print(f"HTTP {exc.code} from image endpoint:\n{detail}", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"Failed to reach image endpoint: {exc}", file=sys.stderr)
        return 1

    try:
        image_bytes = decode_image_bytes(response_json)
    except Exception as exc:  # noqa: BLE001
        print(f"Unexpected response shape: {exc}\n{json.dumps(response_json, indent=2)}", file=sys.stderr)
        return 1

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(image_bytes)
    print(out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
