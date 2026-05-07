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

## 使用

```bash
ssc p10k-powerline-rainbow    # 切换到生成的配置
ssc p10kr                     # 简写别名
ssc p10kc                     # p10k-powerline-classic
ssc p10kl                     # p10k-lean-lean
ssc --list                    # 列出所有可用配置
ssc --rebuild                 # 重新生成配置
```

## 架构

```
data/*.toml → [python generate.py] → generated/*.toml → ssc 切换
```

- **data/layouts/** — format 模板 + metadata（palette key 要求、默认 fg_role）
- **data/palettes/** — 命名颜色到 hex 值的映射
- **data/modules/** — 每个 layout 的完整模块定义
- **data/shared/** — 跨 layout 共享数据（os_symbols, character）
- **engines/** — PowerShell 和 bash/zsh 的切换引擎
- **generated/** — 输出目录（.gitignore，不入版本控制）

## 数据文件格式

### Layout (`data/layouts/<name>.toml`)

```toml
[metadata]
name = "p10k-powerline"
palette_keys = ["os_bg", "dark", "white", "blue", "green", "yellow", "red", "grey", "teal"]
default_fg_role = "dark"

[options]
add_newline = true
command_timeout = 10000
scan_timeout = 1000

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

### Palette (`data/palettes/<name>.toml`)

```toml
[palette]
os_bg = "#d0d0d0"
blue = "#005fd7"
# ...

[hints]
fg_role = "dark"    # 推荐搭配的前景色 role
```

### Modules (`data/modules/<layout-name>.toml`)

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

## 新增 palette

1. 在 `data/palettes/` 下创建 `<name>.toml`
2. 确保包含目标 layout 的所有 `palette_keys`
3. 运行 `python generate.py`（或 `ssc --rebuild`）

## 新增 layout

1. 在 `data/layouts/` 下创建 `<name>.toml`（定义 format 模板）
2. 在 `data/modules/` 下创建同名 `<name>.toml`（定义模块）
3. 运行 `python generate.py`

## 兼容性

生成器会自动检查 palette 与 layout 的兼容性（palette 的 keys 必须覆盖 layout 要求的 `palette_keys`）。不兼容的组合会被跳过。

## 要求

- Python 3.11+（使用内置 `tomllib`）
- Starship（已安装并在 PATH 中）
- Nerd Font（终端字体需支持 Powerline / Nerd Font 字形）
