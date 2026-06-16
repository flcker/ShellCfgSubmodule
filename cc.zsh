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
source "${_CC_DIR}/cc-config.zsh"
source "${_CC_DIR}/cc-model-switch.zsh"
source "${_CC_DIR}/cc-vendor-switch.zsh"
source "${_CC_DIR}/cc-update.zsh"

# 启动自动切换（配置文件 auto 字段）
if [[ -n "$CC_AUTO" ]]; then
    _cc_vendor_switch "$CC_AUTO"
fi

# ----- 帮助 ------------------------------------------------------

_cc_help() {
    echo "${C_DARK_GRAY}══ ${C_GREEN}cc${C_RESET} — Claude Code 统一入口 ${C_DARK_GRAY}══${C_RESET}"
    echo ""
    echo "  ${C_DARK_GRAY}厂商${C_RESET}"
    echo "    ${C_GREEN}cc config init${C_RESET}       生成默认配置文件"
    echo "    ${C_GREEN}cc vendor${C_RESET}           列出已配置厂商"
    echo "    ${C_GREEN}cc vendor <name>${C_RESET}    切换厂商（自动应用默认模型）"
    echo ""
    echo "  ${C_DARK_GRAY}模型${C_RESET}"
    echo "    ${C_GREEN}cc${C_RESET}                 显示当前厂商 + 模型 + 预设列表"
    echo "    ${C_GREEN}cc model${C_RESET}             同上（显式）"
    echo "    ${C_GREEN}cc model <name>${C_RESET}        切换预设"
    echo "    ${C_GREEN}cc model <o> <s> <h>${C_RESET}       Opus/Sonnet/Haiku"
    echo "    ${C_GREEN}cc model <o> <s> <h> <c>${C_RESET}   Opus/Sonnet/Haiku/Current"
    echo ""
    echo "  ${C_DARK_GRAY}快捷${C_RESET}"
    echo "    ${C_GREEN}cc <vendor>${C_RESET}     cc vendor 别名（依赖配置）"
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
        # 厂商（也作为 cc <vendor> 快捷）
        vendor)
            shift
            if [[ -z "${1:-}" ]]; then
                _cc_vendor_list
            else
                _cc_vendor_switch "$1"
            fi
            ;;

        # 配置
        config)
            shift
            case "${1:-}" in
                init)
                    _cc_config_init
                    ;;
                reload)
                    _cc_config_reload
                    ;;
                *)
                    echo "${C_DARK_GRAY}用法: ${C_GREEN}cc config init${C_RESET}    — 生成默认配置文件${C_RESET}"
                    echo "${C_DARK_GRAY}      ${C_GREEN}cc config reload${C_RESET} — 重载配置文件${C_RESET}"
                    ;;
            esac
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
                _cc_model_apply "$1" "$2" "$3" "${4:-}"
                echo "${C_GREEN}✓ 模型: ${C_CYAN}${1} ${2} ${3}${4:+ current=${4}}${C_RESET}"
            elif [[ -n "${2:-}" ]]; then
                echo "${C_RED}✗ 用法: cc model <name> 或 cc model <opus> <sonnet> <haiku> [current]${C_RESET}" >&2
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
            # 尝试作为厂商名快捷切换
            if _cc_vendor_switch "$sub"; then
                return 0
            fi
            echo "${C_DARK_GRAY}可用: config, vendor, model, official, update, help${C_RESET}"
            echo "${C_DARK_GRAY}      cc <vendor> — 快捷切换厂商${C_RESET}"
            return 1
            ;;
    esac
}
