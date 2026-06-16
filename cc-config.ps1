# ============================================================
# cc-tools 配置文件加载器 (PowerShell)
# ============================================================

if (-not (Test-Path Variable:script:C_DARK_GRAY)) {
    $script:C_DARK_GRAY = "`e[37m"
    $script:C_GREEN     = "`e[32m"
    $script:C_CYAN      = "`e[36m"
    $script:C_YELLOW    = "`e[33m"
    $script:C_RED       = "`e[31m"
    $script:C_RESET     = "`e[0m"
}

if (-not (Test-Path Env:CC_CONFIG_FILE)) {
    $env:CC_CONFIG_FILE = "$HOME/.config/cc-tools/cc-tools.conf"
}

# ============================================================
# 加载配置
# ============================================================

function Import-CCConfig {
    $file = $env:CC_CONFIG_FILE
    if (-not (Test-Path $file)) {
        Write-Host "${C_YELLOW}⚠ 配置文件不存在: ${file}${C_RESET}"
        Write-Host "${C_DARK_GRAY}  使用 cc config init 生成模板${C_RESET}"
        return
    }
    $count = 0
    Get-Content $file | Where-Object { $_ -notmatch '^\s*(#|$)' } | ForEach-Object {
        $k, $v = $_ -split '=', 2
        $k = $k.Trim(); $v = $v.Trim()
        $envKey = 'CC_' + $k.Replace('.','_').ToUpper()
        Set-Item -Path "Env:$envKey" -Value $v -ErrorAction SilentlyContinue
        $count++
    }
    Write-Host "${C_DARK_GRAY}[cc-config] 从 ${file} 加载 ${count} 项配置${C_RESET}"
}

# ============================================================
# 生成配置
# ============================================================

function Set-CCConfigInit {
    $file = $env:CC_CONFIG_FILE
    $template = Join-Path $PSScriptRoot 'template.conf'
    if (-not (Test-Path $template)) {
        Write-Host "${C_RED}✗ 模板文件不存在: ${template}${C_RESET}"
        return
    }
    if (Test-Path $file) {
        $bak = "$file.bak"
        Copy-Item $file $bak
        Write-Host "${C_YELLOW}已备份: ${bak}${C_RESET}"
    }
    $null = New-Item -ItemType Directory -Force -Path (Split-Path $file)
    Copy-Item $template $file
    Write-Host "${C_GREEN}✓ 已从 ${template} 生成: ${file}${C_RESET}"
    Write-Host "${C_DARK_GRAY}  请编辑填入实际值后执行 cc config reload${C_RESET}"
}

# ============================================================
# 重载
# ============================================================

function Set-CCConfigReload {
    Write-Host "${C_DARK_GRAY}正在重载配置...${C_RESET}"
    Import-CCConfig
}

# ============================================================
# 帮助
# ============================================================

function Show-CCConfigHelp {
    Write-Host "用法: ${C_GREEN}cc config <action>${C_RESET}"
    Write-Host ""
    Write-Host "  ${C_GREEN}cc config init${C_RESET}     从模板生成配置文件（已有则备份）"
    Write-Host "  ${C_GREEN}cc config reload${C_RESET}   重载配置文件"
    Write-Host ""
    Write-Host "配置文件: ${C_DARK_GRAY}$env:CC_CONFIG_FILE${C_RESET}"
}

# ============================================================
# 启动加载
# ============================================================

Import-CCConfig
