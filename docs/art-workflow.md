# Art Workflow

Use `tools/gen_sprite.py` to generate character or item sprite candidates through the Azure Foundry / Azure OpenAI image deployment configured in `.env`.

Examples:

```powershell
python tools/gen_sprite.py "top-down fantasy wizard hero sprite, neutral pose, painterly, clean silhouette, mobile readable"
```

```powershell
python tools/gen_sprite.py --dry-run "single dungeon torch icon, warm glow, isolated asset"
```

Outputs are written to `assets/generated/` by default unless `--out` is provided.

Use `tools/gen_room_art.py` for environment concepts keyed by room `layout` and `theme`.

Examples:

```powershell
python tools/gen_room_art.py --theme cavern --layout flooded_cross --mode overview
```

```powershell
python tools/gen_room_art.py --theme cavern --layout stream_horizontal --mode piece --extra "Emphasize clear doorway thresholds and narrow stone causeways."
```

Suggested workflow:

1. Generate overview or sheet concepts for each `geometry_id` and floor `theme_id`.
2. Pick the strongest candidate and paint or cut it down into reusable room-piece assets.
3. Keep geometry consistent across floors and swap only the art theme, so later floors can reuse the same walkable layouts with different visuals.
