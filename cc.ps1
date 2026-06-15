# ============================================================
# Claude Code 统一入口 (PowerShell)
# ============================================================
# 使用方法: . ~/.config/zsh/submodule/cc-tools/cc.ps1
#
#   cc             显示当前状态
#   cc model       显示当前模型配置
#   cc ds|deepseek     切换到 DeepSeek 系列
#   cc glm             切换到 GLM 系列
#   cc claude          切换到 Claude 官方系列
#   cc gpt             切换到 GPT 系列
#   cc official        恢复 Claude 官方默认
#   cc update [ver]        更新到指定/最新版本
#   cc update --latest|-L  查看最新版本号
#   cc update --rollback|-r 回退到上一版本
#   cc update --remove|-rm <ver> 删除指定版本
#   cc update --clean|-c   清理所有旧版本
#   cc update --list|-l    列出已安装版本
#   cc help|-h|--help      显示帮助
# ============================================================

# ----- 载入子模块 -------------------------------------------------
$script:_CC_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $_CC_DIR "cc-model-switch.ps1")
. (Join-Path $_CC_DIR "cc-update.ps1")

# ----- 帮助 ------------------------------------------------------

function Show-CCHelp {
    Write-Host "${C_DARK_GRAY}══ ${C_GREEN}cc${C_RESET} — Claude Code 统一入口 ${C_DARK_GRAY}══${C_RESET}"
    Write-Host ""
    Write-Host "  ${C_DARK_GRAY}状态${C_RESET}"
    Write-Host "    ${C_GREEN}cc${C_RESET}          显示当前状态"
    Write-Host "    ${C_GREEN}cc model${C_RESET}    显示当前模型配置"
    Write-Host ""
    Write-Host "  ${C_DARK_GRAY}模型切换${C_RESET}"
    Write-Host "    ${C_GREEN}cc ds|deepseek${C_RESET} 切换到 DeepSeek"
    Write-Host "    ${C_GREEN}cc glm${C_RESET}         切换到 GLM"
    Write-Host "    ${C_GREEN}cc claude${C_RESET}      切换到 Claude"
    Write-Host "    ${C_GREEN}cc gpt${C_RESET}         切换到 GPT"
    Write-Host "    ${C_GREEN}cc official${C_RESET}    恢复官方默认"
    Write-Host ""
    Write-Host "  ${C_DARK_GRAY}更新管理${C_RESET}"
    Write-Host "    ${C_GREEN}cc update${C_RESET}                  更新到最新版本"
    Write-Host "    ${C_GREEN}cc update <ver>${C_RESET}            更新到指定版本"
    Write-Host "    ${C_GREEN}cc update --latest|-L${C_RESET}      查看最新版本号"
    Write-Host "    ${C_GREEN}cc update --rollback|-r${C_RESET}    回退到上一版本"
    Write-Host "    ${C_GREEN}cc update --remove|-rm <ver>${C_RESET} 删除指定版本"
    Write-Host "    ${C_GREEN}cc update --clean|-c${C_RESET}       清理旧版本（保留当前）"
    Write-Host "    ${C_GREEN}cc update --list|-l${C_RESET}        列出已安装版本"
}

# ============================================================
# cc update 参数映射
# ============================================================

function Invoke-CCUpdateCommand {
    param([string[]]$CmdArgs)

    $params = @{}
    $i = 0
    while ($i -lt $CmdArgs.Count) {
        switch ($CmdArgs[$i]) {
            { $_ -in @('--list', '-l') } {
                $params['List'] = $true
            }
            { $_ -in @('--rollback', '-r') } {
                $params['Rollback'] = $true
            }
            { $_ -in @('--remove', '-rm') } {
                if ($i + 1 -lt $CmdArgs.Count) {
                    $params['Remove'] = $CmdArgs[++$i]
                } else {
                    Write-Host "${C_RED}✗ 用法: cc update --remove <版本号>${C_RESET}"
                    return
                }
            }
            { $_ -in @('--clean', '-c') } {
                $params['Clean'] = $true
            }
            { $_ -in @('--latest', '-L') } {
                $params['Latest'] = $true
            }
            { $_ -in @('--help', '-h') } {
                $params['Help'] = $true
            }
            default {
                # 作为版本号
                $params['Version'] = $CmdArgs[$i]
            }
        }
        $i++
    }

    Invoke-CCUpdate @params
}

# ----- 主入口 ------------------------------------------------------

function cc {
    param(
        [Parameter(Position = 0)]
        [string]$Sub,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Rest
    )

    switch ($Sub) {
        # 模型切换
        'ds'       { Invoke-SwitchDeepSeek }
        'deepseek' { Invoke-SwitchDeepSeek }
        'glm'      { Invoke-SwitchGLM }
        'claude'   { Invoke-SwitchClaude }
        'gpt'      { Invoke-SwitchGPT }
        'official' { Invoke-RestoreClaudeOfficial }

        # 状态
        'model'    { Show-CCModel }

        # 更新
        'update'   { Invoke-CCUpdateCommand -CmdArgs $Rest }

        # 帮助
        { $_ -in @('help', '-h', '--help') } { Show-CCHelp }

        # 默认显示状态
        ''         { Show-CCModel }

        default {
            Write-Host "${C_RED}✗ 未知子命令: ${Sub}${C_RESET}"
            Write-Host "${C_DARK_GRAY}可用: ds|deepseek, glm, claude, gpt, official, model, update, help${C_RESET}"
        }
    }
}
