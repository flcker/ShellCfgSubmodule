# LSP 管理子模块

跨平台、多编辑器的 LSP（Language Server Protocol）服务器安装与配置管理。

## 概述

本模块是 [ShellCfgSubmodule](https://github.com/flcker/ShellCfgSubmodule) 的 `lsp` 分支，被主仓库 `~/.config/zsh` 以子模块形式引用于 `submodule/lsp/`。

**设计原则**：
- `lsp_config.json` 是唯一数据源，声明所有 LSP 服务器的安装方式和编辑器配置
- `lsp_install.*` 负责将服务器安装到**系统级 PATH**，供所有工具共用
- `lsp_configure.*` 负责为各编辑器（Zed、VSCode）应用配置
- nvim 通过 `submodule/nvim/lua/lsp.lua` 单独管理（mason.nvim），与本目录协同

## 支持的 LSP 服务器

| 语言 | Server | 命令 | 安装方式 |
|------|--------|------|---------|
| TypeScript / JavaScript | tsserver | `typescript-language-server` | npm |
| Python | pyright | `pyright-langserver` | npm / pip |
| Rust | rust_analyzer | `rust-analyzer` | rustup / brew / apt / winget |
| C / C++ | clangd | `clangd` | brew (llvm) / apt / pacman / winget |
| Go | gopls | `gopls` | go install |
| Lua | lua_ls | `lua-language-server` | brew / apt / winget |

## 快速开始

### macOS / Linux

```bash
# 安装 LSP 服务器到系统 PATH
bash ~/.config/zsh/submodule/lsp/lsp_install.sh

# 应用编辑器配置（Zed + VSCode）
bash ~/.config/zsh/submodule/lsp/lsp_configure.sh

# 单独配置某个编辑器
bash ~/.config/zsh/submodule/lsp/lsp_configure.sh zed
bash ~/.config/zsh/submodule/lsp/lsp_configure.sh vscode
```

### Windows (PowerShell 7)

```powershell
# 安装 LSP 服务器
pwsh ~/.config/zsh/submodule/lsp/lsp_install.ps1

# 应用编辑器配置
pwsh ~/.config/zsh/submodule/lsp/lsp_configure.ps1
pwsh ~/.config/zsh/submodule/lsp/lsp_configure.ps1 -Target zed
pwsh ~/.config/zsh/submodule/lsp/lsp_configure.ps1 -Target vscode
```

## 脚本说明

### `lsp_install.sh` / `lsp_install.ps1`

**职责**：读取 `lsp_config.json`，将 LSP 服务器安装到系统 PATH。

- 自动检测可用的包管理器（brew、apt、npm、cargo、go 等）
- 按 `priority` 字段顺序选择安装方式
- 已在 PATH 中的服务器跳过（`✓`），安装中（`→`），无可用安装器（`✗`）
- 特殊处理：`brew install llvm` 安装 clangd 后自动建 symlink

**安装位置**（系统级，所有编辑器共用）：

| 包管理器 | 安装目录 |
|---------|---------|
| brew | `/opt/homebrew/bin/` |
| apt | `/usr/bin/` |
| npm global | `$(npm prefix -g)/bin/` |
| cargo | `~/.cargo/bin/` |
| go install | `~/go/bin/` |
| winget | 系统 PATH |

### `lsp_configure.sh` / `lsp_configure.ps1`

**职责**：将编辑器配置应用到各工具的配置文件。

- `zed`：合并 `lsp` 字段到 `~/.config/zed/settings.json`（修改前自动备份）
  - 为 clangd 指定实际安装路径（`which clangd`）
- `vscode`：通过 `code --install-extension` 安装推荐扩展列表
  - 依赖 `code` 命令行工具可用
- `all`（默认）：按顺序执行以上全部

## 编辑器集成

### Neovim

通过 `~/.config/zsh/submodule/nvim/lua/lsp.lua` 集成：
- mason.nvim 自动安装缺失的 LSP server（在 `~/.local/share/nvim/mason/bin/`）
- 优先使用系统 PATH 中的服务器（由本模块的 `lsp_install.sh` 安装）
- `vim.fn.executable()` 运行时检查，避免因服务器缺失而报错

### Zed

Zed 自动检测系统 PATH，运行 `lsp_install.sh` 后无需额外操作。
`lsp_configure.sh zed` 会为 clangd 显式指定 binary 路径（brew 安装 llvm 时必要）。

### VSCode

通过扩展内置 LSP，`lsp_configure.sh vscode` 安装推荐扩展即可。

### AI 编程工具（Claude Code / opencode / Copilot 等）

运行 `lsp_install.sh` 后 LSP 服务器在系统 PATH 中，AI 工具无需额外配置即可调用。

## 扩展：添加新语言

在 `lsp_config.json` 的 `servers` 对象中追加新条目：

```json
"bash_ls": {
  "command": "bash-language-server",
  "languageIds": ["shellscript"],
  "install": {
    "npm": "bash-language-server",
    "priority": ["npm"]
  }
}
```

同步更新 `vscode_extensions`，然后在 nvim 的 `lsp.lua` 的 server 列表中也追加 `"bash_ls"`。
