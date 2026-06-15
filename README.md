# cc-tools

Claude Code 统一入口 — 模型切换 & 版本管理。

## 安装

**1. 创建配置文件** `~/.config/cc/vendors.conf`：

```ini
# 厂商配置
vendor.tal.url=http://ai-service.tal.com/coding
vendor.tal.key=sk-...
vendor.tal.models=claude-opus-4.8,deepseek-v4-pro,deepseek-v4-flash

vendor.ds.url=https://api.deepseek.com
vendor.ds.key=sk-...

vendor.glm.url=https://open.bigmodel.cn/api/paas/v4
vendor.glm.key=sk-...

auto=tal
```

```bash
chmod 600 ~/.config/cc/vendors.conf
```

**2. 载入脚本**（`~/.zshrc` 末尾）：

```zsh
source ~/.config/zsh/submodule/cc-tools/cc.zsh
```

**PowerShell**（`$PROFILE` 末尾）：

```powershell
. ~/.config/zsh/submodule/cc-tools/cc.ps1
```

## 用法

### 状态

```
cc          显示当前厂商 + 模型 + API
cc model    同上
```

### 厂商

```
cc vendor           列出已配置厂商
cc vendor <name>    切换厂商
```

### 模型

```
cc model                    显示当前模型组合
cc model ds|glm|claude|gpt  快捷全栈
cc model <opus> <sonnet> <haiku>  分别指定三档
```

### 快捷

```
cc ds|deepseek     厂商 + 全栈 DeepSeek
cc glm             厂商 + 全栈 GLM
cc claude          厂商 + 全栈 Claude
cc gpt             厂商 + 全栈 GPT
cc official        恢复 Anthropic 官方默认
```

快捷命令优先使用 `CC_VENDOR_*` 新配置，若无则回退到旧 `CC_MODEL_API_KEY`。

也可直接使用别名（zsh / PowerShell 均可用）：

```
cc2ds  cc2glm  cc2claude  cc2gpt  cc2official  ccmodel
```

### 版本管理

```
cc update                    更新到最新版本
cc update <ver>              更新到指定版本（如 2.1.173）
cc update --latest|-L        查看最新版本号
cc update --rollback|-r      回退到上一版本
cc update --remove|-rm <ver> 删除指定版本
cc update --clean|-c         清理所有旧版本（保留当前）
cc update --list|-l          列出已安装版本
```

### 帮助

```
cc help    显示完整帮助
```

## 环境变量

### v2 厂商配置

| 变量 | 说明 | 必需 |
|------|------|------|
| `CC_VENDOR_<NAME>_URL` | API 地址 | 否（默认官方） |
| `CC_VENDOR_<NAME>_KEY` | API 密钥 | 是 |
| `CC_VENDOR_<NAME>_MODELS` | 默认模型 "opus sonnet haiku" | 单模型厂商可省略 |

`<NAME>` 支持：`DS` `GLM` `CLAUDE` `GPT` `TAL` `VOLC` 等自定义。

### v1 兼容

| 变量 | 说明 |
|------|------|
| `CC_MODEL_API_KEY` | API 密钥（v2 配置后忽略） |
| `CC_MODEL_BASE_URL` | 代理地址（v2 配置后忽略） |

## 文件结构

```
cc-tools/
├── cc.zsh                    zsh 入口
├── cc-config.zsh             zsh 配置文件加载
├── cc-model-switch.zsh       zsh 模型预设 + v1 切换
├── cc-vendor-switch.zsh      zsh 厂商管理 (v2)
├── cc-update.zsh             zsh 版本管理
├── cc.ps1                    PowerShell 入口
├── cc-model-switch.ps1       PowerShell 模型切换
├── cc-update.ps1             PowerShell 版本管理
└── README.md

~/.config/cc/
└── vendors.conf              厂商配置文件（key=value，models 逗号分隔）
```

## 平台支持

| | macOS | Linux | Windows |
|---|:---:|:---:|:---:|
| zsh | ✓ | ✓ | — |
| PowerShell | ✓ | ✓ | ✓ |

## TODO

### v2 — 厂商 / 模型组合分层切换

当前 `cc ds|glm|claude|gpt` 一把切换厂商+模型，无法跨厂商混用（如 TAL 入口 + Claude Opus + DeepSeek Haiku）。

#### 设计

**配置约定**（`~/.zshrc`）：

```zsh
# 厂商凭证：CC_VENDOR_<name>_URL / _KEY / _MODELS
# _MODELS 格式 "opus sonnet haiku"，单模型厂商可省略（用内置默认）

# 多模型厂商（_MODELS 必填）
export CC_VENDOR_TAL_URL="http://..."  CC_VENDOR_TAL_KEY="sk-..."  CC_VENDOR_TAL_MODELS="claude-opus-4.8 deepseek-v4-pro deepseek-v4-flash"
export CC_VENDOR_VOLC_URL="http://..." CC_VENDOR_VOLC_KEY="sk-..." CC_VENDOR_VOLC_MODELS="deepseek-v4-pro deepseek-v4-pro deepseek-v4-flash"

# 单模型厂商（_MODELS 可选，有内置默认）
export CC_VENDOR_DS_URL="..."   CC_VENDOR_DS_KEY="sk-..."
export CC_VENDOR_GLM_URL="..."  CC_VENDOR_GLM_KEY="sk-..."
export CC_VENDOR_GPT_URL="..."  CC_VENDOR_GPT_KEY="sk-..."
export CC_VENDOR_CLAUDE_KEY="sk-ant-..."                         # URL 默认 api.anthropic.com
```

**命令设计**：

```
# 厂商（切凭证入口）
cc vendor               显示当前厂商
cc vendor tal|ds|glm|...

# 模型组合（切三档模型）
cc model                    显示当前组合
cc model ds|glm|claude|gpt  快捷全栈
cc model <opus> <sonnet> <haiku>  分别指定

# 快捷（厂商 + 模型一起切，保持 v1 兼容）
cc ds|glm|claude|gpt     → vendor + model 全栈
cc tal|volc               → vendor + 默认 model
cc official               → 恢复官方
cc model                  → 显示当前状态
```

**行为区分**：

| 命令 | 单模型厂商 (DS/GLM/Claude/GPT) | 多模型厂商 (TAL/火山) |
|------|-------------------------------|----------------------|
| `cc <name>` | 厂商 + 模型全栈定死 | 只切入口，模型由 `cc model` 控制 |
| `cc vendor <name>` | 同上 | 只切入口 |
| `cc model <o> <s> <h>` | 覆盖默认（一般不必要） | 分配三档 |

**内置模型默认**：

| 厂商 | Opus | Sonnet | Haiku |
|------|------|--------|-------|
| DS | deepseek-v4-pro | deepseek-v4-pro | deepseek-v4-flash |
| GLM | glm-5.1 | glm-5.1 | glm-4.7 |
| Claude | claude-opus-4.8 | claude-sonnet-4.6 | claude-haiku-4.5 |
| GPT | gpt-5.3-codex | gpt-5.3-codex | gpt-5.2-codex |

#### 任务拆解

- [x] `cc-vendor-switch.zsh` — 独立模块，管理厂商凭证（URL/Key）
- [x] 重构 `cc-model-switch.zsh` — 内置模型预设表，model 独立于 vendor
- [x] `cc-config.zsh` — key=value 配置文件加载，models 逗号分隔
- [x] `cc.zsh` 入口 — vendor / model 子命令，config 自动加载 + auto 启动切换
- [ ] `cc-config.ps1` + `cc-vendor-switch.ps1` + 重构 `cc-model-switch.ps1` + `cc.ps1`
- [ ] README 更新为最终版
