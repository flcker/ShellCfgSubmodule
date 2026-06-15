# ============================================================
# cc-tools 配置文件加载器
# ============================================================
# 从 key=value 文本文件加载厂商配置，转为 CC_VENDOR_* 环境变量。
# 零依赖，zsh / PowerShell 通用格式。
#
# 文件格式:
#   vendor.<name>.<field>=<value>
#   models 字段用逗号分隔: opus,sonnet,haiku
#   # 开头的行视为注释
#   auto=<vendor>  启动时自动切换
#
# 优先级: CC_CONFIG_FILE > 默认路径 > CC_VENDOR_* 环境变量
# ============================================================

# ============================================================
# 默认路径
# ============================================================

: ${CC_CONFIG_FILE:="$HOME/.config/cc/vendors.conf"}

# ============================================================
# 加载配置 → 环境变量
# ============================================================

_cc_config_load() {
    local file="$CC_CONFIG_FILE"

    if [[ ! -f "$file" ]]; then
        echo "${C_YELLOW}⚠ 配置文件不存在: ${file}${C_RESET}" >&2
        echo "${C_DARK_GRAY}  可参考示例创建或使用 CC_VENDOR_* 环境变量${C_RESET}"
        return 1
    fi

    # 验证权限：密钥文件不应被其他用户读取
    local perms
    perms=$(stat -f '%p' "$file" 2>/dev/null || stat -c '%a' "$file" 2>/dev/null)
    if [[ "$perms" =~ [0-7][0-7][0-7] ]]; then
        local others="${perms: -1}"
        if [[ "$others" -ne 0 ]]; then
            echo "${C_YELLOW}⚠ 配置文件权限过宽，建议 chmod 600: ${file}${C_RESET}" >&2
        fi
    fi

    local line key value count=0
    while IFS='=' read -r key value; do
        # 跳过空行和注释
        [[ -z "$key" || "$key" == \#* ]] && continue

        # trim
        key="${key##[[:space:]]}"; key="${key%%[[:space:]]}"
        value="${value##[[:space:]]}"; value="${value%%[[:space:]]}"

        # 转环境变量名: vendor.tal.url → CC_VENDOR_TAL_URL
        local env_key="CC_${(U)key//./_}"
        export "$env_key"="$value"
        ((count++))
    done < "$file"

    echo "${C_DARK_GRAY}[cc-config] 从 ${file} 加载 ${count} 项配置${C_RESET}"
    return 0
}

# ============================================================
# 辅助：获取 vendor 字段
# ============================================================

_cc_config_get() {
    local vendor="$1" field="$2"
    local var="CC_VENDOR_${(U)vendor}_${(U)field}"
    echo "${(P)var}"
}

# ============================================================
# 生成默认配置（仅注释，不覆盖已有）
# ============================================================

_cc_config_init() {
    local file="$CC_CONFIG_FILE"

    if [[ -f "$file" ]]; then
        echo "${C_YELLOW}配置文件已存在: ${file}${C_RESET}"
        echo "${C_DARK_GRAY}  如需覆盖请先删除或指定 CC_CONFIG_FILE 为新路径${C_RESET}"
        return 1
    fi

    mkdir -p "$(dirname "$file")"

    cat > "$file" << 'CONFEOF'
# ============================================================
# cc-tools 厂商配置
# ============================================================
# 格式: vendor.<name>.<field>=<value>
#   name   — 厂商简称，即 cc vendor <name> 的参数
#   url    — API 地址（可选，Claude 官方可省略默认走 api.anthropic.com）
#   key    — API 密钥（必需）
#   models — 默认模型，逗号分隔: opus,sonnet,haiku
#            单模型厂商可省略此行，使用内置默认
#            多模型厂商（TAL/火山等）必填
#
# auto = 启动时自动切换的厂商（可选）
# ============================================================

# --- TAL Coding（公司多模型代理）---
#vendor.tal.url=http://ai-service.tal.com/coding
#vendor.tal.key=sk-...
#vendor.tal.models=claude-opus-4.8,deepseek-v4-pro,deepseek-v4-flash

# --- DeepSeek（自购）---
#vendor.ds.url=https://api.deepseek.com
#vendor.ds.key=sk-...

# --- GLM（智谱）---
#vendor.glm.url=https://open.bigmodel.cn/api/paas/v4
#vendor.glm.key=sk-...

# --- Claude 官方 ---
#vendor.claude.key=sk-ant-...

# --- GPT（OpenAI 兼容）---
#vendor.gpt.url=https://api.openai.com/v1
#vendor.gpt.key=sk-...

# --- 火山引擎 ---
#vendor.volc.url=https://ark.cn-beijing.volces.com/api/v3
#vendor.volc.key=sk-...
#vendor.volc.models=deepseek-v4-pro,deepseek-v4-pro,deepseek-v4-flash

# --- 自定义厂商（模板）---
#vendor.xxx.url=https://your-api.example.com
#vendor.xxx.key=sk-...
#vendor.xxx.models=opus-model,sonnet-model,haiku-model

#auto=tal
CONFEOF

    chmod 600 "$file"
    echo "${C_GREEN}✓ 已生成配置模板: ${file}${C_RESET}"
    echo "${C_DARK_GRAY}  请编辑填入实际值后重新打开 shell${C_RESET}"
}

# ============================================================
# 自动加载
# ============================================================

_cc_config_load || true
