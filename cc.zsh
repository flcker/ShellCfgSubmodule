# ============================================================
# Claude Code 统一入口（TAL Token Plan）
# ============================================================
# 使用方法: source ~/.config/zsh/submodule/cc-tools/cc.zsh
#
#   cc                    显示当前状态
#   cc vendor [name]      切换厂商 / 列出厂商
#   cc model [name|o s h] 切换模型 / 显示当前
#   cc ds|glm|claude|gpt  快捷全栈切换
#   cc official           恢复官方默认
#   cc update ...         版本管理
#   cc help               显示帮助
# ============================================================

# ----- 载入子模块 -------------------------------------------------
_CC_DIR="${0:A:h}"
source "${_CC_DIR}/cc-model-switch.zsh"
source "${_CC_DIR}/cc-vendor-switch.zsh"
source "${_CC_DIR}/cc-update.zsh"

# ----- 帮助 ------------------------------------------------------

_cc_help() {
    echo "${C_DARK_GRAY}══ ${C_GREEN}cc${C_RESET} — Claude Code 统一入口 ${C_DARK_GRAY}══${C_RESET}"
    echo ""
    echo "  ${C_DARK_GRAY}厂商${C_RESET}"
    echo "    ${C_GREEN}cc vendor${C_RESET}           列出已配置厂商"
    echo "    ${C_GREEN}cc vendor <name>${C_RESET}    切换厂商（自动应用默认模型）"
    echo ""
    echo "  ${C_DARK_GRAY}模型${C_RESET}"
    echo "    ${C_GREEN}cc${C_RESET}                 显示当前厂商 + 模型 + API"
    echo "    ${C_GREEN}cc model${C_RESET}             同上（显式）"
    echo "    ${C_GREEN}cc model ds|glm|claude|gpt${C_RESET} 快捷切换"
    echo "    ${C_GREEN}cc model <o> <s> <h>${C_RESET}       分别指定 Opus/Sonnet/Haiku"
    echo ""
    echo "  ${C_DARK_GRAY}快捷${C_RESET}"
    echo "    ${C_GREEN}cc ds|deepseek${C_RESET}  厂商 + 全栈 DeepSeek"
    echo "    ${C_GREEN}cc glm${C_RESET}          厂商 + 全栈 GLM"
    echo "    ${C_GREEN}cc claude${C_RESET}       厂商 + 全栈 Claude"
    echo "    ${C_GREEN}cc gpt${C_RESET}          厂商 + 全栈 GPT"
    echo "    ${C_GREEN}cc official${C_RESET}     恢复官方 Anthropic"
    echo ""
    echo "  ${C_DARK_GRAY}更新管理${C_RESET}"
    echo "    ${C_GREEN}cc update${C_RESET}                  更新到最新版本"
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
        # 快捷全栈（v2: vendor + model / v1: 老函数兼容）
        ds|deepseek)
            if [[ -n "$CC_VENDOR_DS_KEY" ]]; then
                _cc_vendor_switch ds
            else
                switch-deepseek
            fi
            ;;
        glm)
            if [[ -n "$CC_VENDOR_GLM_KEY" ]]; then
                _cc_vendor_switch glm
            else
                switch-glm
            fi
            ;;
        claude)
            if [[ -n "$CC_VENDOR_CLAUDE_KEY" ]]; then
                _cc_vendor_switch claude
            else
                switch-claude
            fi
            ;;
        gpt)
            if [[ -n "$CC_VENDOR_GPT_KEY" ]]; then
                _cc_vendor_switch gpt
            else
                switch-gpt
            fi
            ;;

        # 厂商
        vendor)
            shift
            if [[ -z "${1:-}" ]]; then
                _cc_vendor_list
            else
                _cc_vendor_switch "$1"
            fi
            ;;

        # 恢复官方
        official)
            _cc_vendor_official
            ;;

        # 模型
        model)
            shift
            if [[ -z "${1:-}" ]]; then
                _cc_model_display
            elif [[ -n "${3:-}" ]]; then
                _cc_model_apply "$1" "$2" "$3"
                echo "${C_GREEN}✓ 模型: ${C_CYAN}${1} ${2} ${3}${C_RESET}"
            elif [[ -n "${2:-}" ]]; then
                echo "${C_RED}✗ 用法: cc model <name> 或 cc model <opus> <sonnet> <haiku>${C_RESET}" >&2
                return 1
            else
                _cc_model_switch "$1"
            fi
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
            _cc_model_display
            ;;

        *)
            echo "${C_RED}✗ 未知子命令: ${sub}${C_RESET}" >&2
            echo "${C_DARK_GRAY}可用: vendor, model, ds|glm|claude|gpt, official, update, help${C_RESET}"
            return 1
            ;;
    esac
}
