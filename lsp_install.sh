#!/usr/bin/env bash
# lsp_install.sh — 读取 lsp_config.json，将 LSP 服务器安装到系统 PATH
# 用法: bash lsp_install.sh
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

export LSP_CONFIG
python3 << 'PYEOF'
import os, json, subprocess, shutil

config_path = os.environ['LSP_CONFIG']
with open(config_path) as f:
    config = json.load(f)

def has(cmd):
    return shutil.which(cmd) is not None

pip_cmd = "pip3" if shutil.which("pip3") else "pip"

mgrs = {
    "brew":   has("brew"),
    "apt":    has("apt-get"),
    "pacman": has("pacman"),
    "npm":    has("npm"),
    "pip":    has(pip_cmd),
    "cargo":  has("cargo"),
    "go":     has("go"),
    "rustup": has("rustup"),
}

def run(cmd):
    print(f"  $ {cmd}", flush=True)
    subprocess.run(cmd, shell=True, check=True)

def install_via(mgr, pkg):
    dispatch = {
        "npm":    f"npm install -g {pkg}",
        "pip":    f"{pip_cmd} install --user {pkg}",
        "brew":   f"brew install {pkg}",
        "apt":    f"sudo apt-get install -y {pkg}",
        "pacman": f"sudo pacman -S --noconfirm {pkg}",
        "cargo":  f"cargo install {pkg}",
        "go":     f"go install {pkg}",
        "rustup": f"rustup component add {pkg}",
    }
    run(dispatch[mgr])

results = []
for name, server in config.get("servers", {}).items():
    cmd_name = server["command"]
    if shutil.which(cmd_name):
        results.append(("✓", name, "already in PATH"))
        continue

    install = server.get("install", {})
    priority = install.get("priority", [])
    done = False

    for mgr in priority:
        if mgrs.get(mgr) and mgr in install:
            print(f"\n→ Installing {name} via {mgr}…", flush=True)
            try:
                install_via(mgr, install[mgr])
                post = server.get("post_install", {}).get(mgr)
                if post:
                    print("  (post-install)", flush=True)
                    run(post)
                results.append(("→", name, f"installed via {mgr}"))
            except subprocess.CalledProcessError as e:
                results.append(("✗", name, f"failed via {mgr}: {e}"))
            done = True
            break

    if not done:
        needed = ", ".join(priority)
        results.append(("✗", name, f"no available installer (need one of: {needed})"))

print("\n── LSP Install Summary ──────────────────────────────")
for status, name, note in results:
    print(f"  {status}  {name:<24} {note}")
print()
PYEOF
