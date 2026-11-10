#Requires -Version 7
# ============================================================
# lsp.ps1 — LSP 管理统一入口（Windows）
# ============================================================
# 用法:
#   lsp install                    安装所有 LSP 服务器到系统 PATH
#   lsp configure [zed|vscode|all] 应用编辑器配置（默认 all）
#   lsp status                     对比 lsp_config.json 与 PATH 已装项
#   lsp help                       显示帮助
#
# 由主仓 sh/lsp.ps1 source 后提供全局 lsp 命令。
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:LSP_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LSP_CONFIG = Join-Path $script:LSP_DIR "lsp_config.json"

# ── 帮助 ─────────────────────────────────────────────────────
function Show-LspHelp {
    Write-Host ""
    Write-Host "  lsp — LSP 服务器安装与配置管理" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  用法: lsp <command> [args]" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  install                    安装所有 LSP 服务器到系统 PATH" -ForegroundColor Green
    Write-Host "  configure [zed|vscode|all] 应用编辑器配置（默认 all）" -ForegroundColor Green
    Write-Host "  status                     对比配置与 PATH 已装项" -ForegroundColor Green
    Write-Host "  help                       显示本页" -ForegroundColor Green
    Write-Host ""
}

# ── install ──────────────────────────────────────────────────
function Invoke-LspInstall {
    $installer = Join-Path $script:LSP_DIR "lsp_install.ps1"
    if (-not (Test-Path $installer)) {
        Write-Error "lsp_install.ps1 not found: $installer"
        return
    }
    & $installer
}

# ── configure ────────────────────────────────────────────────
function Invoke-LspConfigure {
    param([string]$Target = "all")

    switch ($Target.ToLower()) {
        { $_ -cin @("zed", "vscode", "all") } { break }
        default {
            Write-Warning "未知目标: '$Target'。可用: zed | vscode | all"
            return
        }
    }

    $configurer = Join-Path $script:LSP_DIR "lsp_configure.ps1"
    if (-not (Test-Path $configurer)) {
        Write-Error "lsp_configure.ps1 not found: $configurer"
        return
    }
    & $configurer -Target $Target.ToLower()
}

# ── status ───────────────────────────────────────────────────
function Show-LspStatus {
    if (-not (Test-Path $script:LSP_CONFIG)) {
        Write-Error "lsp_config.json not found: $script:LSP_CONFIG"
        return
    }

    $Config = Get-Content $script:LSP_CONFIG -Raw | ConvertFrom-Json

    Write-Host ""
    Write-Host "  ── LSP 服务器状态 ──" -ForegroundColor Cyan
    Write-Host ""

    $installed = 0
    $total = 0

    foreach ($Entry in $Config.servers.PSObject.Properties) {
        $Name    = $Entry.Name
        $CmdName = $Entry.Value.command
        $total++

        $cmd = Get-Command $CmdName -ErrorAction SilentlyContinue
        if ($cmd) {
            $loc = if ($cmd.Source) { $cmd.Source } else { $cmd.Name }
            Write-Host ("  ✓  {0,-24} {1}" -f $Name, $loc) -ForegroundColor Green
            $installed++
        } else {
            Write-Host ("  ✗  {0,-24} 未安装" -f $Name) -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host ("  {0}/{1} 已安装" -f $installed, $total) -ForegroundColor DarkGray
    Write-Host ""
}

# ── 主入口 ───────────────────────────────────────────────────
function global:lsp {
    param(
        [Parameter(Position = 0)]
        [string]$Sub = "",
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Rest
    )

    if (-not $Rest) { $Rest = @() }

    switch ($Sub) {
        'install' {
            Invoke-LspInstall
        }
        'configure' {
            if ($Rest.Count -ge 1) { Invoke-LspConfigure -Target $Rest[0] }
            else { Invoke-LspConfigure }
        }
        'status' {
            Show-LspStatus
        }
        { $_ -cin @('help', '-h', '--help') } {
            Show-LspHelp
        }
        '' {
            Show-LspHelp
        }
        default {
            Write-Warning "未知子命令: '$Sub'"
            Show-LspHelp
        }
    }
}
