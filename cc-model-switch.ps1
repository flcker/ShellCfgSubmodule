# ============================================================
# Claude Code 模型预设 (PowerShell v2)
# ============================================================

if (-not (Test-Path Variable:script:C_DARK_GRAY)) {
    $script:C_DARK_GRAY = "`e[37m"
    $script:C_GREEN     = "`e[32m"
    $script:C_CYAN      = "`e[36m"
    $script:C_YELLOW    = "`e[33m"
    $script:C_RED       = "`e[31m"
    $script:C_RESET     = "`e[0m"
}

# ============================================================
# 应用模型
# ============================================================

function Set-CCModelApply {
    param(
        [string]$Opus,
        [string]$Sonnet,
        [string]$Haiku,
        [string]$Current
    )
    if (-not $Current) { $Current = $Opus }

    $env:ANTHROPIC_MODEL                = $Current
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL   = $Opus
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = $Sonnet
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL  = $Haiku

    if ($Current -like 'claude-opus-*') {
        Remove-Item Env:CLAUDE_CODE_EFFORT_LEVEL          -ErrorAction SilentlyContinue
        Remove-Item Env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING -ErrorAction SilentlyContinue
    } else {
        $env:CLAUDE_CODE_EFFORT_LEVEL          = 'max'
        $env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = '1'
    }
}

# ============================================================
# 切换预设（仅查配置）
# ============================================================

function Switch-CCModel {
    param([string]$Name)
    $vendor = $env:CC_CURRENT_VENDOR
    if (-not $vendor) {
        Write-Host "${C_RED}✗ 未选择厂商，请先 cc vendor <name>${C_RESET}"
        return $false
    }
    $vUpper = $vendor.ToUpper()
    $nUpper = $Name.ToUpper()

    $opus   = (Get-Item "Env:CC_VENDOR_${vUpper}_PRESET_${nUpper}_OPUS"   -ErrorAction SilentlyContinue).Value
    $sonnet = (Get-Item "Env:CC_VENDOR_${vUpper}_PRESET_${nUpper}_SONNET" -ErrorAction SilentlyContinue).Value
    $haiku  = (Get-Item "Env:CC_VENDOR_${vUpper}_PRESET_${nUpper}_HAIKU"  -ErrorAction SilentlyContinue).Value
    if ($opus -and $sonnet -and $haiku) {
        $current = (Get-Item "Env:CC_VENDOR_${vUpper}_PRESET_${nUpper}_CURRENT" -ErrorAction SilentlyContinue).Value
        Set-CCModelApply -Opus $opus -Sonnet $sonnet -Haiku $haiku -Current $current
        Write-Host "${C_GREEN}✓ 预设: ${C_CYAN}${Name}${C_DARK_GRAY} → ${opus}, ${sonnet}, ${haiku}${C_RESET}"
        return $true
    }

    Write-Host "${C_RED}✗ 未知预设: ${Name}${C_RESET}"
    Write-Host "${C_DARK_GRAY}  在配置文件添加: vendor.${vendor}.preset.${Name}.opus/sonnet/haiku${C_RESET}"
    return $false
}

# ============================================================
# 显示状态
# ============================================================

function Show-CCModel {
    $current = if ($env:ANTHROPIC_MODEL) { $env:ANTHROPIC_MODEL }
               elseif ($env:ANTHROPIC_DEFAULT_OPUS_MODEL) { $env:ANTHROPIC_DEFAULT_OPUS_MODEL }
               else { 'claude-opus (官方)' }
    $opus   = if ($env:ANTHROPIC_DEFAULT_OPUS_MODEL)   { $env:ANTHROPIC_DEFAULT_OPUS_MODEL }   else { 'claude-opus (官方)' }
    $sonnet = if ($env:ANTHROPIC_DEFAULT_SONNET_MODEL) { $env:ANTHROPIC_DEFAULT_SONNET_MODEL } else { 'claude-sonnet (官方)' }
    $haiku  = if ($env:ANTHROPIC_DEFAULT_HAIKU_MODEL)  { $env:ANTHROPIC_DEFAULT_HAIKU_MODEL }  else { 'claude-haiku (官方)' }
    $url    = if ($env:ANTHROPIC_BASE_URL) { $env:ANTHROPIC_BASE_URL } else { 'https://api.anthropic.com' }

    if ($env:CC_CURRENT_VENDOR) {
        Write-Host "${C_DARK_GRAY}[Vendor]:  ${C_CYAN}$env:CC_CURRENT_VENDOR${C_RESET}"
    }
    Write-Host "${C_DARK_GRAY}[Current]: ${C_CYAN}${current}${C_RESET}"
    Write-Host "${C_DARK_GRAY}[Opus]:    ${C_CYAN}${opus}${C_DARK_GRAY}`t [Sonnet]: ${C_CYAN}${sonnet}${C_DARK_GRAY}`t [Haiku]:  ${C_CYAN}${haiku}${C_RESET}"
    Write-Host "${C_DARK_GRAY}[API]:     ${url}${C_RESET}"

    # 预设列表
    $vendor = $env:CC_CURRENT_VENDOR
    if ($vendor) {
        $vUpper = $vendor.ToUpper()
        $presets = @()
        Get-ChildItem Env: | Where-Object { $_.Name -match "^CC_VENDOR_${vUpper}_PRESET_.*_OPUS$" } | ForEach-Object {
            $presets += ($_.Name -replace "^CC_VENDOR_${vUpper}_PRESET_", '' -replace '_OPUS$', '').ToLower()
        }
        if ($presets.Count -gt 0) {
            Write-Host "${C_DARK_GRAY}[Presets]: ${C_CYAN}$($presets -join ', ')${C_RESET}"
        }
    }
}

# ============================================================
# 帮助
# ============================================================

function Show-CCModelHelp {
    Write-Host "用法: ${C_GREEN}cc model [name|o s h [c]]${C_RESET}"
    Write-Host ""
    Write-Host "  ${C_GREEN}cc model${C_RESET}              显示 [Vendor] [Current] [Opus] [Sonnet] [Haiku] [Presets]"
    Write-Host "  ${C_GREEN}cc model <name>${C_RESET}       切换预设（查 vendor.<v>.preset.<name>.*）"
    Write-Host "  ${C_GREEN}cc model <o> <s> <h>${C_RESET}     自定义 Opus/Sonnet/Haiku"
    Write-Host "  ${C_GREEN}cc model <o> <s> <h> <c>${C_RESET} 自定义 Opus/Sonnet/Haiku/Current"
    Write-Host ""
    Write-Host "预设定义在配置文件中: vendor.<v>.preset.<name>.opus/sonnet/haiku"
}

Write-Host "${C_DARK_GRAY}[cc-tools] 已加载${C_RESET}"
