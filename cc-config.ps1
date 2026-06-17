# ============================================================
# cc-tools 配置文件加载器 (PowerShell)
# ============================================================
# 从 key=value 文本文件加载厂商配置，转为 CC_VENDOR_* 环境变量。
# 零依赖，zsh / PowerShell 通用格式。
#
# 文件格式:
#   vendor.<name>.<field>=<value>
#   models 字段用逗号分隔: opus,sonnet,haiku
#   # 开头的行视为注释
#   auto=<vendor>[:<preset>]  启动时自动切换
#
# 优先级: CC_CONFIG_FILE > ~/.config/cc-tools/cc-tools.conf

if (-not (Test-Path Variable:script:C_DARK_GRAY)) {
    $script:C_DARK_GRAY = "`e[37m"
    $script:C_GREEN     = "`e[32m"
    $script:C_CYAN      = "`e[36m"
    $script:C_YELLOW    = "`e[33m"
    $script:C_RED       = "`e[31m"
    $script:C_RESET     = "`e[0m"
}

# 捕获脚本目录，供函数内部使用（函数调用时 $PSScriptRoot 可能为空）
$script:CC_CONFIG_DIR = $PSScriptRoot

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
    $template = Join-Path $script:CC_CONFIG_DIR 'template.conf'
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
