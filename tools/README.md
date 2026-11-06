# Tools

`art/` – Python scripts that generate the pixel art of some ships and write it into `data/pixel_art.gd`
(run from anywhere: `python tools/art/hadrian_art.py`; `--show` prints the art instead).

- `kanayama_art.py` – Kanayama-maru (package 25b)
- `aurelle_art.py` – Pearl, Boulevard, Opal (package 25c)
- `empress_art.py` – the Empress with the park deck (full height, not mirrored)
- `hadrian_art.py` – Talon, Maul, Goliath, Citadel and the Citadel's bridge variants (`VARIANTS`)

Godot ignores this folder (`.gdignore`).
