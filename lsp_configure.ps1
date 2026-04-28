#Requires -Version 7
# lsp_configure.ps1 — 应用各编辑器的 LSP 配置（Zed / VSCode，Windows）
# 用法: pwsh lsp_configure.ps1 [-Target zed|vscode|all]

param(
    [string]$Target = "all"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir "lsp_config.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "lsp_config.json not found: $ConfigPath"
    exit 1
}

$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

function Has-Command($Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── Zed ──────────────────────────────────────────────────────
function Apply-Zed {
    $ZedSettings = "$env:APPDATA\Zed\settings.json"
    if (-not (Test-Path $ZedSettings)) {
        # macOS/Linux 路径备用
        $ZedSettings = "$env:HOME/.config/zed/settings.json"
    }
    if (-not (Test-Path $ZedSettings)) {
        Write-Warning "Zed settings not found: $ZedSettings"
        return
    }

    $Backup = $ZedSettings + ".bak"
    Copy-Item $ZedSettings $Backup

    # 检测 clangd 路径
    $ClangdPath = (Get-Command "clangd" -ErrorAction SilentlyContinue)?.Source ?? ""

    # 读取并解析（去除注释和尾随逗号）
    $Raw = Get-Content $ZedSettings -Raw
    $Cleaned = $Raw -replace '//[^\n]*', '' -replace ',\s*([}\]])', '$1'

    try {
        $Settings = $Cleaned | ConvertFrom-Json -AsHashtable
    } catch {
        Write-Error "Failed to parse Zed settings: $_"
        return
    }

    if (-not $Settings.ContainsKey("lsp")) { $Settings["lsp"] = @{} }
    $Settings["lsp"]["clangd"] = @{ binary = @{ path = $ClangdPath } }

    $Settings | ConvertTo-Json -Depth 10 | Set-Content $ZedSettings
    Write-Host "✓  Zed: clangd path set to '$ClangdPath'" -ForegroundColor Green
    Write-Host "   (backup: $Backup)" -ForegroundColor DarkGray
}

# ── VSCode ────────────────────────────────────────────────────
function Apply-Vscode {
    if (-not (Has-Command "code")) {
        Write-Warning "VSCode CLI (code) not found — skipping"
        return
    }

    $Extensions = $Config.vscode_extensions
    Write-Host "`n── VSCode Extensions ────────────────────────────────"

    foreach ($Ext in $Extensions) {
        $Result = & code --install-extension $Ext --force 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓  $Ext" -ForegroundColor Green
        } else {
            Write-Host "  ✗  $Ext — $Result" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# ── 入口 ─────────────────────────────────────────────────────
switch ($Target.ToLower()) {
    "zed"    { Apply-Zed }
    "vscode" { Apply-Vscode }
    "all"    {
        Write-Host "── Configuring Zed ──────────────────────────────────"
        try { Apply-Zed } catch { Write-Warning "Zed config failed: $_" }
        Apply-Vscode
    }
    default {
        Write-Error "用法: lsp_configure.ps1 [-Target zed|vscode|all]"
        exit 1
    }
}
