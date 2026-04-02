# nvim

基于 Lua 的模块化 Neovim 配置，使用 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件。

## 目录结构

```
nvim/
├── init.lua              # 主配置文件（基础选项、模块自动加载）
└── lua/
    ├── plugins.lua       # 插件管理与配置
    ├── keymap.lua        # 快捷键映射
    └── colortheme.lua    # 配色主题
```

## 插件

| 插件 | 说明 |
|------|------|
| [nvim-tree/nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | 文件树浏览器 |
| [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | 状态栏美化 |
| [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | 代码补全引擎 |
| [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 语法高亮与代码解析 |
| [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | 文件类型图标 |
| [plasticboy/vim-markdown](https://github.com/preservim/vim-markdown) | Markdown 语法支持 |

首次启动时 lazy.nvim 会自动下载并安装以上插件。

## 快捷键

Leader 键为 `Space`（空格）。

| 快捷键 | 说明 |
|--------|------|
| `<leader>w` | 保存文件 |
| `<leader>q` | 退出 |
| `<leader>wq` | 保存并退出 |
| `<leader>e` | 切换文件树 |
| `<leader>sv` | 垂直分割窗口 |
| `<leader>sh` | 水平分割窗口 |
| `<leader>nh` | 取消搜索高亮 |
| `<leader>h` / `<leader>←` | 跳转到左侧窗口 |
| `<leader>j` / `<leader>↓` | 跳转到下方窗口 |
| `<leader>k` / `<leader>↑` | 跳转到上方窗口 |
| `<leader>l` / `<leader>→` | 跳转到右侧窗口 |

> 使用方式：先按 `Space` 松开，再按对应键（默认超时 1000ms）。

## 基础配置

| 配置项 | 值 |
|--------|----|
| 编码 | UTF-8 |
| 行号 | 绝对行号 |
| 缩进 | 4 个空格，Tab 转空格，智能缩进 |
| 搜索 | 高亮匹配、实时匹配、忽略大小写（含关键字时自动区分） |
| 外观 | 24 位真彩色、高亮当前行、全局状态栏 |
| 剪贴板 | 与系统剪贴板共享（`unnamedplus`） |
| 鼠标 | 全模式启用 |

## 配色主题

`colortheme.lua` 中定义了 3 套配色方案，当前使用 **OneDark**：

| 名称 | 背景色 | 风格 |
|------|--------|------|
| Base（Catppuccin 风格） | `#1e1e2e` | 紫蓝色系 |
| **OneDark**（当前） | `#121212` | 深色现代风 |
| OneMonokai | `#272822` | Monokai 经典 |

如需切换主题，修改 `colortheme.lua` 第 46 行的 `usingColortheme` 变量即可。
