# cc-tools

Claude Code 统一入口 — 模型切换 & 版本管理。

## 安装

**zsh**：在 `~/.zshrc` 末尾添加：

```zsh
# 凭证配置
export CC_MODEL_API_KEY="sk-..."        # API 密钥（必需）
export CC_MODEL_BASE_URL="http://..."   # 代理地址（可选，默认走官方）

# 载入 cc-tools
source ~/.config/zsh/submodule/cc-tools/cc.zsh
```

**PowerShell**：在 `$PROFILE` 末尾添加：

```powershell
# 凭证配置
$env:CC_MODEL_API_KEY = "sk-..."        # API 密钥（必需）
$env:CC_MODEL_BASE_URL = "http://..."   # 代理地址（可选，默认走官方）

# macOS / Linux — 与 zsh 共用同一仓库
. ~/.config/zsh/submodule/cc-tools/cc.ps1

# Windows — 独立 pwsh 仓库
# . ~/.config/pwsh/submodule/cc-tools/cc.ps1
```

## 用法

### 状态

```
cc          显示当前模型配置和 API 端点
cc model    同上（显式）
```

### 模型切换

```
cc ds|deepseek     DeepSeek:  deepseek-v4-pro / deepseek-v4-flash
cc glm             GLM:       glm-5.1 / glm-4.7
cc claude          Claude:    claude-opus-4.8 / claude-sonnet-4.6 / claude-haiku-4.5
cc gpt             GPT:       gpt-5.3-codex / gpt-5.2-codex
cc official        恢复 Anthropic 官方默认
```

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

| 变量 | 说明 | 必需 |
|------|------|------|
| `CC_MODEL_API_KEY` | API 密钥 | 是 |
| `CC_MODEL_BASE_URL` | 代理地址（默认走官方 api.anthropic.com） | 否 |
| `CC_MODEL_DISABLE_EXPERIMENTAL_BETAS` | 禁用实验特性（默认 1） | 否 |
| `CC_MODEL_ATTRIBUTION_HEADER` | 归属头（默认 false） | 否 |

## 文件结构

```
cc-tools/
├── cc.zsh                    zsh 入口
├── cc-model-switch.zsh       zsh 模型切换
├── cc-update.zsh             zsh 版本管理
├── cc.ps1                    PowerShell 入口
├── cc-model-switch.ps1       PowerShell 模型切换
├── cc-update.ps1             PowerShell 版本管理
└── README.md
```

## 平台支持

| | macOS | Linux | Windows |
|---|:---:|:---:|:---:|
| zsh | ✓ | ✓ | — |
| PowerShell | ✓ | ✓ | ✓ |
