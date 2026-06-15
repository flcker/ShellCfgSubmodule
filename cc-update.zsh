# ============================================================
# Claude Code 更新脚本
# ============================================================
# 下载指定版本的 Claude Code CLI 并更新本地 symlink。
#
# 使用方法:
#   source ~/.config/zsh/submodule/cc-tools/cc-update.zsh
#   cc-update              # 更新到最新版本
#   cc-update 2.1.173      # 更新到指定版本
#   cc-update --rollback   # 回退到上一版本
#   cc-update --list       # 列出已安装版本
#
# 参考: claude-update.md
# ============================================================

# ============================================================
# 统一配置
# ============================================================

: ${CC_DIST_BASE:="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819"}
: ${CC_VERSIONS_DIR:="$HOME/.local/share/claude/versions"}
: ${CC_BIN_DIR:="$HOME/.local/bin"}
: ${CC_BIN_NAME:="claude"}

# ============================================================
# ANSI 颜色
# ============================================================

autoload -U colors && colors
C_DARK_GRAY="$fg[white]"
C_GREEN="$fg[green]"
C_CYAN="$fg[cyan]"
C_YELLOW="$fg[yellow]"
C_RED="$fg[red]"
C_RESET="$reset_color"

# ============================================================
# 平台检测
# ============================================================

_detect_platform() {
    local os arch
    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux)  os="linux"  ;;
        *) echo "${C_RED}✗ 不支持的操作系统: $(uname -s)${C_RESET}" >&2; return 1 ;;
    esac
    case "$(uname -m)" in
        arm64|aarch64) arch="arm64" ;;
        x86_64)        arch="x64"   ;;
        *) echo "${C_RED}✗ 不支持的架构: $(uname -m)${C_RESET}" >&2; return 1 ;;
    esac
    echo "${os}-${arch}"
}

# ============================================================
# 获取最新版本号（从发布清单 / latest 标记）
# ============================================================

_fetch_latest_version() {
    local platform="$1"
    local latest_url="${CC_DIST_BASE}/claude-code-releases/latest"
    local version

    version=$(curl -fsSL "${latest_url}" 2>/dev/null)
    if [[ -z "$version" ]]; then
        echo "${C_RED}✗ 无法获取最新版本号${C_RESET}" >&2
        return 1
    fi
    echo "$version"
}

# ============================================================
# 构建下载 URL
# ============================================================

_build_download_url() {
    local version="$1"
    local platform="$2"
    echo "${CC_DIST_BASE}/claude-code-releases/${version}/${platform}/claude"
}

# ============================================================
# 列出已安装版本
# ============================================================

_list_installed_versions() {
    echo "${C_DARK_GRAY}已安装版本 (${CC_VERSIONS_DIR}):${C_RESET}"
    if [[ ! -d "$CC_VERSIONS_DIR" ]] || [[ -z "$(ls -A "$CC_VERSIONS_DIR" 2>/dev/null)" ]]; then
        echo "  (无)"
        return
    fi
    local current_target
    current_target=$(readlink "${CC_BIN_DIR}/${CC_BIN_NAME}" 2>/dev/null || echo "")
    for f in "$CC_VERSIONS_DIR"/*; do
        local vname="$(basename "$f")"
        local marker=""
        if [[ "$f" == "$current_target" ]]; then
            marker=" ${C_GREEN}← 当前${C_RESET}"
        fi
        echo "  ${C_CYAN}${vname}${marker}${C_RESET}"
    done
}

# ============================================================
# 回退到上一版本
# ============================================================

_rollback() {
    local current_target
    current_target=$(readlink "${CC_BIN_DIR}/${CC_BIN_NAME}" 2>/dev/null || echo "")

    if [[ ! -d "$CC_VERSIONS_DIR" ]] || [[ -z "$(ls -A "$CC_VERSIONS_DIR" 2>/dev/null)" ]]; then
        echo "${C_YELLOW}⚠ 没有已安装的版本可回退${C_RESET}"
        return 1
    fi

    # 收集除当前版本外的所有版本，按版本号降序取第一个
    local candidates=()
    for f in "$CC_VERSIONS_DIR"/*; do
        [[ -f "$f" ]] || continue
        [[ "$f" != "$current_target" ]] && candidates+=("$f")
    done

    if [[ ${#candidates[@]} -eq 0 ]]; then
        echo "${C_YELLOW}⚠ 只有当前一个版本，无法回退${C_RESET}"
        return 1
    fi

    # 按版本号降序排序（统一去掉 claude- 前缀后排序），取最新
    local target target_name
    target=$(
        for f in "${candidates[@]}"; do
            local bn="$(basename "$f")"
            local ver="${bn#claude-}"
            printf '%s\t%s\n' "$ver" "$f"
        done | sort -Vr | head -1 | cut -f2
    )
    target_name="$(basename "$target")"

    echo "${C_DARK_GRAY}回退: $(basename "$current_target") → ${C_CYAN}${target_name}${C_RESET}"
    ln -sf "$target" "${CC_BIN_DIR}/${CC_BIN_NAME}"
    echo "${C_GREEN}✓ 已切换到 ${target_name}${C_RESET}"
}

# ============================================================
# 删除指定版本
# ============================================================

_remove_version() {
    local ver="$1"
    local current_target
    current_target=$(readlink "${CC_BIN_DIR}/${CC_BIN_NAME}" 2>/dev/null || echo "")

    # 解析文件名：支持 claude-2.1.121 和 2.1.121 两种写法
    local target_path
    if [[ -f "${CC_VERSIONS_DIR}/claude-${ver}" ]]; then
        target_path="${CC_VERSIONS_DIR}/claude-${ver}"
    elif [[ -f "${CC_VERSIONS_DIR}/${ver}" ]]; then
        target_path="${CC_VERSIONS_DIR}/${ver}"
    else
        echo "${C_RED}✗ 版本不存在: ${ver}${C_RESET}" >&2
        return 1
    fi

    # 判断是否为当前使用的版本
    if [[ "$target_path" == "$current_target" ]]; then
        # 查找其他已安装版本用于回退
        local candidates=()
        for f in "$CC_VERSIONS_DIR"/*; do
            [[ -f "$f" ]] || continue
            [[ "$f" != "$target_path" ]] && candidates+=("$f")
        done

        if [[ ${#candidates[@]} -gt 0 ]]; then
            echo "${C_YELLOW}⚠ ${ver} 是当前版本，正在回退...${C_RESET}"
            # 按版本号降序取第一个
            local rollback_target rollback_name
            rollback_target=$(
                for f in "${candidates[@]}"; do
                    local bn="$(basename "$f")"
                    local v="${bn#claude-}"
                    printf '%s\t%s\n' "$v" "$f"
                done | sort -Vr | head -1 | cut -f2
            )
            rollback_name="$(basename "$rollback_target")"
            ln -sf "$rollback_target" "${CC_BIN_DIR}/${CC_BIN_NAME}"
            echo "${C_GREEN}✓ 已回退到 ${rollback_name}${C_RESET}"
        else
            echo "${C_YELLOW}⚠ ${ver} 是唯一安装的版本，一并移除 bin${C_RESET}"
            rm -f "${CC_BIN_DIR}/${CC_BIN_NAME}"
            echo "${C_DARK_GRAY}  已删除 ${CC_BIN_NAME}${C_RESET}"
        fi
    fi

    rm -f "$target_path"
    echo "${C_GREEN}✓ 已删除 $(basename "$target_path")${C_RESET}"
}

# ============================================================
# 清理所有旧版本（保留当前）
# ============================================================

_clean_versions() {
    local current_target
    current_target=$(readlink "${CC_BIN_DIR}/${CC_BIN_NAME}" 2>/dev/null || echo "")

    if [[ ! -d "$CC_VERSIONS_DIR" ]] || [[ -z "$(ls -A "$CC_VERSIONS_DIR" 2>/dev/null)" ]]; then
        echo "${C_YELLOW}⚠ 没有已安装的版本${C_RESET}"
        return 0
    fi

    local to_delete=()
    for f in "$CC_VERSIONS_DIR"/*; do
        [[ -f "$f" ]] || continue
        [[ "$f" != "$current_target" ]] && to_delete+=("$f")
    done

    if [[ ${#to_delete[@]} -eq 0 ]]; then
        echo "${C_DARK_GRAY}没有可清理的旧版本${C_RESET}"
        return 0
    fi

    local freed=0
    for f in "${to_delete[@]}"; do
        local size
        size=$(du -h "$f" 2>/dev/null | cut -f1)
        rm -f "$f" && ((freed++))
        echo "${C_DARK_GRAY}  删除: $(basename "$f") (${size})${C_RESET}"
    done

    echo "${C_GREEN}✓ 已清理 ${freed} 个旧版本，当前保留: $(basename "$current_target")${C_RESET}"
}

cc-update() {
    # ----- 确保目录存在 -----
    mkdir -p "$CC_VERSIONS_DIR" "$CC_BIN_DIR"

    # ----- 子命令分发 -----
    case "${1:-}" in
        --list|-l)
            _list_installed_versions
            return 0
            ;;
        --rollback|-r)
            _rollback
            return $?
            ;;
        --remove|-rm)
            if [[ -z "${2:-}" ]]; then
                echo "${C_RED}✗ 用法: cc-update --remove <版本号>${C_RESET}" >&2
                return 1
            fi
            _remove_version "$2"
            return $?
            ;;
        --clean|-c)
            _clean_versions
            return $?
            ;;
        --latest|-L)
            local platform
            platform=$(_detect_platform) || return 1
            echo "${C_DARK_GRAY}正在获取最新版本...${C_RESET}"
            local latest
            latest=$(_fetch_latest_version) || return 1
            echo "${C_GREEN}最新版本: ${C_CYAN}${latest}${C_RESET}"
            return 0
            ;;
        --help|-h)
            echo "用法: ${C_GREEN}cc-update${C_RESET} [版本号|--latest|-L|--rollback|-r|--remove|-rm|--clean|-c|--list|-l]"
            echo ""
            echo "  ${C_DARK_GRAY}# 更新${C_RESET}"
            echo "    ${C_GREEN}cc-update${C_RESET}               更新到最新版本"
            echo "    ${C_GREEN}cc-update 2.1.173${C_RESET}       更新到指定版本"
            echo ""
            echo "  ${C_DARK_GRAY}# 查询${C_RESET}"
            echo "    ${C_GREEN}--latest|-L${C_RESET}             查看最新版本号"
            echo "    ${C_GREEN}--list|-l${C_RESET}              列出已安装版本"
            echo ""
            echo "  ${C_DARK_GRAY}# 管理${C_RESET}"
            echo "    ${C_GREEN}--rollback|-r${C_RESET}          回退到上一版本"
            echo "    ${C_GREEN}--remove|-rm <ver>${C_RESET}     删除指定版本"
            echo "    ${C_GREEN}--clean|-c${C_RESET}             清理旧版本（保留当前）"
            return 0
            ;;
    esac

    # ----- 平台检测 -----
    local platform
    platform=$(_detect_platform) || return 1

    # ----- 确定版本 -----
    local version="${1:-}"
    if [[ -z "$version" ]]; then
        echo "${C_DARK_GRAY}正在获取最新版本...${C_RESET}"
        version=$(_fetch_latest_version) || return 1
    fi

    local target_path="${CC_VERSIONS_DIR}/claude-${version}"
    local download_url
    download_url=$(_build_download_url "$version" "$platform")

    # ----- 已是最新？-----
    local current_target
    current_target=$(readlink "${CC_BIN_DIR}/${CC_BIN_NAME}" 2>/dev/null || echo "")
    if [[ -f "$target_path" ]] && [[ "$target_path" == "$current_target" ]]; then
        echo "${C_GREEN}✓ 已是最新版本 ${C_CYAN}${version}${C_RESET}"
        return 0
    fi

    # ----- 版本已存在？-----
    if [[ -f "$target_path" ]]; then
        echo "${C_DARK_GRAY}版本 ${C_CYAN}${version}${C_DARK_GRAY} 已下载，直接切换...${C_RESET}"
    else
        # ----- 下载 -----
        echo "${C_DARK_GRAY}下载中 ${download_url}${C_RESET}"

        if ! curl -fsSL -o "$target_path" "$download_url"; then
            echo "${C_RED}✗ 下载失败${C_RESET}" >&2
            rm -f "$target_path"
            return 1
        fi

        # ----- 校验（检查是否为有效二进制）-----
        chmod +x "$target_path"
        if ! file "$target_path" 2>/dev/null | grep -qE 'executable|Mach-O|ELF'; then
            echo "${C_RED}✗ 下载的文件不是有效二进制${C_RESET}" >&2
            rm -f "$target_path"
            return 1
        fi

        # ----- 完整性检查（试运行 --version）-----
        if ! "$target_path" --version >/dev/null 2>&1; then
            echo "${C_RED}✗ 下载的文件无法运行（可能损坏或不完整）${C_RESET}" >&2
            rm -f "$target_path"
            return 1
        fi

        echo "${C_GREEN}✓ 下载完成 (${target_path})${C_RESET}"
    fi

    # ----- 创建/更新 symlink -----
    ln -sf "$target_path" "${CC_BIN_DIR}/${CC_BIN_NAME}"

    if [[ -n "$current_target" ]] && [[ "$current_target" != "$target_path" ]]; then
        echo "${C_DARK_GRAY}切换: $(basename "$current_target") → ${C_CYAN}claude-${version}${C_RESET}"
    fi
    echo "${C_GREEN}✓ Claude Code ${version} (${platform}) 已就绪${C_RESET}"
}

# ============================================================
# 启动提示
# ============================================================

echo "${C_DARK_GRAY}[cc-update] 已加载，可用: ${C_GREEN}cc-update [版本|--latest|-L|--rollback|-r|--remove|-rm|--clean|-c|--list|-l]${C_RESET}"
