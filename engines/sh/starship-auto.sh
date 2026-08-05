#!/usr/bin/env bash
# starship-auto.sh — bash/zsh switching engine for starshipauto
# Source this file in .bashrc/.zshrc BEFORE eval "$(starship init bash/zsh)"

_STARSHIPAUTO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
_STARSHIPAUTO_GENERATED="$_STARSHIPAUTO_ROOT/generated"
_STARSHIPAUTO_MANIFEST="$_STARSHIPAUTO_GENERATED/manifest.json"

# ── Auto-generate if needed ───────────────────────────────────────────────────
_starshipauto_build() {
    local gen_py="$_STARSHIPAUTO_ROOT/generate.py"
    if [ ! -f "$gen_py" ]; then
        echo "starshipauto: generate.py not found" >&2
        return 1
    fi
    python3 "$gen_py" 2>&1 || python "$gen_py" 2>&1
}

_starshipauto_ensure_generated() {
    if [ ! -f "$_STARSHIPAUTO_MANIFEST" ]; then
        _starshipauto_build
    fi
}

_starshipauto_ensure_generated

# ── Load manifest ─────────────────────────────────────────────────────────────
_starshipauto_list_configs() {
    if command -v jq >/dev/null 2>&1 && [ -f "$_STARSHIPAUTO_MANIFEST" ]; then
        jq -r '.configs[].name' "$_STARSHIPAUTO_MANIFEST"
    elif [ -d "$_STARSHIPAUTO_GENERATED" ]; then
        find "$_STARSHIPAUTO_GENERATED" -name "*.toml" -exec basename {} .toml \;
    fi
}

_starshipauto_get_path() {
    local name="$1"
    local static_dir="${_STARSHIPAUTO_ROOT%/starshipauto}/starship"

    # Generated configs
    if [ -f "$_STARSHIPAUTO_GENERATED/${name}.toml" ]; then
        echo "$_STARSHIPAUTO_GENERATED/${name}.toml"
        return 0
    fi


    # Static configs
    case "$name" in
        custom|c)              echo "$static_dir/starship_custom.toml" ;;
        powerline|pl)          echo "$static_dir/starship_powerline.toml" ;;
        plaintextsymbols|pts)  echo "$static_dir/starship_plaintextsymbols.toml" ;;
        nerdfontsymbols|nfs)   echo "$static_dir/starship_nerdfontsymbols.toml" ;;
        pastelpowerline|ppl)   echo "$static_dir/starship_pastelpowerline.toml" ;;
        nerdpowerline|npl)     echo "$static_dir/starship_nerdpowerline.toml" ;;
        p10kr|p10k_rainbow)    echo "$static_dir/starship_p10k_rainbow.toml" ;;
        p10kc|p10k_classic)    echo "$static_dir/starship_p10k_classic.toml" ;;
        p10kl|p10k_lean)       echo "$static_dir/starship_p10k_lean.toml" ;;
        default|d)             echo "" ;;
        *)                     return 1 ;;
    esac
}

# ── Random selection at startup ───────────────────────────────────────────────
_starshipauto_random_config() {
    local configs=()
    configs+=("")  # starship default

    # Add static configs
    local static_dir="${_STARSHIPAUTO_ROOT%/starshipauto}/starship"
    if [ -d "$static_dir" ]; then
        for f in "$static_dir"/starship_*.toml; do
            [ -f "$f" ] && configs+=("$f")
        done
    fi

    # Add generated configs
    if [ -d "$_STARSHIPAUTO_GENERATED" ]; then
        for f in "$_STARSHIPAUTO_GENERATED"/*.toml; do
            [ -f "$f" ] && configs+=("$f")
        done
    fi

    local count=${#configs[@]}
    if [ "$count" -gt 0 ]; then
        local idx=$((RANDOM % count))
        echo "${configs[$idx]}"
    fi
}

export STARSHIP_CONFIG="$(_starshipauto_random_config)"

# ── ssc command ───────────────────────────────────────────────────────────────
ssc() {
    case "${1:-}" in
        --help|-h|"")
            echo "ssc <config> — switch starship config"
            echo ""
            echo "Generated: $(_starshipauto_list_configs | tr '\n' ' ')"
            echo "  Aliases: p10kr p10kc p10kl"
            echo ""
            echo "Static: custom(c) powerline(pl) plaintextsymbols(pts) nerdfontsymbols(nfs)"
            echo "        pastelpowerline(ppl) nerdpowerline(npl) default(d)"
            echo ""
            echo "Commands: --list --rebuild random(r)"
            echo ""
            echo "Current: $(basename "${STARSHIP_CONFIG:-(default)}" .toml)"
            ;;
        --list)
            echo "Available configs:"
            _starshipauto_list_configs
            echo "custom powerline plaintextsymbols nerdfontsymbols pastelpowerline nerdpowerline default"
            ;;
        --rebuild)
            _starshipauto_build
            ;;
        random|r)
            export STARSHIP_CONFIG="$(_starshipauto_random_config)"
            # Re-init starship (detect shell)
            if [ -n "$ZSH_VERSION" ]; then
                eval "$(starship init zsh)"
            else
                eval "$(starship init bash)"
            fi
            echo "Switched to: $(basename "${STARSHIP_CONFIG:-(default)}" .toml)"
            ;;
        *)
            local cfg_file
            cfg_file="$(_starshipauto_get_path "$1")"
            if [ $? -ne 0 ]; then
                echo "Unknown config: '$1'. Use 'ssc --list' to see available options." >&2
                return 1
            fi
            export STARSHIP_CONFIG="$cfg_file"
            # Re-init starship (detect shell)
            if [ -n "$ZSH_VERSION" ]; then
                eval "$(starship init zsh)"
            else
                eval "$(starship init bash)"
            fi
            echo "Switched to: $(basename "${STARSHIP_CONFIG:-(default)}" .toml)"
            ;;
    esac
}

# ── Tab completion ────────────────────────────────────────────────────────────
if [ -n "$BASH_VERSION" ]; then
    _ssc_completions() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local opts="--help --list --rebuild"
        opts="$opts $(_starshipauto_list_configs 2>/dev/null)"
        opts="$opts p10kr p10kc p10kl custom c powerline pl plaintextsymbols pts nerdfontsymbols nfs pastelpowerline ppl nerdpowerline npl default d random r"
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    }
    complete -F _ssc_completions ssc
elif [ -n "$ZSH_VERSION" ]; then
    _ssc_completions() {
        local opts=("--help" "--list" "--rebuild")
        opts+=($(_starshipauto_list_configs 2>/dev/null))
        opts+=("p10kr" "p10kc" "p10kl" "custom" "c" "powerline" "pl" "plaintextsymbols" "pts" "nerdfontsymbols" "nfs" "pastelpowerline" "ppl" "nerdpowerline" "npl" "default" "d" "random" "r")
        _describe 'config' opts
    }
    compdef _ssc_completions ssc 2>/dev/null
fi
