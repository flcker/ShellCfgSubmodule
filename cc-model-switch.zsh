# ============================================================
# Claude Code 多模型切换脚本
# ============================================================
# 通过统一代理切换 Claude Code 使用的 AI 模型。
# 支持 Opus / Sonnet / Haiku 三个级别分别映射不同模型。
#
# 使用方法:
#   1. 在 ~/.zshrc 中配置代理凭证（二选一，按优先级）：
#      a) 推荐：仅暴露鉴权 header，地址仍走官方
#         export CC_MODEL_API_KEY="sk-..."
#      b) 全量代理（使用自建 API 网关）：
#         export CC_MODEL_BASE_URL="http://your-proxy.com/coding"
#         export CC_MODEL_API_KEY="sk-..."
#
#   2. source ~/.config/zsh/submodule/cc-tools/cc.zsh
#      （或单独 source cc-model-switch.zsh）
#
# 注意：凭证存入 ~/.zshrc 后可通过 git 同步脚本本身，不会暴露密钥。
# ============================================================

# ============================================================
# 统一配置（可在 ~/.zshrc 中覆盖）
# ============================================================

: ${CC_MODEL_BASE_URL:=""}
: ${CC_MODEL_API_KEY:=""}
: ${CC_MODEL_DISABLE_EXPERIMENTAL_BETAS:="1"}
: ${CC_MODEL_ATTRIBUTION_HEADER:="false"}

# ============================================================
# ANSI 颜色
# ============================================================

autoload -U colors && colors
C_DARK_GRAY="$fg[white]"
C_GREEN="$fg[green]"
C_CYAN="$fg[cyan]"
C_YELLOW="$fg[yellow]"
C_RESET="$reset_color"

# ============================================================
# 内部辅助函数
# ============================================================

_set_claude_model_env() {
    local sonnet_model="$1"
    local opus_model="$2"
    local haiku_model="$3"
    local enable_effort="$4"

    # 允许仅设置 API key（地址走官方），也支持全量代理
    if [[ -n "$CC_MODEL_BASE_URL" ]]; then
        export ANTHROPIC_BASE_URL="$CC_MODEL_BASE_URL"
    fi
    if [[ -n "$CC_MODEL_API_KEY" ]]; then
        export ANTHROPIC_AUTH_TOKEN="$CC_MODEL_API_KEY"
    fi

    export ANTHROPIC_MODEL="$opus_model"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$sonnet_model"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$opus_model"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku_model"
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="$CC_MODEL_DISABLE_EXPERIMENTAL_BETAS"
    export CLAUDE_CODE_ATTRIBUTION_HEADER="$CC_MODEL_ATTRIBUTION_HEADER"

    if [[ "$enable_effort" == "1" ]]; then
        export CLAUDE_CODE_EFFORT_LEVEL="max"
        export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING="1"
    else
        unset CLAUDE_CODE_EFFORT_LEVEL
        unset CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING
    fi
}

# ============================================================
# DeepSeek 系列
#   Opus/Sonnet → deepseek-v4-pro    Haiku → deepseek-v4-flash
# ============================================================

switch-deepseek() {
    local enable_effort=1
    [[ "$1" == "--no-effort" ]] && enable_effort=0
    _set_claude_model_env "deepseek-v4-pro" "deepseek-v4-pro" "deepseek-v4-flash" "$enable_effort"
    echo "${C_GREEN}✓ DeepSeek | Opus/Sonnet: deepseek-v4-pro | Haiku: deepseek-v4-flash${C_RESET}"
}

# ============================================================
# GLM 系列
#   Opus/Sonnet → glm-5.1    Haiku → glm-4.7
# ============================================================

switch-glm() {
    local enable_effort=1
    [[ "$1" == "--no-effort" ]] && enable_effort=0
    _set_claude_model_env "glm-5.1" "glm-5.1" "glm-4.7" "$enable_effort"
    echo "${C_GREEN}✓ GLM | Opus/Sonnet: glm-5.1 | Haiku: glm-4.7${C_RESET}"
}

# ============================================================
# Claude 官方系列
#   Opus → claude-opus-4.8    Sonnet → claude-sonnet-4.6    Haiku → claude-haiku-4.5
# ============================================================

switch-claude() {
    _set_claude_model_env "claude-sonnet-4.6" "claude-opus-4.8" "claude-haiku-4.5" "0"
    echo "${C_GREEN}✓ Claude | Opus: claude-opus-4.8 | Sonnet: claude-sonnet-4.6 | Haiku: claude-haiku-4.5${C_RESET}"
}

# ============================================================
# GPT 系列
#   Opus/Sonnet → gpt-5.3-codex    Haiku → gpt-5.2-codex
# ============================================================

switch-gpt() {
    local enable_effort=1
    [[ "$1" == "--no-effort" ]] && enable_effort=0
    _set_claude_model_env "gpt-5.3-codex" "gpt-5.3-codex" "gpt-5.2-codex" "$enable_effort"
    echo "${C_GREEN}✓ GPT | Opus/Sonnet: gpt-5.3-codex | Haiku: gpt-5.2-codex${C_RESET}"
}

# ============================================================
# 恢复官方
# ============================================================

restore-claude-official() {
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_MODEL
    unset ANTHROPIC_DEFAULT_SONNET_MODEL
    unset ANTHROPIC_DEFAULT_OPUS_MODEL
    unset ANTHROPIC_DEFAULT_HAIKU_MODEL
    unset CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS
    unset CLAUDE_CODE_ATTRIBUTION_HEADER
    unset CLAUDE_CODE_EFFORT_LEVEL
    unset CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING
    echo "${C_GREEN}✓ 已恢复官方 Anthropic Claude${C_RESET}"
}

# ============================================================
# 状态显示
# ============================================================

show-current-model() {
    local opus="${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus (官方)}"
    local sonnet="${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet (官方)}"
    local haiku="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku (官方)}"
    local url="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"

    echo "${C_DARK_GRAY}[Opus]:   ${C_CYAN}${opus}${C_DARK_GRAY}\t [Sonnet]: ${C_CYAN}${sonnet}${C_DARK_GRAY}\t [Haiku]:  ${C_CYAN}${haiku}${C_RESET}"
    echo "${C_DARK_GRAY}[API]:    ${url}${C_RESET}"
}

# ============================================================
# 别名
# ============================================================

alias cc2ds='switch-deepseek'
alias cc2glm='switch-glm'
alias cc2claude='switch-claude'
alias cc2gpt='switch-gpt'
alias cc2official='restore-claude-official'
alias ccmodel='show-current-model'

# ============================================================
# 模型预设系统 (v2)
# ============================================================

# 内置预设 → "opus sonnet haiku" 字符串
_cc_model_builtin() {
    case "$1" in
        ds|deepseek) echo "deepseek-v4-pro deepseek-v4-pro deepseek-v4-flash" ;;
        glm)         echo "glm-5.1 glm-5.1 glm-4.7" ;;
        claude)      echo "claude-opus-4.8 claude-sonnet-4.6 claude-haiku-4.5" ;;
        gpt)         echo "gpt-5.3-codex gpt-5.3-codex gpt-5.2-codex" ;;
        *)           return 1 ;;
    esac
}

# 应用模型组合 opus sonnet haiku
_cc_model_apply() {
    local opus="$1" sonnet="$2" haiku="$3"
    export ANTHROPIC_MODEL="$opus"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$opus"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$sonnet"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku"

    # Effort: Claude 官方模型不启用
    if [[ "$opus" == claude-opus-* ]]; then
        unset CLAUDE_CODE_EFFORT_LEVEL
        unset CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING
    else
        export CLAUDE_CODE_EFFORT_LEVEL="max"
        export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING="1"
    fi
}

# 按名称切换预设
_cc_model_switch() {
    local name="$1"
    local models
    models=$(_cc_model_builtin "$name") || {
        echo "${C_RED}✗ 未知模型: ${name}${C_RESET}" >&2
        echo "${C_DARK_GRAY}可用: ds|deepseek, glm, claude, gpt${C_RESET}"
        return 1
    }
    _cc_model_apply $=models
    echo "${C_GREEN}✓ 模型: ${C_CYAN}${name}${C_RESET}"
}

# 显示当前模型（增强版，含厂商）
_cc_model_display() {
    local opus="${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus (官方)}"
    local sonnet="${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet (官方)}"
    local haiku="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku (官方)}"

    if [[ -n "$CC_CURRENT_VENDOR" ]]; then
        echo "${C_DARK_GRAY}[Vendor]: ${C_CYAN}${CC_CURRENT_VENDOR}${C_RESET}"
    fi
    echo "${C_DARK_GRAY}[Opus]:   ${C_CYAN}${opus}${C_DARK_GRAY}\t [Sonnet]: ${C_CYAN}${sonnet}${C_DARK_GRAY}\t [Haiku]:  ${C_CYAN}${haiku}${C_RESET}"
    local url="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
    echo "${C_DARK_GRAY}[API]:    ${url}${C_RESET}"
}

# ============================================================
# 启动提示 & 自动切换
# ============================================================

echo "${C_DARK_GRAY}[cc-tools] 已加载，可用: ${C_GREEN}cc2ds / cc2glm / cc2claude / cc2gpt / cc2official / ccmodel${C_RESET}"

# 优先级: CC_VENDOR_*_KEY > CC_MODEL_API_KEY
if [[ -n "$CC_VENDOR_DS_KEY" ]] || [[ -n "$CC_VENDOR_GLM_KEY" ]] || \
   [[ -n "$CC_VENDOR_CLAUDE_KEY" ]] || [[ -n "$CC_VENDOR_GPT_KEY" ]] || \
   [[ -n "$CC_VENDOR_TAL_KEY" ]] || [[ -n "$CC_VENDOR_VOLC_KEY" ]]; then
    echo "${C_DARK_GRAY}[cc-tools] 检测到 CC_VENDOR_* 配置，使用 cc vendor <name> 切换${C_RESET}"
elif [[ -n "$CC_MODEL_API_KEY" ]]; then
    switch-deepseek
else
    echo "${C_YELLOW}⚠ 未配置凭证，跳过自动切换${C_RESET}"
    echo "${C_DARK_GRAY}  请在 ~/.zshrc 中配置 CC_VENDOR_*_KEY 或 CC_MODEL_API_KEY${C_RESET}"
fi
