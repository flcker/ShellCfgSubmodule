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
apply_zed() {
    local zed_settings="$HOME/.config/zed/settings.json"
    if [[ ! -f "$zed_settings" ]]; then
        echo "✗  Zed settings not found: $zed_settings" >&2
        return 1
    fi

    ZED_SETTINGS="$zed_settings" python3 << 'PYEOF'
import os, json, shutil

settings_path = os.environ['ZED_SETTINGS']
backup_path   = settings_path + ".bak"

# 备份原始文件
shutil.copy2(settings_path, backup_path)

# Zed settings 包含 // 注释，需要预处理
with open(settings_path) as f:
    raw = f.read()

# 去除行注释（// ...）
import re
cleaned = re.sub(r'//[^\n]*', '', raw)
# 去除尾随逗号（JSON 不允许）
cleaned = re.sub(r',\s*([}\]])', r'\1', cleaned)

try:
    settings = json.loads(cleaned)
except json.JSONDecodeError as e:
    print(f"✗  Failed to parse {settings_path}: {e}")
    exit(1)

# 检测 clangd 路径
clangd_path = shutil.which("clangd") or ""

settings.setdefault("lsp", {})
settings["lsp"]["clangd"] = {
    "binary": { "path": clangd_path }
}

# 写回（保留原有注释头，追加 lsp 字段到已解析内容）
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"✓  Zed: clangd path set to '{clangd_path}'")
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
