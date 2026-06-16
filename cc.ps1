# ============================================================
# Claude Code 统一入口 (PowerShell v2)
# ============================================================
# 使用方法: . ~/.config/zsh/submodule/cc-tools/cc.ps1
#
#   cc                    显示当前状态
#   cc vendor [name]      切换厂商 / 列出厂商
#   cc model [name|o s h] 切换模型 / 显示当前
#   cc config init|reload 配置管理
#   cc official           恢复官方默认
#   cc update ...         版本管理
#   cc help [module]      帮助
# ============================================================

$script:_CC_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $_CC_DIR 'cc-config.ps1')
. (Join-Path $_CC_DIR 'cc-model-switch.ps1')
. (Join-Path $_CC_DIR 'cc-vendor-switch.ps1')
. (Join-Path $_CC_DIR 'cc-update.ps1')

# 启动自动切换（格式: vendor 或 vendor:preset）
if ($env:CC_AUTO) {
    $parts = $env:CC_AUTO -split ':', 2
    if (Switch-CCVendor $parts[0]) {
        if ($parts[1]) { Switch-CCModel $parts[1] }
    }
}

# ============================================================
# 帮助入口
# ============================================================

function Show-CCHelp {
    Write-Host "${C_DARK_GRAY}══ ${C_GREEN}cc${C_RESET} — Claude Code 统一入口 ${C_DARK_GRAY}══${C_RESET}"
    Write-Host ""
    Write-Host "  ${C_DARK_GRAY}用法:${C_RESET} cc <command> [args]"
    Write-Host ""
    Write-Host "  ${C_GREEN}config${C_RESET}    配置管理    ${C_DARK_GRAY}cc help config${C_RESET}"
    Write-Host "  ${C_GREEN}vendor${C_RESET}    厂商切换    ${C_DARK_GRAY}cc help vendor${C_RESET}"
    Write-Host "  ${C_GREEN}model${C_RESET}     模型选择    ${C_DARK_GRAY}cc help model${C_RESET}"
    Write-Host "  ${C_GREEN}update${C_RESET}    版本管理    ${C_DARK_GRAY}cc help update${C_RESET}"
    Write-Host "  ${C_GREEN}official${C_RESET}  恢复官方"
    Write-Host ""
    Write-Host "  ${C_DARK_GRAY}cc <vendor>${C_RESET}       快捷切换厂商"
    Write-Host "  ${C_DARK_GRAY}cc${C_RESET}                显示当前状态"
    Write-Host "  ${C_DARK_GRAY}cc help${C_RESET}           显示本页"
}

# ============================================================
# 主入口
# ============================================================

function global:cc {
    param(
        [Parameter(Position = 0)]
        [string]$Sub,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Rest
    )

    # 无剩余参数时 $Rest 为 $null，统一为空数组避免索引报错
    if (-not $Rest) { $Rest = @() }

    switch ($Sub) {
        'vendor' {
            if (-not $Rest) { Get-CCVendor }
            else { Switch-CCVendor $Rest[0] }
        }
        'model' {
            if (-not $Rest) { Show-CCModel }
            elseif ($Rest.Count -eq 1) { Switch-CCModel $Rest[0] }
            elseif ($Rest.Count -ge 3) {
                Set-CCModelApply -Opus $Rest[0] -Sonnet $Rest[1] -Haiku $Rest[2] -Current $Rest[3]
                $msg = "✓ 模型: $($Rest[0]) $($Rest[1]) $($Rest[2])"
                if ($Rest[3]) { $msg += " current=$($Rest[3])" }
                Write-Host "${C_GREEN}${msg}${C_RESET}"
            }
            else {
                Write-Host "${C_RED}✗ 用法: cc model <name> 或 cc model <o> <s> <h> [current]${C_RESET}"
            }
        }
        'config' {
            switch ($Rest[0]) {
                'init'   { Set-CCConfigInit }
                'reload' { Set-CCConfigReload }
                default  {
                    Write-Host "${C_DARK_GRAY}用法: ${C_GREEN}cc config init${C_RESET}    — 生成默认配置文件${C_RESET}"
                    Write-Host "${C_DARK_GRAY}      ${C_GREEN}cc config reload${C_RESET} — 重载配置文件${C_RESET}"
                }
            }
        }
        'official' {
            Reset-CCVendorOfficial
        }
        'help' {
            switch ($Rest[0]) {
                'config' { Show-CCConfigHelp }
                'vendor' { Show-CCVendorHelp }
                'model'  { Show-CCModelHelp }
                'update' { Invoke-CCUpdate -Help }
                default  { Show-CCHelp }
            }
        }
        'update' {
            $params = @{}
            $i = 0
            while ($i -lt $Rest.Count) {
                switch ($Rest[$i]) {
                    { $_ -in @('--list', '-l') }     { $params['List'] = $true }
                    { $_ -in @('--rollback', '-r') }  { $params['Rollback'] = $true }
                    { $_ -in @('--remove', '-rm') }   { if (++$i -lt $Rest.Count) { $params['Remove'] = $Rest[$i] } }
                    { $_ -in @('--clean', '-c') }     { $params['Clean'] = $true }
                    { $_ -in @('--latest', '-L') }     { $params['Latest'] = $true }
                    { $_ -in @('--help', '-h') }       { $params['Help'] = $true }
                    default { $params['Version'] = $Rest[$i] }
                }
                $i++
            }
            Invoke-CCUpdate @params
        }
        '' { Show-CCModel }
        default {
            if (Switch-CCVendor $Sub) { return }
            Write-Host "${C_DARK_GRAY}可用: config, vendor, model, official, update, help${C_RESET}"
            Write-Host "${C_DARK_GRAY}      cc <vendor> — 快捷切换厂商${C_RESET}"
        }
    }
}
