#!/usr/bin/env bash
# starship-auto.sh — bash/zsh switching engine for starshipauto
# Source this file in .bashrc/.zshrc BEFORE eval "$(starship init bash/zsh)"

_STARSHIPAUTO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
_STARSHIPAUTO_GENERATED="$_STARSHIPAUTO_ROOT/generated"
_STARSHIPAUTO_MANIFEST="$_STARSHIPAUTO_GENERATED/manifest.json"
_STARSHIPAUTO_LOCK_FILE="$HOME/.starshipauto_lock"

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

# ── Lock support ──────────────────────────────────────────────────────────────
# Read locked config path from lock file (trimmed). Empty output = no lock or
# empty lock (= starship default). Lock file lives outside the repo so it does
# not dirty the submodule.
__starshipauto_read_lock() {
    [ -f "$_STARSHIPAUTO_LOCK_FILE" ] || return 0
    local locked=""
    read -r locked < "$_STARSHIPAUTO_LOCK_FILE" 2>/dev/null
    printf '%s' "$locked"
}

# Resolve a user-supplied name to a config path for locking purposes.
#   - "default" / "d" → empty path (starship default)
#   - exact alias/fullname via _starshipauto_get_path → that path
#   - otherwise prefix-match against generated + static canonical names
# Ambiguous (multiple prefix matches) → list candidates to stderr, return 1.
# No match → "Unknown config" to stderr, return 1.
__starshipauto_resolve_for_lock() {
    local name="$1"
    # default/d → starship default (empty path)
    if [ "$name" = "default" ] || [ "$name" = "d" ]; then
        printf ''
        return 0
    fi
    # Exact alias/fullname
    local p=""
    p="$(_starshipauto_get_path "$name")"
    if [ -n "$p" ]; then
        printf '%s' "$p"
        return 0
    fi
    # Prefix match against generated + static canonical names
    local candidates=()
    if [ -d "$_STARSHIPAUTO_GENERATED" ]; then
        local f=""
        for f in "$_STARSHIPAUTO_GENERATED"/*.toml; do
            [ -f "$f" ] || continue
            local base=""
            base="$(basename "$f" .toml)"
            case "$base" in
                "$name"*) candidates+=("$base") ;;
            esac
        done
    fi
    local static_names=(custom powerline plaintextsymbols nerdfontsymbols pastelpowerline nerdpowerline p10k_rainbow p10k_classic p10k_lean)
    local sn=""
    for sn in "${static_names[@]}"; do
        case "$sn" in
            "$name"*) candidates+=("$sn") ;;
        esac
    done
    # Deduplicate (a name could appear in both generated and static lists)
    local unique=()
    local seen=":"
    local c=""
    for c in "${candidates[@]}"; do
        case "$seen" in
            *":$c:"*) ;;
            *) unique+=("$c"); seen="${seen}${c}:" ;;
        esac
    done
    if [ "${#unique[@]}" -eq 1 ]; then
        # Grab the single candidate without relying on 0- vs 1-indexing (bash vs zsh)
        local match=""
        for c in "${unique[@]}"; do match="$c"; break; done
        if [ -f "$_STARSHIPAUTO_GENERATED/${match}.toml" ]; then
            printf '%s' "$_STARSHIPAUTO_GENERATED/${match}.toml"
        else
            printf '%s' "$(_starshipauto_get_path "$match")"
        fi
        return 0
    elif [ "${#unique[@]}" -gt 1 ]; then
        echo "Ambiguous '$name': ${unique[*]}" >&2
        echo "Use a longer prefix or 'ssc --list'." >&2
        return 1
    else
        echo "Unknown config: '$name'. Use 'ssc --list' to see available options." >&2
        return 1
    fi
}

# Select config at startup: honour lock file if it points to a valid path
# (or is empty = default), otherwise fall back to random selection.
__starshipauto_select_config() {
    local locked=""
    locked="$(__starshipauto_read_lock)"
    if [ -f "$_STARSHIPAUTO_LOCK_FILE" ] && { [ -z "$locked" ] || [ -f "$locked" ]; }; then
        printf '%s' "$locked"
    else
        _starshipauto_random_config
    fi
}

# Append " (locked)" to the Current: line of `ssc -h` when a lock is active.
__starshipauto_lock_status() {
    [ -f "$_STARSHIPAUTO_LOCK_FILE" ] && printf ' (locked)'
}

export STARSHIP_CONFIG="$(__starshipauto_select_config)"

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
            echo "Commands: --list --rebuild random(r) --lock [cfg] --unlock"
            echo ""
            echo "Lock:    ssc --lock [cfg]   persist across sessions (ssc --unlock to release)"
            echo ""
            echo "Current: $(basename "${STARSHIP_CONFIG:-(default)}" .toml)$(__starshipauto_lock_status)"
            ;;
        --list)
            echo "Available configs:"
            _starshipauto_list_configs
            echo "custom powerline plaintextsymbols nerdfontsymbols pastelpowerline nerdpowerline default"
            ;;
        --rebuild)
            _starshipauto_build
            ;;
        --lock)
            local target=""
            if [ -z "${2:-}" ]; then
                target="$STARSHIP_CONFIG"
            else
                target="$(__starshipauto_resolve_for_lock "$2")" || return 1
            fi
            printf '%s\n' "$target" > "$_STARSHIPAUTO_LOCK_FILE"
            export STARSHIP_CONFIG="$target"
            # Re-init starship (detect shell)
            if [ -n "$ZSH_VERSION" ]; then
                eval "$(starship init zsh)"
            else
                eval "$(starship init bash)"
            fi
            echo "Locked: $(basename "${target:-(default)}" .toml)"
            ;;
        --unlock)
            rm -f "$_STARSHIPAUTO_LOCK_FILE"
            echo "Unlocked: random mode restored"
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
        local opts="--help --list --rebuild --lock --unlock"
        opts="$opts $(_starshipauto_list_configs 2>/dev/null)"
        opts="$opts p10kr p10kc p10kl custom c powerline pl plaintextsymbols pts nerdfontsymbols nfs pastelpowerline ppl nerdpowerline npl default d random r"
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    }
    complete -F _ssc_completions ssc
elif [ -n "$ZSH_VERSION" ]; then
    _ssc_completions() {
        local opts=("--help" "--list" "--rebuild" "--lock" "--unlock")
        opts+=($(_starshipauto_list_configs 2>/dev/null))
        opts+=("p10kr" "p10kc" "p10kl" "custom" "c" "powerline" "pl" "plaintextsymbols" "pts" "nerdfontsymbols" "nfs" "pastelpowerline" "ppl" "nerdpowerline" "npl" "default" "d" "random" "r")
        _describe 'config' opts
    }
    compdef _ssc_completions ssc 2>/dev/null
fi
