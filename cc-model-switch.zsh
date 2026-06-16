# ============================================================
# Claude Code 模型预设 (v2)
# ============================================================
# 预设及 env 操作。厂商凭证由 cc-vendor-switch 管理。
# ============================================================

# ============================================================
# ANSI 颜色
# ============================================================

autoload -U colors && colors
C_DARK_GRAY="$fg[white]"
C_GREEN="$fg[green]"
C_CYAN="$fg[cyan]"
C_YELLOW="$fg[yellow]"
C_RED="$fg[red]"
C_RESET="$reset_color"

# ============================================================
# 应用模型组合 opus sonnet haiku [current]
# ============================================================

_cc_model_apply() {
    local opus="$1" sonnet="$2" haiku="$3" current="${4:-$1}"
    export ANTHROPIC_MODEL="$current"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$opus"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$sonnet"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku"

    if [[ "$current" == claude-opus-* ]]; then
        unset CLAUDE_CODE_EFFORT_LEVEL
        unset CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING
    else
        export CLAUDE_CODE_EFFORT_LEVEL="max"
        export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING="1"
    fi
}

# ============================================================
# 按名称切换预设（仅查配置）
# ============================================================

_cc_model_switch() {
    local name="$1"
    local vendor="${CC_CURRENT_VENDOR:-}"

    if [[ -z "$vendor" ]]; then
        echo "${C_RED}✗ 未选择厂商，请先 cc vendor <name>${C_RESET}" >&2
        return 1
    fi

    local opus_key="CC_VENDOR_${(U)vendor}_PRESET_${(U)name}_OPUS"
    local sonnet_key="CC_VENDOR_${(U)vendor}_PRESET_${(U)name}_SONNET"
    local haiku_key="CC_VENDOR_${(U)vendor}_PRESET_${(U)name}_HAIKU"
    if [[ -n "${(P)opus_key}" ]] && [[ -n "${(P)sonnet_key}" ]] && [[ -n "${(P)haiku_key}" ]]; then
        local current_key="CC_VENDOR_${(U)vendor}_PRESET_${(U)name}_CURRENT"
        _cc_model_apply "${(P)opus_key}" "${(P)sonnet_key}" "${(P)haiku_key}" "${(P)current_key}"
        echo "${C_GREEN}✓ 预设: ${C_CYAN}${name}${C_DARK_GRAY} → ${(P)opus_key}, ${(P)sonnet_key}, ${(P)haiku_key}${C_RESET}"
        return 0
    fi

    echo "${C_RED}✗ 未知预设: ${name}${C_RESET}" >&2
    echo "${C_DARK_GRAY}  在配置文件添加: vendor.${vendor}.preset.${name}.opus/sonnet/haiku${C_RESET}"
    return 1
}

# ============================================================
# 显示当前状态
# ============================================================

_cc_model_display() {
    local current="${ANTHROPIC_MODEL:-${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus (官方)}}"
    local opus="${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus (官方)}"
    local sonnet="${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet (官方)}"
    local haiku="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku (官方)}"
    local url="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"

    if [[ -n "$CC_CURRENT_VENDOR" ]]; then
        echo "${C_DARK_GRAY}[Vendor]:  ${C_CYAN}${CC_CURRENT_VENDOR}${C_RESET}"
    fi
    echo "${C_DARK_GRAY}[Current]: ${C_CYAN}${current}${C_RESET}"
    echo "${C_DARK_GRAY}[Opus]:    ${C_CYAN}${opus}${C_DARK_GRAY}\t [Sonnet]: ${C_CYAN}${sonnet}${C_DARK_GRAY}\t [Haiku]:  ${C_CYAN}${haiku}${C_RESET}"
    echo "${C_DARK_GRAY}[API]:     ${url}${C_RESET}"

    local vendor="${CC_CURRENT_VENDOR:-}"
    if [[ -n "$vendor" ]]; then
        local presets=()
        local prefix="CC_VENDOR_${(U)vendor}_PRESET_"
        for var in ${(Mk)parameters:#${prefix}*_OPUS}; do
            local pname="${var#$prefix}"
            pname="${pname%_OPUS}"
            presets+=("${(L)pname}")
        done
        if [[ ${#presets[@]} -gt 0 ]]; then
            echo "${C_DARK_GRAY}[Presets]: ${C_CYAN}${(j:, :)presets}${C_RESET}"
        fi
    fi
}

# ============================================================
# 启动提示
# ============================================================

_cc_model_help() {
    echo "用法: ${C_GREEN}cc model [name|o s h [c]]${C_RESET}"
    echo ""
    echo "  ${C_GREEN}cc model${C_RESET}              显示 [Vendor] [Current] [Opus] [Sonnet] [Haiku] [Presets]"
    echo "  ${C_GREEN}cc model <name>${C_RESET}       切换预设（查 vendor.<v>.preset.<name>.*）"
    echo "  ${C_GREEN}cc model <o> <s> <h>${C_RESET}     自定义 Opus/Sonnet/Haiku"
    echo "  ${C_GREEN}cc model <o> <s> <h> <c>${C_RESET} 自定义 Opus/Sonnet/Haiku/Current"
    echo ""
    echo "预设定义在配置文件中: vendor.<v>.preset.<name>.opus/sonnet/haiku"
}

echo "${C_DARK_GRAY}[cc-tools] 已加载${C_RESET}"
