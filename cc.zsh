# ============================================================
# Claude Code 统一入口（TAL Token Plan）
# ============================================================
# 使用方法: source ~/.config/zsh/submodule/cc-tools/cc.zsh
#
#   cc                    显示当前状态
#   cc ds|deepseek        切换到 DeepSeek 系列
#   cc glm                切换到 GLM 系列
#   cc claude             切换到 Claude 官方系列
#   cc gpt                切换到 GPT 系列
#   cc official           恢复 Claude 官方默认
#   cc update [ver]       更新 Claude Code 二进制
#   cc update --rollback  回退到上一版本
#   cc update --list      列出已安装版本
#   cc help               显示帮助
# ============================================================

# ----- 载入子模块 -------------------------------------------------
_CC_DIR="${0:A:h}"
source "${_CC_DIR}/cc-model-switch.zsh"
source "${_CC_DIR}/cc-update.zsh"

# ----- 帮助 ------------------------------------------------------

_cc_help() {
    echo "${C_DARK_GRAY}══ ${C_GREEN}cc${C_RESET} — Claude Code 统一入口 ${C_DARK_GRAY}══${C_RESET}"
    echo ""
    echo "  ${C_DARK_GRAY}状态${C_RESET}"
    echo "    ${C_GREEN}cc${C_RESET}          显示当前状态"
    echo "    ${C_GREEN}cc model${C_RESET}    显示当前模型配置"
    echo ""
    echo "  ${C_DARK_GRAY}模型切换${C_RESET}"
    echo "    ${C_GREEN}cc ds|deepseek${C_RESET} 切换到 DeepSeek"
    echo "    ${C_GREEN}cc glm${C_RESET}         切换到 GLM"
    echo "    ${C_GREEN}cc claude${C_RESET}      切换到 Claude"
    echo "    ${C_GREEN}cc gpt${C_RESET}         切换到 GPT"
    echo "    ${C_GREEN}cc official${C_RESET}    恢复官方默认"
    echo ""
    echo "  ${C_DARK_GRAY}更新管理${C_RESET}"
    echo "    ${C_GREEN}cc update${C_RESET}                  更新到最新版本"
    echo "    ${C_GREEN}cc update <ver>${C_RESET}            更新到指定版本"
    echo "    ${C_GREEN}cc update --latest|-L${C_RESET}      查看最新版本号"
    echo "    ${C_GREEN}cc update --rollback|-r${C_RESET}    回退到上一版本"
    echo "    ${C_GREEN}cc update --remove|-rm <ver>${C_RESET} 删除指定版本"
    echo "    ${C_GREEN}cc update --clean|-c${C_RESET}       清理旧版本（保留当前）"
    echo "    ${C_GREEN}cc update --list|-l${C_RESET}        列出已安装版本"
}

# ----- 主入口 ------------------------------------------------------

cc() {
    local sub="${1:-}"

    case "$sub" in
        # 模型切换
        ds|deepseek)
            switch-deepseek
            ;;
        glm)
            switch-glm
            ;;
        claude)
            switch-claude
            ;;
        gpt)
            switch-gpt
            ;;
        official)
            restore-claude-official
            ;;

        # 状态
        model)
            show-current-model
            ;;

        # 更新
        update)
            shift
            cc-update "$@"
            ;;

        # 帮助
        help|-h|--help)
            _cc_help
            ;;

        # 默认显示状态
        "")
            show-current-model
            ;;

        *)
            echo "${C_RED}✗ 未知子命令: ${sub}${C_RESET}" >&2
            echo "${C_DARK_GRAY}可用: ds|deepseek, glm, claude, gpt, official, model, update, help${C_RESET}"
            return 1
            ;;
    esac
}
