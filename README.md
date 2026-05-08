# starshipauto

动态 Starship 配置生成器。将 format/palette/modules 解耦为独立数据文件，通过 Python 脚本生成所有 layout × palette 组合的最终 `.toml` 配置。

## 快速开始

```bash
# 生成所有配置（首次使用或修改数据文件后）
python generate.py

# PowerShell — 自动集成到 ssc 命令
# (starship.ps1 会自动检测并加载本模块)

# bash/zsh — 在 .bashrc/.zshrc 中添加:
source /path/to/starshipauto/engines/sh/starship-auto.sh
eval "$(starship init bash)"  # 或 zsh
```

## 命名规则

文件命名遵循 `{layout}_{separator}_{head/tail}_{palette}` 格式，参考 Powerlevel10k 术语：

| 字段 | 含义 | 取值 |
|------|------|------|
| layout | 布局类型 | `pl`(powerline), `lean` |
| separator | 段间分隔符 | `angled`, `round`, `slanted`, `none` |
| head/tail | 起止帽样式 | `sharp`, `round`, `none` |
| palette | 配色方案 | `rainbow`, `classic`, `lean` |

不存在的组件补 `none`。

### 当前 layouts

| 文件名 | 分隔符 | 头/尾 | 说明 |
|--------|--------|-------|------|
| `pl_angled_sharp` | Angled  | Sharp  | 纯箭头（无起止帽） |
| `pl_round_round` | Round  | Round  | 纯圆角 |
| `pl_slanted_none` | Slanted  | Flat | 纯斜线（无起止帽） |
| `pl_angled_round` | Angled  | Round  | 箭头分隔 + 圆角帽 |
| `pl_slanted_round` | Slanted  | Round  | 斜线分隔 + 圆角帽 |
| `lean_none_none` | — | — | Lean 风格，无背景无分隔 |

### 生成示例

```
pl_angled_sharp_rainbow.toml
pl_round_round_classic.toml
lean_none_none_lean.toml
```

## 使用 (ssc)

```bash
# 前缀匹配（输入唯一前缀即可切换）
ssc pl_round              # 匹配 pl_round_round_*
ssc ang_s                 # 匹配 pl_angled_sharp_*

# 按类型筛选 + 序号
ssc -t a                  # 列出 starshipauto 配置（带序号）
ssc -t a 3               # 切换到第 3 个 auto 配置
ssc -t s                  # 列出 starship 静态配置（带序号）
ssc -t s 2               # 切换到第 2 个静态配置

# 锁定/解锁
ssc --lock                # 锁定当前配置（后续 session 默认使用）
ssc --lock pl_round       # 锁定指定配置（支持前缀匹配）
ssc --unlock              # 解除锁定，恢复随机模式

# 其他
ssc --list                # 列出所有可用配置
ssc --rebuild             # 重新生成配置
```

启动行为：有锁定配置则使用锁定，否则从全部配置池中随机选择。

## 架构

```
data/*.toml → [python generate.py] → generated/*.toml → ssc 切换
```

- **data/layouts/** — format 模板 + metadata（palette key 要求、modules_ref、默认 fg_role）
- **data/palettes/** — 命名颜色到 hex 值的映射
- **data/modules/** — 模块定义（多个 layout 可通过 `modules_ref` 共享）
- **data/shared/** — 跨 layout 共享数据（os_symbols, character, multiline）
- **engines/** — PowerShell 和 bash/zsh 的切换引擎
- **generated/** — 输出目录（.gitignore，不入版本控制）

## 数据文件格式

### Layout (`data/layouts/{layout}_{sep}_{head}.toml`)

```toml
[metadata]
name = "pl_angled_round"
description = "Powerline with angled separators and round head/tail"
modules_ref = "pl"          # 共享模块文件（data/modules/pl.toml）
palette_keys = ["os_bg", "dark", "white", "blue", "green", "yellow", "red", "grey", "teal"]
default_fg_role = "dark"

[options]
add_newline = true
command_timeout = 10000
scan_timeout = 1000
fill_symbol = "─"

[format]
template = '''
...\
{LANG_MODULES}\
...\
[  $time ](fg:{FG_ROLE} bg:os_bg)\
...'''
```

占位符：
- `{LANG_MODULES}` — 替换为语言模块 `$name\` 列表
- `{FG_ROLE}` — 替换为 palette 的 `hints.fg_role` 值

### Palette (`data/palettes/{palette}.toml`)

```toml
[palette]
os_bg = "#d0d0d0"
blue = "#005fd7"
muted = "#6c6c6c"
# ...

[hints]
fg_role = "dark"    # 推荐搭配的前景色 role
```

### Modules (`data/modules/{layout}.toml`)

```toml
[lang_order]
order = ["c", "rust", "python", ...]

[modules.rust]
symbol = "󱘗 "
style = "bg:grey"
format = '[[ $symbol($version) ](fg:white bg:grey)]($style)'

[modules.directory]
style = "bg:blue fg:white"
format = "[ $path ]($style)"
# ...
```

模块中可使用 `{FG_ROLE}` 占位符，生成时自动替换。

### Shared (`data/shared/`)

- **character.toml** — 命令行提示符样式
- **os_symbols.toml** — 操作系统图标映射
- **multiline.toml** — 多行标识（╭─/╰─），自动注入含 `$line_break` 的 layout

```toml
[multiline]
top_prefix = "[╭─]({STYLE})"
bottom_prefix = "[╰─]({STYLE})"
style = "fg:muted"
fallback_style = "fg:grey"
```

## 新增 palette

1. 在 `data/palettes/` 下创建 `{name}.toml`
2. 确保包含目标 layout 的所有 `palette_keys`
3. 运行 `python generate.py`（或 `ssc --rebuild`）

## 新增 layout

1. 在 `data/layouts/` 下创建 `{layout}_{sep}_{head}.toml`
2. 设置 `modules_ref` 指向已有模块文件，或在 `data/modules/` 下创建新文件
3. 运行 `python generate.py`

## 兼容性

生成器会自动检查 palette 与 layout 的兼容性（palette 的 keys 必须覆盖 layout 要求的 `palette_keys`）。不兼容的组合会被跳过。

## 添加为 submodule

### 已有远程分支（克隆到新机器时）

```bash
git submodule add -b starshipauto git@github.com:flcker/ShellCfgSubmodule.git submodule/starshipauto
git config -f .gitmodules submodule.submodule/starshipauto.shallow true
git config -f .gitmodules submodule.submodule/starshipauto.update rebase
git add .gitmodules submodule/starshipauto
git commit -m "feat: add starshipauto submodule"
```

### 首次创建（新仓库初始化）

```bash
# 在 submodule/starshipauto 目录中初始化
cd submodule/starshipauto
git init
git checkout -b starshipauto
git add .
git commit -m "feat: initial starshipauto module"
git remote add origin git@github.com:flcker/ShellCfgSubmodule.git
git push -u origin starshipauto

# 回到父仓库，删除后重新挂载为 submodule
cd ../..
rm -rf submodule/starshipauto
git submodule add -b starshipauto git@github.com:flcker/ShellCfgSubmodule.git submodule/starshipauto
git config -f .gitmodules submodule.submodule/starshipauto.shallow true
git config -f .gitmodules submodule.submodule/starshipauto.update rebase
git add .gitmodules submodule/starshipauto
git commit -m "feat: add starshipauto submodule"
```

## 要求

- Python 3.11+（使用内置 `tomllib`）
- Starship（已安装并在 PATH 中）
- Nerd Font（终端字体需支持 Powerline / Nerd Font 字形）
