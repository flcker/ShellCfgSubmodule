#!/usr/bin/env bash
# lsp_configure.sh — 应用各编辑器的 LSP 配置（Zed / VSCode）
# 用法: bash lsp_configure.sh [zed|vscode|all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LSP_CONFIG="$SCRIPT_DIR/lsp_config.json"

if [[ ! -f "$LSP_CONFIG" ]]; then
    echo "✗  lsp_config.json not found: $LSP_CONFIG" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "✗  python3 is required but not found" >&2
    exit 1
fi

# ── Zed ──────────────────────────────────────────────────────
# Zed 内置所有 LSP server 的下载与管理，无需设置 binary 路径。
# 本函数只合并 lsp_config.json 中各 server 的 "zed.initialization_options"。
apply_zed() {
    local zed_settings="$HOME/.config/zed/settings.json"
    if [[ ! -f "$zed_settings" ]]; then
        echo "✗  Zed settings not found: $zed_settings" >&2
        return 1
    fi

    ZED_SETTINGS="$zed_settings" LSP_CONFIG="$LSP_CONFIG" python3 << 'PYEOF'
import os, json, re, shutil

settings_path = os.environ['ZED_SETTINGS']
config_path   = os.environ['LSP_CONFIG']
backup_path   = settings_path + ".bak"

shutil.copy2(settings_path, backup_path)

with open(settings_path) as f:
    raw = f.read()

# Zed settings 是 JSONC，去除注释和尾随逗号后解析
cleaned = re.sub(r'//[^\n]*', '', raw)
cleaned = re.sub(r',\s*([}\]])', r'\1', cleaned)

try:
    settings = json.loads(cleaned)
except json.JSONDecodeError as e:
    print(f"✗  Failed to parse {settings_path}: {e}")
    exit(1)

with open(config_path) as f:
    config = json.load(f)

settings.setdefault("lsp", {})
applied = []

for name, server in config.get("servers", {}).items():
    zed_opts = server.get("zed", {})
    init_opts = zed_opts.get("initialization_options")
    if init_opts:
        zed_name = zed_opts.get("name", name)  # Zed 可能用不同命名（如连字符）
        settings["lsp"].setdefault(zed_name, {})["initialization_options"] = init_opts
        applied.append(zed_name)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

if applied:
    print(f"✓  Zed: applied initialization_options for: {', '.join(applied)}")
else:
    print("✓  Zed: no initialization_options to apply")
print(f"   (backup: {backup_path})")
PYEOF
}

# ── VSCode ────────────────────────────────────────────────────
apply_vscode() {
    if ! command -v code >/dev/null 2>&1; then
        echo "✗  VSCode CLI (code) not found — skipping" >&2
        return 1
    fi

    LSP_CONFIG="$LSP_CONFIG" python3 << 'PYEOF'
import os, json, subprocess, shutil

config_path = os.environ['LSP_CONFIG']
with open(config_path) as f:
    config = json.load(f)

extensions = config.get("vscode_extensions", [])
results = []

for ext in extensions:
    result = subprocess.run(
        ["code", "--install-extension", ext, "--force"],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        results.append(("✓", ext))
    else:
        results.append(("✗", ext + " — " + result.stderr.strip()))

print("\n── VSCode Extensions ────────────────────────────────")
for status, note in results:
    print(f"  {status}  {note}")
print()
PYEOF
}

# ── 入口 ─────────────────────────────────────────────────────
TARGET="${1:-all}"
case "$TARGET" in
    zed)    apply_zed ;;
    vscode) apply_vscode ;;
    all)
        echo "── Configuring Zed ──────────────────────────────────"
        apply_zed || true
        echo ""
        echo "── Configuring VSCode ───────────────────────────────"
        apply_vscode || true
        ;;
    *)
        echo "用法: $0 [zed|vscode|all]" >&2
        exit 1
        ;;
esac
