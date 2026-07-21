#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
from pathlib import Path

from gen_sprite import (
    DEFAULT_OUTPUT_DIR,
    build_request,
    decode_image_bytes,
    output_path_for_prompt,
    request_image,
    require_env,
    resolve_env,
)


ROOM_LAYOUT_CHOICES = [
    "flooded_cross",
    "moss_terraces",
    "stream_horizontal",
    "stream_vertical",
    "crystal_grotto",
]

ROOM_THEME_CHOICES = [
    "cavern",
    "fungal",
    "ruins",
]

ROOM_ART_MODES = [
    "overview",
    "piece",
    "sheet",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate room-environment concept art through the Azure Foundry / Azure OpenAI image deployment configured in .env.")
    parser.add_argument("--theme", choices=ROOM_THEME_CHOICES, default="cavern", help="Environment theme.")
    parser.add_argument("--layout", choices=ROOM_LAYOUT_CHOICES, default="flooded_cross", help="Room geometry to depict.")
    parser.add_argument("--mode", choices=ROOM_ART_MODES, default="overview", help="Prompt preset.")
    parser.add_argument("--out", dest="out_path", help="Optional output PNG path.")
    parser.add_argument("--size", default="1024x1024", help="Image size, for example 1024x1024.")
    parser.add_argument("--quality", choices=["low", "medium", "high"], default="low", help="Model quality tier.")
    parser.add_argument("--background", choices=["auto", "transparent", "opaque"], default="opaque", help="Background mode if supported by the deployment.")
    parser.add_argument("--extra", default="", help="Extra sentence appended to the generated prompt.")
    parser.add_argument("--dry-run", action="store_true", help="Print the resolved prompt and request details without calling the API.")
    return parser.parse_args()


def theme_phrase(theme_id: str) -> str:
    match theme_id:
        case "fungal":
            return "bioluminescent fungal underdark, mushroom growth, violet pools, damp stone"
        case "ruins":
            return "ancient submerged stone ruins, weathered masonry, shallow teal water, worn tiles"
        case _:
            return "rocky cavern, mossy stone, shallow streams, damp cave walls"


def layout_phrase(layout_id: str) -> str:
    match layout_id:
        case "stream_horizontal":
            return "a room with a central stone platform and horizontal stream channels flanking the walkway"
        case "stream_vertical":
            return "a room with a central stone platform and vertical stream channels flanking the walkway"
        case "moss_terraces":
            return "a terraced room with a broad center platform, side shelves, and uneven mossy growth"
        case "crystal_grotto":
            return "a crystal chamber with a central dais, approach causeways, and symmetrical side pools"
        case _:
            return "a flooded cross room with a central platform linked to doors by narrow causeways over water"


def room_art_prompt(theme_id: str, layout_id: str, mode: str, extra: str) -> str:
    base = (
        "Top-down fake-isometric modular dungeon room concept art for a mobile tactics game. "
        f"Theme: {theme_phrase(theme_id)}. "
        f"Layout: {layout_phrase(layout_id)}. "
        "Clearly separate walkable stone floor from blocked terrain. "
        "No characters, no UI, no text, no labels. "
        "Readable silhouette, clean edges, hand-painted fantasy art, asset-friendly composition."
    )
    if mode == "piece":
        base += (
            " Show a single premade room piece centered in frame, suitable as a reusable room background asset. "
            "Keep the room footprint fully visible with minimal perspective distortion."
        )
    elif mode == "sheet":
        base += (
            " Present a compact concept sheet with four closely related room-piece variants for the same layout, "
            "consistent scale and lighting, arranged cleanly for art direction review."
        )
    else:
        base += (
            " Show one polished room overview with enough border space to read door openings and blocked terrain."
        )
    if extra.strip():
        base += " " + extra.strip()
    return base


def main() -> int:
    args = parse_args()
    prompt = room_art_prompt(args.theme, args.layout, args.mode, args.extra)

    env = resolve_env()
    deployment_name = require_env(env, "AI_FOUNDRY_IMAGE_DEPLOYMENT_NAME")
    base_url = require_env(env, "LOCAL_COPILOT_SDK_AZURE_OPENAI_BASE_URL", "AZURE_OPENAI_BASE_URL", "AZURE_OPENAI_ENDPOINT")
    api_key = require_env(env, "LOCAL_AZURE_OPENAI_API_KEY", "AZURE_OPENAI_API_KEY")

    url, headers, body = build_request(
        base_url=base_url,
        deployment_name=deployment_name,
        api_key=api_key,
        prompt=prompt,
        size=args.size,
        quality=args.quality,
        background=args.background,
    )

    output_dir = DEFAULT_OUTPUT_DIR / "rooms"
    output_dir.mkdir(parents=True, exist_ok=True)
    default_name = f"{args.theme}-{args.layout}-{args.mode}"
    out_path = Path(args.out_path) if args.out_path else output_path_for_prompt(output_dir, default_name)

    if args.dry_run:
        print(json.dumps({
            "prompt": prompt,
            "url": url,
            "headers": {
                "Content-Type": headers["Content-Type"],
                "api-key": "***",
            },
            "body": body,
            "out_path": str(out_path),
        }, indent=2))
        return 0

    try:
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
