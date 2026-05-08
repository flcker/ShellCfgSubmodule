# starshipauto

动态 Starship 配置生成器。将 layout/separator/palette 解耦为独立数据文件，通过 Python 脚本生成所有组合的最终 `.toml` 配置。

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

生成文件命名格式：`{layout}_{separator}_{palette}`

| 字段 | 含义 | 取值 |
|------|------|------|
| layout | 布局类型 | `pl`(powerline), `lean` |
| separator | 分隔符风格 | `angled_round`, `round_round`, `slanted_round`, `angled_sharp`, `slanted_none`, `none` |
| palette | 配色方案 | `rainbow`, `classic`, `pastel`, `catppuccin_mocha` 等 |

### 生成示例

```
pl_angled_round_rainbow.toml
pl_slanted_none_classic.toml
lean_none_catppuccin_mocha.toml
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
data/
├── layouts/       ─┐
├── separators/     ├─→ [python generate.py] → generated/*.toml → ssc 切换
├── palettes/      ─┘
└── shared/
```

生成维度：`layout × compatible_separators × palette`

- **data/layouts/** — 自包含的布局定义（metadata + format 模板 + 模块配置）
- **data/separators/** — 分隔符字形定义（仅 3 个值：sep/head/tail）
- **data/palettes/** — 命名颜色到 hex 值的映射
- **data/shared/** — 跨 layout 共享数据（options, os_symbols, character, multiline）
- **engines/** — PowerShell 和 bash/zsh 的切换引擎
- **generated/** — 输出目录（.gitignore，不入版本控制）

## 数据文件格式

### Layout (`data/layouts/{name}.toml`)

每个 layout 文件自包含 metadata、format 模板和全部模块定义：

```toml
[metadata]
name = "pl"
description = "Powerline layout with background segments"
palette_keys = ["os_bg", "dark", "white", "blue", "green", "yellow", "red", "grey", "teal"]
default_fg_role = "dark"
compatible_separators = ["angled_round", "round_round", "slanted_round", "angled_sharp", "slanted_none"]

[format]
template = '''
{HEAD:os_bg}\
$os\
...
{SEP:os_bg:blue}\
$directory\
...'''

[lang_order]
order = ["c", "rust", "python", ...]

[modules.rust]
symbol = "󱘗 "
style = "bg:grey"
format = '[[ $symbol($version) ](fg:{FG_ROLE} bg:grey)]($style)'
```

Format 模板占位符：
- `{HEAD:color}` — 首段开口帽（separator 无此字形则省略）
- `{SEP:prev:next}` — 左侧段间过渡 `[glyph](bg:next fg:prev)`
- `{L_END:color}` — 左侧末段封口
- `{R_START:color}` — 右侧首段开口
- `{R_SEP:next:prev}` — 右侧段间过渡 `[glyph](fg:next bg:prev)`
- `{R_TAIL:color}` — 右侧末段封口帽（separator 无此字形则省略）
- `{LANG_MODULES}` — 展开为语言模块 `$name\` 列表
- `{FG_ROLE}` — 由 palette 的 `hints.fg_role` 决定的前景色

### Separator (`data/separators/{name}.toml`)

```toml
[separators]
sep = ""      # 段间过渡字形（右向）
head = ""     # 首段开口帽（空=无帽）
tail = ""     # 末段封口帽（空=无帽）
```

生成器自动推导镜像字形：
- `r_sep` = sep 的镜像（E0B0↔E0B2, E0B4↔E0B6, E0BC↔E0BE）
- `l_end` = tail 非空时用 tail，否则用 sep
- `r_start` = r_sep
- `r_tail` = tail

### Palette (`data/palettes/{name}.toml`)

```toml
[palette]
os_bg = "#d0d0d0"
blue = "#005fd7"
muted = "#6c6c6c"
# ...

[hints]
fg_role = "dark"    # 推荐搭配的前景色 role（映射到 palette 中的颜色名）
```

### Shared (`data/shared/`)

- **options.toml** — 全局选项（add_newline, command_timeout 等），layout 可局部覆盖
- **character.toml** — 命令行提示符样式
- **os_symbols.toml** — 操作系统图标映射（50 个 Nerd Font 图标）
- **multiline.toml** — 多行标识（╭─/╰─），自动注入含 `$line_break` 的 layout

## 新增 separator

1. 在 `data/separators/` 下创建 `{name}.toml`，定义 3 个字形
2. 在目标 layout 的 `compatible_separators` 列表中加入名称
3. 运行 `python generate.py`

## 新增 palette

1. 在 `data/palettes/` 下创建 `{name}.toml`
2. 确保包含目标 layout 的所有 `palette_keys`
3. 运行 `python generate.py`（或 `ssc --rebuild`）

## 新增 layout

1. 在 `data/layouts/` 下创建 `{name}.toml`
2. 定义 metadata（含 `compatible_separators`）、format 模板和全部模块配置
3. 运行 `python generate.py`

## 兼容性

生成器自动检查：
- palette 的 keys 必须覆盖 layout 要求的 `palette_keys`
- layout 只与其 `compatible_separators` 中列出的 separator 组合

不兼容的组合会被跳过。

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
cd submodule/starshipauto
git init
git checkout -b starshipauto
git add .
git commit -m "feat: initial starshipauto module"
git remote add origin git@github.com:flcker/ShellCfgSubmodule.git
git push -u origin starshipauto

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
