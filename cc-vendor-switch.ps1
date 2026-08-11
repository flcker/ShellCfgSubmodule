# ============================================================
# Claude Code 厂商切换 (PowerShell v2)
# ============================================================

if (-not (Test-Path Variable:script:C_DARK_GRAY)) {
    $script:C_DARK_GRAY = "`e[37m"
    $script:C_GREEN     = "`e[32m"
    $script:C_CYAN      = "`e[36m"
    $script:C_YELLOW    = "`e[33m"
    $script:C_RED       = "`e[31m"
    $script:C_RESET     = "`e[0m"
}

# 全局追踪数组：记录当前已应用的厂商自定义 env 变量名（vendor.<v>.env.<VAR>）
# 切换厂商 / cc official 时据此 unset，恢复 Claude 默认行为
if (-not (Test-Path Variable:Global:CC_ACTIVE_ENV_VARS)) {
    $global:CC_ACTIVE_ENV_VARS = @()
}
# 全局追踪数组：记录当前已应用的预设自定义 env 变量名（vendor.<v>.preset.<p>.env.<VAR>）
# 切换预设 / 厂商 / cc official 时据此 unset
if (-not (Test-Path Variable:Global:CC_ACTIVE_PRESET_ENV_VARS)) {
    $global:CC_ACTIVE_PRESET_ENV_VARS = @()
}

# ============================================================
# 列出厂商
# ============================================================

function Get-CCVendor {
    $current = $env:CC_CURRENT_VENDOR
    $vendors = @()
    Get-ChildItem Env: | Where-Object { $_.Name -match '^CC_VENDOR_.*_KEY$' } | ForEach-Object {
        $vendors += ($_.Name -replace '^CC_VENDOR_', '' -replace '_KEY$', '').ToLower()
    }
    if ($vendors.Count -eq 0) {
        Write-Host "${C_DARK_GRAY}(未配置任何厂商)${C_RESET}"
        return
    }

    # 当前厂商优先
    if ($current -and $vendors -contains $current) {
        $u = $current.ToUpper()
        $url = (Get-Item "Env:CC_VENDOR_${u}_URL" -ErrorAction SilentlyContinue).Value
        if (-not $url) { $url = 'https://api.anthropic.com' }
        $models = (Get-Item "Env:CC_VENDOR_${u}_MODELS" -ErrorAction SilentlyContinue).Value

        Write-Host "  ${C_CYAN}${current} ${C_GREEN}← 当前${C_RESET}"
        Write-Host "    ${C_DARK_GRAY}url:    ${url}${C_RESET}"
        if ($models) {
            Write-Host "    ${C_DARK_GRAY}models: $($models -replace ',',' ')${C_RESET}"
        }

        $presets = @()
        Get-ChildItem Env: | Where-Object { $_.Name -match "^CC_VENDOR_${u}_PRESET_.*_OPUS$" } | ForEach-Object {
            $presets += ($_.Name -replace "^CC_VENDOR_${u}_PRESET_", '' -replace '_OPUS$', '').ToLower()
        }
        if ($presets.Count -gt 0) {
            Write-Host "    ${C_DARK_GRAY}presets:${C_CYAN} $($presets -join ', ')${C_RESET}"
        }

        $envs = @()
        $envPre = "CC_VENDOR_${u}_ENV_"
        Get-ChildItem Env: | Where-Object { $_.Name -like "${envPre}*" } | ForEach-Object {
            $envs += "$($_.Name.Substring($envPre.Length))=$($_.Value)"
        }
        if ($envs.Count -gt 0) {
            Write-Host "    ${C_DARK_GRAY}env:    $($envs -join ', ')${C_RESET}"
        }
    }

    # 其他厂商
    $others = $vendors | Where-Object { $_ -ne $current }
    if ($others.Count -gt 0) {
        Write-Host ""
        Write-Host "  ${C_DARK_GRAY}可用:${C_RESET}"
        foreach ($v in $others) {
            $u = $v.ToUpper()
            $url = (Get-Item "Env:CC_VENDOR_${u}_URL" -ErrorAction SilentlyContinue).Value
            if (-not $url) { $url = 'https://api.anthropic.com' }
            $models = (Get-Item "Env:CC_VENDOR_${u}_MODELS" -ErrorAction SilentlyContinue).Value
            Write-Host "    ${C_CYAN}${v}${C_RESET}  ${C_DARK_GRAY}url: ${url}${C_RESET}"
            if ($models) {
                Write-Host "    ${C_DARK_GRAY}      models: $($models -replace ',',' ')${C_RESET}"
            }
        }
    }
}

# ============================================================
# 切换厂商
# ============================================================

function Switch-CCVendor {
    param([string]$Name)
    $u = $Name.ToUpper()
    $key = (Get-Item "Env:CC_VENDOR_${u}_KEY" -ErrorAction SilentlyContinue).Value
    if (-not $key) {
        Write-Host "${C_RED}✗ 厂商未配置: ${Name}（缺少 CC_VENDOR_${u}_KEY）${C_RESET}"
        return $false
    }

    # ----- 清理上次厂商应用的自定义 env -----
    foreach ($v in $global:CC_ACTIVE_ENV_VARS) {
        if ($v) { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }
    }
    $global:CC_ACTIVE_ENV_VARS = @()

    # 切换厂商会使当前预设的 env 失效
    foreach ($v in $global:CC_ACTIVE_PRESET_ENV_VARS) {
        if ($v) { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }
    }
    $global:CC_ACTIVE_PRESET_ENV_VARS = @()

    $url = (Get-Item "Env:CC_VENDOR_${u}_URL" -ErrorAction SilentlyContinue).Value
    if ($url) { $env:ANTHROPIC_BASE_URL = $url }
    $env:ANTHROPIC_AUTH_TOKEN = $key
    $env:CC_CURRENT_VENDOR = $Name

    if (-not (Test-Path Env:CC_MODEL_DISABLE_EXPERIMENTAL_BETAS)) {
        $env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = '1'
    }
    if (-not (Test-Path Env:CC_MODEL_ATTRIBUTION_HEADER)) {
        $env:CLAUDE_CODE_ATTRIBUTION_HEADER = 'false'
    }

    $models = (Get-Item "Env:CC_VENDOR_${u}_MODELS" -ErrorAction SilentlyContinue).Value
    if ($models) {
        $parts = $models -split ','
        Set-CCModelApply -Opus $parts[0] -Sonnet $parts[1] -Haiku $parts[2]
        Write-Host "${C_GREEN}✓ 厂商: ${C_CYAN}${Name}${C_GREEN} | 模型: $($models -replace ',',' ')${C_RESET}"
    } else {
        Write-Host "${C_GREEN}✓ 厂商: ${C_CYAN}${Name}${C_RESET}"
        Write-Host "${C_DARK_GRAY}  未配置 models，使用 cc model <name> 指定组合${C_RESET}"
    }

    # ----- 应用厂商自定义 env（vendor.<v>.env.<VAR>=<value>，配了才 export）-----
    $envPrefix = "CC_VENDOR_${u}_ENV_"
    $envNames = @()
    Get-ChildItem Env: | Where-Object { $_.Name -like "${envPrefix}*" } | ForEach-Object {
        $realName = $_.Name.Substring($envPrefix.Length)
        Set-Item -Path "Env:$realName" -Value $_.Value
        $global:CC_ACTIVE_ENV_VARS += $realName
        $envNames += "${realName}=$($_.Value)"
    }
    if ($envNames.Count -gt 0) {
        Write-Host "${C_DARK_GRAY}  env: $($envNames -join ', ')${C_RESET}"
    }
    return $true
}

# ============================================================
# 恢复官方
# ============================================================

function Reset-CCVendorOfficial {
    # ----- 清理厂商自定义 env（恢复 Claude 默认）-----
    foreach ($v in $global:CC_ACTIVE_ENV_VARS) {
        if ($v) { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }
    }
    $global:CC_ACTIVE_ENV_VARS = @()

    # 清理预设自定义 env
    foreach ($v in $global:CC_ACTIVE_PRESET_ENV_VARS) {
        if ($v) { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }
    }
    $global:CC_ACTIVE_PRESET_ENV_VARS = @()

    $vars = @(
        'ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_MODEL',
        'ANTHROPIC_DEFAULT_SONNET_MODEL', 'ANTHROPIC_DEFAULT_OPUS_MODEL', 'ANTHROPIC_DEFAULT_HAIKU_MODEL',
        'CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS', 'CLAUDE_CODE_ATTRIBUTION_HEADER',
        'CLAUDE_CODE_EFFORT_LEVEL', 'CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING',
        'CC_CURRENT_VENDOR'
    )
    foreach ($v in $vars) {
        Remove-Item "Env:$v" -ErrorAction SilentlyContinue
    }
    Write-Host "${C_GREEN}✓ 已恢复官方 Anthropic Claude${C_RESET}"
}

# ============================================================
# 帮助
# ============================================================

function Show-CCVendorHelp {
    Write-Host "用法: ${C_GREEN}cc vendor [name]${C_RESET}"
    Write-Host ""
    Write-Host "  ${C_GREEN}cc vendor${C_RESET}         列出当前厂商详情 + 可用厂商"
    Write-Host "  ${C_GREEN}cc vendor <name>${C_RESET}  切换厂商（应用其 models 字段）"
    Write-Host "  ${C_GREEN}cc <name>${C_RESET}         同上（快捷）"
    Write-Host "  ${C_GREEN}cc official${C_RESET}       恢复官方 Anthropic"
    Write-Host ""
    Write-Host "厂商在配置文件中定义: vendor.<name>.url/key/models/env"
}

Write-Host "${C_DARK_GRAY}[cc-vendor] 已加载，可用: ${C_GREEN}cc vendor <name>${C_RESET}"
