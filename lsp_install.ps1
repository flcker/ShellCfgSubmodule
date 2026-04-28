#Requires -Version 7
# lsp_install.ps1 — 读取 lsp_config.json，将 LSP 服务器安装到系统 PATH（Windows）
# 用法: pwsh lsp_install.ps1

param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir "lsp_config.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "lsp_config.json not found: $ConfigPath"
    exit 1
}

$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

function Has-Command($Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$Mgrs = @{
    winget = Has-Command "winget"
    scoop  = Has-Command "scoop"
    npm    = Has-Command "npm"
    pip    = Has-Command "pip" -or (Has-Command "pip3")
    cargo  = Has-Command "cargo"
    go     = Has-Command "go"
    rustup = Has-Command "rustup"
}

$PipCmd = if (Has-Command "pip3") { "pip3" } else { "pip" }

function Install-Via($Mgr, $Pkg) {
    $Cmds = @{
        winget = "winget install --id $Pkg -e"
        scoop  = "scoop install $Pkg"
        npm    = "npm install -g $Pkg"
        pip    = "$PipCmd install --user $Pkg"
        cargo  = "cargo install $Pkg"
        go     = "go install $Pkg"
        rustup = "rustup component add $Pkg"
    }
    $Cmd = $Cmds[$Mgr]
    Write-Host "  `$ $Cmd" -ForegroundColor DarkGray
    Invoke-Expression $Cmd
}

$Results = @()

foreach ($Entry in $Config.servers.PSObject.Properties) {
    $Name   = $Entry.Name
    $Server = $Entry.Value
    $CmdName = $Server.command

    if (Get-Command $CmdName -ErrorAction SilentlyContinue) {
        $Results += [pscustomobject]@{ Status = "✓"; Name = $Name; Note = "already in PATH" }
        continue
    }

    $Install  = $Server.install
    $Priority = $Install.priority
    $Done     = $false

    foreach ($Mgr in $Priority) {
        if ($Mgrs[$Mgr] -and $Install.PSObject.Properties[$Mgr]) {
            $Pkg = $Install.$Mgr
            Write-Host "`n→ Installing $Name via $Mgr…" -ForegroundColor Cyan
            try {
                Install-Via $Mgr $Pkg
                $Results += [pscustomobject]@{ Status = "→"; Name = $Name; Note = "installed via $Mgr" }
            } catch {
                $Results += [pscustomobject]@{ Status = "✗"; Name = $Name; Note = "failed via ${Mgr}: $_" }
            }
            $Done = $true
            break
        }
    }

    if (-not $Done) {
        $Needed = $Priority -join ", "
        $Results += [pscustomobject]@{ Status = "✗"; Name = $Name; Note = "no available installer (need one of: $Needed)" }
    }
}

Write-Host "`n── LSP Install Summary ──────────────────────────────"
foreach ($R in $Results) {
    $Color = switch ($R.Status) {
        "✓" { "Green" }
        "→" { "Cyan"  }
        "✗" { "Red"   }
    }
    Write-Host ("  {0}  {1,-24} {2}" -f $R.Status, $R.Name, $R.Note) -ForegroundColor $Color
}
Write-Host ""
