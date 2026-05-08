#!/usr/bin/env python3
"""StarshipAuto generator — reads data/ TOML files, outputs generated/ configs."""

import json
import sys
from pathlib import Path

if sys.version_info >= (3, 11):
    import tomllib
else:
    try:
        import tomli as tomllib
    except ImportError:
        print("Error: Python 3.11+ required, or install tomli: pip install tomli", file=sys.stderr)
        sys.exit(1)

ROOT = Path(__file__).parent
DATA_DIR = ROOT / "data"
GENERATED_DIR = ROOT / "generated"


def load_toml(path: Path) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)


def load_all_layouts() -> dict[str, dict]:
    layouts = {}
    for f in (DATA_DIR / "layouts").glob("*.toml"):
        data = load_toml(f)
        name = data["metadata"]["name"]
        layouts[name] = data
    return layouts


def load_all_palettes() -> dict[str, dict]:
    palettes = {}
    for f in (DATA_DIR / "palettes").glob("*.toml"):
        data = load_toml(f)
        name = f.stem
        palettes[name] = data
    return palettes


def load_modules(layout_name: str, layout: dict) -> dict | None:
    ref = layout.get("metadata", {}).get("modules_ref", layout_name)
    path = DATA_DIR / "modules" / f"{ref}.toml"
    if path.exists():
        return load_toml(path)
    return None


def load_shared() -> dict:
    shared = {}
    for f in (DATA_DIR / "shared").glob("*.toml"):
        shared[f.stem] = load_toml(f)
    return shared


def is_compatible(layout: dict, palette: dict) -> bool:
    required_keys = set(layout["metadata"]["palette_keys"])
    available_keys = set(palette["palette"].keys())
    return required_keys.issubset(available_keys)


def toml_quote(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        if "'" not in value:
            return f"'{value}'"
        return f'"{value}"'
    return f'"{value}"'


def build_lang_modules_format(lang_order: list[str]) -> str:
    return "\\\n".join(f"${lang}" for lang in lang_order)


def emit_module_section(name: str, config: dict, fg_role: str) -> str:
    lines = []

    if name == "directory_substitutions":
        lines.append("[directory.substitutions]")
        for k, v in config.items():
            lines.append(f"{toml_quote(k)} = {toml_quote(v)}")
        return "\n".join(lines)

    lines.append(f"[{name}]")
    for key, value in config.items():
        actual_value = value
        if isinstance(value, str):
            actual_value = value.replace("{FG_ROLE}", fg_role)
        lines.append(f"{key} = {toml_quote(actual_value)}")
    return "\n".join(lines)


def generate_config(
    layout: dict,
    palette_name: str,
    palette: dict,
    modules_data: dict,
    shared: dict,
) -> str:
    fg_role = palette.get("hints", {}).get("fg_role", layout["metadata"]["default_fg_role"])
    options = dict(shared.get("options", {}).get("options", {}))
    options.update(layout.get("options", {}))
    lang_order = modules_data["lang_order"]["order"]
    all_modules = modules_data["modules"]

    # Starship palette name uses underscores (TOML section name)
    starship_palette_name = palette_name.replace("-", "_")

    sections = []

    # ── Header ────────────────────────────────────────────────────────────────
    header_lines = [
        "\"$schema\" = 'https://starship.rs/config-schema.json'",
        "",
        f"command_timeout = {options['command_timeout']}",
        f"scan_timeout = {options['scan_timeout']}",
        f"add_newline = {'true' if options['add_newline'] else 'false'}",
    ]
    sections.append("\n".join(header_lines))

    # ── Format ────────────────────────────────────────────────────────────────
    lang_modules_str = build_lang_modules_format(lang_order)
    format_template = layout["format"]["template"]
    format_str = format_template.replace("{LANG_MODULES}", lang_modules_str)
    format_str = format_str.replace("{FG_ROLE}", fg_role)

    # ── Multiline injection ─────────────────────────────────────────────────
    multiline_cfg = shared.get("multiline", {}).get("multiline", {})
    if multiline_cfg and "$line_break" in format_str:
        style = multiline_cfg["style"]
        if "muted" not in palette["palette"]:
            style = multiline_cfg.get("fallback_style", "fg:grey")
        top = multiline_cfg["top_prefix"].replace("{STYLE}", style)
        bottom = multiline_cfg["bottom_prefix"].replace("{STYLE}", style)
        format_str = f"{top}\\\n{format_str}"
        format_str = format_str.replace("$line_break", f"$line_break\\\n{bottom}")

    format_section = f'format = """\n{format_str}"""'
    sections.append(format_section)

    sections.append(f"palette = '{starship_palette_name}'")

    # ── OS Symbols ────────────────────────────────────────────────────────────
    os_config = all_modules.get("os", {})
    if not os_config.get("disabled", False):
        os_section = emit_module_section("os", os_config, fg_role)
        sections.append(os_section)

        if "os_symbols" in shared:
            lines = ["[os.symbols]"]
            for k, v in shared["os_symbols"]["os_symbols"].items():
                lines.append(f"{k} = {toml_quote(v)}")
            sections.append("\n".join(lines))
    else:
        sections.append(emit_module_section("os", os_config, fg_role))

    # ── Fixed modules (username, hostname, directory, git, etc.) ──────────────
    fixed_order = [
        "username", "hostname",
        "directory", "directory_substitutions",
        "git_branch", "git_status", "git_state", "git_commit",
    ]
    for mod_name in fixed_order:
        if mod_name in all_modules:
            sections.append(emit_module_section(mod_name, all_modules[mod_name], fg_role))

    # ── Language modules ──────────────────────────────────────────────────────
    for lang in lang_order:
        if lang in all_modules:
            sections.append(emit_module_section(lang, all_modules[lang], fg_role))

    # ── Container/environment modules ─────────────────────────────────────────
    container_order = ["docker_context", "nix_shell", "conda"]
    for mod_name in container_order:
        if mod_name in all_modules:
            sections.append(emit_module_section(mod_name, all_modules[mod_name], fg_role))

    # ── Right-side modules ────────────────────────────────────────────────────
    right_order = ["fill", "jobs", "status", "cmd_duration", "time"]
    for mod_name in right_order:
        if mod_name in all_modules:
            sections.append(emit_module_section(mod_name, all_modules[mod_name], fg_role))

    # ── Line break ────────────────────────────────────────────────────────────
    if "line_break" in all_modules:
        sections.append(emit_module_section("line_break", all_modules["line_break"], fg_role))

    # ── Character (shared) ────────────────────────────────────────────────────
    if "character" in shared:
        char_config = shared["character"]["character"]
        sections.append(emit_module_section("character", char_config, fg_role))

    # ── Palette ───────────────────────────────────────────────────────────────
    palette_lines = [f"[palettes.{starship_palette_name}]"]
    for k, v in palette["palette"].items():
        palette_lines.append(f"{k} = {toml_quote(v)}")
    sections.append("\n".join(palette_lines))

    return "\n\n".join(sections) + "\n"


def main():
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    layouts = load_all_layouts()
    palettes = load_all_palettes()
    shared = load_shared()

    if not layouts:
        print("Error: No layouts found in data/layouts/", file=sys.stderr)
        sys.exit(1)
    if not palettes:
        print("Error: No palettes found in data/palettes/", file=sys.stderr)
        sys.exit(1)

    manifest = {"configs": []}
    generated_count = 0

    for layout_name, layout in sorted(layouts.items()):
        modules_data = load_modules(layout_name, layout)
        if not modules_data:
            print(f"Warning: No modules file for layout '{layout_name}', skipping", file=sys.stderr)
            continue

        for palette_name, palette in sorted(palettes.items()):
            if not is_compatible(layout, palette):
                continue

            config_name = f"{layout_name}_{palette_name}"
            filename = f"{config_name}.toml"
            output_path = GENERATED_DIR / filename

            content = generate_config(layout, palette_name, palette, modules_data, shared)
            output_path.write_text(content, encoding="utf-8")

            manifest["configs"].append({
                "name": config_name,
                "layout": layout_name,
                "palette": palette_name,
                "file": filename,
            })
            generated_count += 1
            print(f"  Generated: {filename}")

    manifest_path = GENERATED_DIR / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"\nDone: {generated_count} configs generated, manifest written to {manifest_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
