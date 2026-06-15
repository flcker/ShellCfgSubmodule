# ============================================================
# Claude Code 厂商切换脚本 (v2)
# ============================================================
# 管理 API 厂商凭证（URL + Key），与模型预设独立。
#
# 配置（~/.zshrc）：
#   export CC_VENDOR_<NAME>_URL="http://..."    # API 地址
#   export CC_VENDOR_<NAME>_KEY="sk-..."        # API 密钥
#   export CC_VENDOR_<NAME>_MODELS="o s h"      # 默认模型（可选）
#
# 单模型厂商（DS/GLM/Claude/GPT）有内置模型默认，
# 多模型厂商（TAL/Volc 等）需显式指定 _MODELS。
# ============================================================

# ============================================================
# 厂商列表（注册厂商名）
# ============================================================

_cc_vendor_list() {
    local vendors=()
    local vname
    # 扫描所有 CC_VENDOR_*_KEY 变量
    for var in ${(Mk)parameters:#CC_VENDOR_*_KEY}; do
        vname="${var#CC_VENDOR_}"
        vname="${vname%_KEY}"
        vendors+=("${(L)vname}")
    done
    if [[ ${#vendors[@]} -eq 0 ]]; then
        echo "${C_DARK_GRAY}(未配置任何厂商)${C_RESET}"
        return
    fi
    local current="${CC_CURRENT_VENDOR:-}"
    for v in "${vendors[@]}"; do
        local marker=""
        [[ "$v" == "$current" ]] && marker=" ${C_GREEN}← 当前${C_RESET}"
        echo "  ${C_CYAN}${v}${marker}${C_RESET}"
    done
}

# ============================================================
# 厂商切换
# ============================================================

_cc_vendor_switch() {
    local name="$1"
    local upper="${(U)name}"
    local url_var="CC_VENDOR_${upper}_URL"
    local key_var="CC_VENDOR_${upper}_KEY"
    local models_var="CC_VENDOR_${upper}_MODELS"
    local url="${(P)url_var}"
    local key="${(P)key_var}"
    local models="${(P)models_var}"

    if [[ -z "$key" ]]; then
        echo "${C_RED}✗ 厂商未配置: ${name}（缺少 ${key_var}）${C_RESET}" >&2
        return 1
    fi

    # ----- 应用凭证 -----
    if [[ -n "$url" ]]; then
        export ANTHROPIC_BASE_URL="$url"
    fi
    export ANTHROPIC_AUTH_TOKEN="$key"
    export CC_CURRENT_VENDOR="$name"

    # 通用配置
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="${CC_MODEL_DISABLE_EXPERIMENTAL_BETAS:-1}"
    export CLAUDE_CODE_ATTRIBUTION_HEADER="${CC_MODEL_ATTRIBUTION_HEADER:-false}"

    # ----- 应用模型 -----
    if [[ -n "$models" ]]; then
        _cc_preset_apply $=models
        echo "${C_GREEN}✓ 厂商: ${C_CYAN}${name}${C_GREEN} | 模型: ${models}${C_RESET}"
    elif _cc_preset_builtin "$name" >/dev/null 2>&1; then
        _cc_preset_apply $(_cc_preset_builtin "$name")
        echo "${C_GREEN}✓ 厂商: ${C_CYAN}${name}${C_GREEN} | 预设: ${name}${C_RESET}"
    else
        # 多模型厂商无 _MODELS 配置 → 仅切凭证，模型不变
        echo "${C_GREEN}✓ 厂商: ${C_CYAN}${name}${C_RESET}"
        echo "${C_DARK_GRAY}  模型未变（多模型厂商请用 cc preset 指定组合）${C_RESET}"
    fi
}

# ============================================================
# 恢复官方
# ============================================================

_cc_vendor_official() {
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
    unset CC_CURRENT_VENDOR
    echo "${C_GREEN}✓ 已恢复官方 Anthropic Claude${C_RESET}"
}

# ============================================================
# 启动提示
# ============================================================

echo "${C_DARK_GRAY}[cc-vendor] 已加载，可用: ${C_GREEN}cc vendor <name>${C_RESET}"
