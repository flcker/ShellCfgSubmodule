# ============================================================
# Claude Code 厂商切换脚本 (v2)
# ============================================================
# 管理 API 厂商凭证（URL + Key），与模型预设独立。
# 全部厂商 + 模型映射在 ~/.config/cc-tools/cc-tools.conf 中配置。
# ============================================================

# 全局追踪数组：记录当前已应用的厂商自定义 env 变量名（vendor.<v>.env.<VAR>）
# 切换厂商 / cc official 时据此 unset，恢复 Claude 默认行为
typeset -ga CC_ACTIVE_ENV_VARS

# 全局追踪数组：记录当前已应用的预设自定义 env 变量名（vendor.<v>.preset.<p>.env.<VAR>）
# 切换预设 / 厂商 / cc official 时据此 unset
typeset -ga CC_ACTIVE_PRESET_ENV_VARS

# ============================================================
# 厂商列表
# ============================================================

_cc_vendor_list() {
    local vendors=()
    local vname
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

    # 当前厂商先展示，带预设列表
    if [[ -n "$current" ]]; then
        local upper="${(U)current}"
        local url_var="CC_VENDOR_${upper}_URL"
        local models_var="CC_VENDOR_${upper}_MODELS"
        local url="${(P)url_var:-https://api.anthropic.com}"
        local models="${(P)models_var}"

        echo "  ${C_CYAN}${current} ${C_GREEN}← 当前${C_RESET}"
        echo "    ${C_DARK_GRAY}url:    ${url}${C_RESET}"
        if [[ -n "$models" ]]; then
            echo "    ${C_DARK_GRAY}models: ${models//,/ }${C_RESET}"
        fi

        local presets=()
        local prefix="CC_VENDOR_${upper}_PRESET_"
        for var in ${(Mk)parameters:#${prefix}*_OPUS}; do
            local pname="${var#$prefix}"
            pname="${pname%_OPUS}"
            presets+=("${(L)pname}")
        done
        if [[ ${#presets[@]} -gt 0 ]]; then
            echo "    ${C_DARK_GRAY}presets:${C_CYAN} ${(j:, :)presets}${C_RESET}"
        fi

        local envs=()
        local env_pre="CC_VENDOR_${upper}_ENV_"
        for var in ${(Mko)parameters:#${env_pre}*}; do
            envs+=("${var#$env_pre}=${(P)var}")
        done
        (( ${#envs[@]} > 0 )) && echo "    ${C_DARK_GRAY}env:    ${(j:, :)envs}${C_RESET}"
    fi

    # 其他可用厂商
    local others=()
    for v in "${vendors[@]}"; do
        [[ "$v" == "$current" ]] && continue
        others+=("$v")
    done
    if [[ ${#others[@]} -gt 0 ]]; then
        echo ""
        echo "  ${C_DARK_GRAY}可用:${C_RESET}"
        for v in "${others[@]}"; do
            local upper="${(U)v}"
            local url_var="CC_VENDOR_${upper}_URL"
            local models_var="CC_VENDOR_${upper}_MODELS"
            local url="${(P)url_var:-https://api.anthropic.com}"
            local models="${(P)models_var}"

            echo "    ${C_CYAN}${v}${C_RESET}  ${C_DARK_GRAY}url: ${url}${C_RESET}"
            if [[ -n "$models" ]]; then
                echo "    ${C_DARK_GRAY}      models: ${models//,/ }${C_RESET}"
            fi
        done
    fi
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

    # ----- 清理上次厂商应用的自定义 env -----
    for v in "${CC_ACTIVE_ENV_VARS[@]}"; do
        [[ -n "$v" ]] && unset "$v"
    done
    CC_ACTIVE_ENV_VARS=()

    # 切换厂商会使当前预设的 env 失效
    for v in "${CC_ACTIVE_PRESET_ENV_VARS[@]}"; do
        [[ -n "$v" ]] && unset "$v"
    done
    CC_ACTIVE_PRESET_ENV_VARS=()

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
        _cc_model_apply ${(s:,:)models}
        echo "${C_GREEN}✓ 厂商: ${C_CYAN}${name}${C_GREEN} | 模型: ${models//,/ }${C_RESET}"
    else
        echo "${C_GREEN}✓ 厂商: ${C_CYAN}${name}${C_RESET}"
        echo "${C_DARK_GRAY}  未配置 models，使用 cc model <name> 指定组合${C_RESET}"
    fi

    # ----- 应用厂商自定义 env（vendor.<v>.env.<VAR>=<value>，配了才 export）-----
    local env_prefix="CC_VENDOR_${upper}_ENV_"
    local _env_names=()
    for var in ${(Mko)parameters:#${env_prefix}*}; do
        local real_name="${var#$env_prefix}"
        export "$real_name"="${(P)var}"
        CC_ACTIVE_ENV_VARS+=("$real_name")
        _env_names+=("$real_name=${(P)var}")
    done
    (( ${#_env_names[@]} > 0 )) && echo "${C_DARK_GRAY}  env: ${(j:, :)_env_names}${C_RESET}"
    return 0
}

# ============================================================
# 恢复官方
# ============================================================

_cc_vendor_official() {
    # ----- 清理厂商自定义 env（恢复 Claude 默认）-----
    for v in "${CC_ACTIVE_ENV_VARS[@]}"; do
        [[ -n "$v" ]] && unset "$v"
    done
    CC_ACTIVE_ENV_VARS=()

    # 清理预设自定义 env
    for v in "${CC_ACTIVE_PRESET_ENV_VARS[@]}"; do
        [[ -n "$v" ]] && unset "$v"
    done
    CC_ACTIVE_PRESET_ENV_VARS=()

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

_cc_vendor_help() {
    echo "用法: ${C_GREEN}cc vendor [name]${C_RESET}"
    echo ""
    echo "  ${C_GREEN}cc vendor${C_RESET}         列出当前厂商详情 + 可用厂商"
    echo "  ${C_GREEN}cc vendor <name>${C_RESET}  切换厂商（应用其 models 字段）"
    echo "  ${C_GREEN}cc <name>${C_RESET}         同上（快捷）"
    echo "  ${C_GREEN}cc official${C_RESET}       恢复官方 Anthropic"
    echo ""
    echo "厂商在配置文件中定义: vendor.<name>.url/key/models/env"
}

echo "${C_DARK_GRAY}[cc-vendor] 已加载，可用: ${C_GREEN}cc vendor <name>${C_RESET}"
