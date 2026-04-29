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
# Zed 内置所有 LSP server 的下载与管理，无需设置 binary 路径。
# 本函数只合并 lsp_config.json 中各 server 的 "zed.initialization_options"。
function Apply-Zed {
    $ZedSettings = "$env:APPDATA\Zed\settings.json"
    if (-not (Test-Path $ZedSettings)) {
        $ZedSettings = "$env:HOME/.config/zed/settings.json"
    }
    if (-not (Test-Path $ZedSettings)) {
        Write-Warning "Zed settings not found: $ZedSettings"
        return
    }

    $Backup = $ZedSettings + ".bak"
    Copy-Item $ZedSettings $Backup

    $Raw     = Get-Content $ZedSettings -Raw
    $Cleaned = $Raw -replace '//[^\n]*', '' -replace ',\s*([}\]])', '$1'

    try {
        $Settings = $Cleaned | ConvertFrom-Json -AsHashtable
    } catch {
        Write-Error "Failed to parse Zed settings: $_"
        return
    }

    if (-not $Settings.ContainsKey("lsp")) { $Settings["lsp"] = @{} }

    $Applied = @()
    foreach ($Entry in $Config.servers.PSObject.Properties) {
        $Name    = $Entry.Name
        $ZedOpts = $Entry.Value.zed
        if ($null -eq $ZedOpts) { continue }
        $InitOpts = $ZedOpts.initialization_options
        if ($null -eq $InitOpts) { continue }

        # Zed 可能用不同命名（如连字符），优先取 zed.name
        $ZedName = if ($ZedOpts.PSObject.Properties["name"]) { $ZedOpts.name } else { $Name }
        if (-not $Settings["lsp"].ContainsKey($ZedName)) { $Settings["lsp"][$ZedName] = @{} }
        $Settings["lsp"][$ZedName]["initialization_options"] = $InitOpts
        $Applied += $ZedName
    }

    $Settings | ConvertTo-Json -Depth 10 | Set-Content $ZedSettings

    if ($Applied.Count -gt 0) {
        Write-Host "✓  Zed: applied initialization_options for: $($Applied -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "✓  Zed: no initialization_options to apply" -ForegroundColor Green
    }
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
