# ============================================================
# Claude Code 多模型切换脚本 (PowerShell)
# ============================================================
# 通过环境变量切换 Claude Code 使用的 AI 模型。
# 支持 Opus / Sonnet / Haiku 三个级别分别映射不同模型。
#
# 使用方法:
#   1. 在 $PROFILE 中配置代理凭证（二选一，按优先级）：
#      a) 推荐：仅暴露鉴权 header，地址仍走官方
#         $env:CC_MODEL_API_KEY = "sk-..."
#      b) 全量代理（使用自建 API 网关）：
#         $env:CC_MODEL_BASE_URL = "http://your-proxy.com/coding"
#         $env:CC_MODEL_API_KEY = "sk-..."
#
#   2. . ~/.config/zsh/submodule/cc-tools/cc.ps1
#      （或单独 dot-source cc-model-switch.ps1）
#
# 注意：凭证存入 $PROFILE 后可通过 git 同步脚本本身，不会暴露密钥。
# ============================================================

# ============================================================
# 统一配置（可在 $PROFILE 中覆盖）
# ============================================================

if (-not (Test-Path Env:CC_MODEL_BASE_URL)) { $env:CC_MODEL_BASE_URL = "" }
if (-not (Test-Path Env:CC_MODEL_API_KEY))   { $env:CC_MODEL_API_KEY = "" }
if (-not (Test-Path Env:CC_MODEL_DISABLE_EXPERIMENTAL_BETAS)) { $env:CC_MODEL_DISABLE_EXPERIMENTAL_BETAS = "1" }
if (-not (Test-Path Env:CC_MODEL_ATTRIBUTION_HEADER)) { $env:CC_MODEL_ATTRIBUTION_HEADER = "false" }

# ============================================================
# ANSI 颜色
# ============================================================

$script:C_DARK_GRAY = "`e[37m"
$script:C_GREEN     = "`e[32m"
$script:C_CYAN      = "`e[36m"
$script:C_YELLOW    = "`e[33m"
$script:C_RED       = "`e[31m"
$script:C_RESET     = "`e[0m"

# ============================================================
# 内部辅助函数
# ============================================================

function Set-ClaudeModelEnv {
    param(
        [string]$SonnetModel,
        [string]$OpusModel,
        [string]$HaikuModel,
        [bool]$EnableEffort = $false
    )

    # 允许仅设置 API key（地址走官方），也支持全量代理
    if ($env:CC_MODEL_BASE_URL) {
        $env:ANTHROPIC_BASE_URL = $env:CC_MODEL_BASE_URL
    }
    if ($env:CC_MODEL_API_KEY) {
        $env:ANTHROPIC_AUTH_TOKEN = $env:CC_MODEL_API_KEY
    }

    $env:ANTHROPIC_MODEL                  = $OpusModel
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL   = $SonnetModel
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL     = $OpusModel
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL    = $HaikuModel
    $env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = $env:CC_MODEL_DISABLE_EXPERIMENTAL_BETAS
    $env:CLAUDE_CODE_ATTRIBUTION_HEADER         = $env:CC_MODEL_ATTRIBUTION_HEADER

    if ($EnableEffort) {
        $env:CLAUDE_CODE_EFFORT_LEVEL          = "max"
        $env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1"
    } else {
        Remove-Item Env:CLAUDE_CODE_EFFORT_LEVEL -ErrorAction SilentlyContinue
        Remove-Item Env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING -ErrorAction SilentlyContinue
    }
}

# ============================================================
# DeepSeek 系列
#   Opus/Sonnet -> deepseek-v4-pro    Haiku -> deepseek-v4-flash
# ============================================================

function Invoke-SwitchDeepSeek {
    param([switch]$NoEffort)
    $enableEffort = -not $NoEffort
    Set-ClaudeModelEnv -SonnetModel "deepseek-v4-pro" -OpusModel "deepseek-v4-pro" -HaikuModel "deepseek-v4-flash" -EnableEffort $enableEffort
    Write-Host "${C_GREEN}✓ DeepSeek | Opus/Sonnet: deepseek-v4-pro | Haiku: deepseek-v4-flash${C_RESET}"
}

# ============================================================
# GLM 系列
#   Opus/Sonnet -> glm-5.1    Haiku -> glm-4.7
# ============================================================

function Invoke-SwitchGLM {
    param([switch]$NoEffort)
    $enableEffort = -not $NoEffort
    Set-ClaudeModelEnv -SonnetModel "glm-5.1" -OpusModel "glm-5.1" -HaikuModel "glm-4.7" -EnableEffort $enableEffort
    Write-Host "${C_GREEN}✓ GLM | Opus/Sonnet: glm-5.1 | Haiku: glm-4.7${C_RESET}"
}

# ============================================================
# Claude 官方系列
#   Opus -> claude-opus-4.8    Sonnet -> claude-sonnet-4.6    Haiku -> claude-haiku-4.5
# ============================================================

function Invoke-SwitchClaude {
    Set-ClaudeModelEnv -SonnetModel "claude-sonnet-4.6" -OpusModel "claude-opus-4.8" -HaikuModel "claude-haiku-4.5" -EnableEffort $false
    Write-Host "${C_GREEN}✓ Claude | Opus: claude-opus-4.8 | Sonnet: claude-sonnet-4.6 | Haiku: claude-haiku-4.5${C_RESET}"
}

# ============================================================
# GPT 系列
#   Opus/Sonnet -> gpt-5.3-codex    Haiku -> gpt-5.2-codex
# ============================================================

function Invoke-SwitchGPT {
    param([switch]$NoEffort)
    $enableEffort = -not $NoEffort
    Set-ClaudeModelEnv -SonnetModel "gpt-5.3-codex" -OpusModel "gpt-5.3-codex" -HaikuModel "gpt-5.2-codex" -EnableEffort $enableEffort
    Write-Host "${C_GREEN}✓ GPT | Opus/Sonnet: gpt-5.3-codex | Haiku: gpt-5.2-codex${C_RESET}"
}

# ============================================================
# 恢复官方
# ============================================================

function Invoke-RestoreClaudeOfficial {
    $vars = @(
        "ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_MODEL",
        "ANTHROPIC_DEFAULT_SONNET_MODEL", "ANTHROPIC_DEFAULT_OPUS_MODEL", "ANTHROPIC_DEFAULT_HAIKU_MODEL",
        "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS", "CLAUDE_CODE_ATTRIBUTION_HEADER",
        "CLAUDE_CODE_EFFORT_LEVEL", "CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING"
    )
    foreach ($v in $vars) {
        Remove-Item Env:$v -ErrorAction SilentlyContinue
    }
    Write-Host "${C_GREEN}✓ 已恢复官方 Anthropic Claude${C_RESET}"
}

# ============================================================
# 状态显示
# ============================================================

function Show-CCModel {
    $opus   = if ($env:ANTHROPIC_DEFAULT_OPUS_MODEL)   { $env:ANTHROPIC_DEFAULT_OPUS_MODEL }   else { "claude-opus (官方)" }
    $sonnet = if ($env:ANTHROPIC_DEFAULT_SONNET_MODEL) { $env:ANTHROPIC_DEFAULT_SONNET_MODEL } else { "claude-sonnet (官方)" }
    $haiku  = if ($env:ANTHROPIC_DEFAULT_HAIKU_MODEL)  { $env:ANTHROPIC_DEFAULT_HAIKU_MODEL }  else { "claude-haiku (官方)" }
    $url    = if ($env:ANTHROPIC_BASE_URL) { $env:ANTHROPIC_BASE_URL } else { "https://api.anthropic.com" }

    Write-Host "${C_DARK_GRAY}[Opus]:   ${C_CYAN}${opus}${C_DARK_GRAY}`t [Sonnet]: ${C_CYAN}${sonnet}${C_DARK_GRAY}`t [Haiku]:  ${C_CYAN}${haiku}${C_RESET}"
    Write-Host "${C_DARK_GRAY}[API]:    ${url}${C_RESET}"
}

# ============================================================
# 别名
# ============================================================

Set-Alias -Name cc2ds       -Value Invoke-SwitchDeepSeek       -Scope Global
Set-Alias -Name cc2glm      -Value Invoke-SwitchGLM            -Scope Global
Set-Alias -Name cc2claude   -Value Invoke-SwitchClaude         -Scope Global
Set-Alias -Name cc2gpt      -Value Invoke-SwitchGPT            -Scope Global
Set-Alias -Name cc2official -Value Invoke-RestoreClaudeOfficial -Scope Global
Set-Alias -Name ccmodel     -Value Show-CCModel                -Scope Global

# ============================================================
# 启动提示 & 默认切换到 DeepSeek
# ============================================================

Write-Host "${C_DARK_GRAY}[cc-tools] 已加载，可用: ${C_GREEN}cc2ds / cc2glm / cc2claude / cc2gpt / cc2official / ccmodel${C_RESET}"

if ($env:CC_MODEL_API_KEY) {
    Invoke-SwitchDeepSeek
} else {
    Write-Host "${C_YELLOW}⚠ 未配置 `$env:CC_MODEL_API_KEY，跳过自动切换${C_RESET}"
    Write-Host "${C_DARK_GRAY}  请在 `$PROFILE 中添加:${C_RESET}"
    Write-Host "${C_DARK_GRAY}    `$env:CC_MODEL_API_KEY = `"sk-...`"${C_RESET}"
    Write-Host "${C_DARK_GRAY}    `$env:CC_MODEL_BASE_URL = `"http://...`"  # 可选${C_RESET}"
}
