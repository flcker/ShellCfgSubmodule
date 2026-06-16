# cc-tools

Claude Code 统一入口 — 厂商切换 & 模型管理 & 版本更新。

## 安装

**1. 编写配置** `~/.config/cc-tools/cc-tools.conf`：

```ini
# 多模型厂商（可混用不同厂商的模型）
vendor.multi.url=http://your-proxy.com
vendor.multi.key=sk-...
vendor.multi.models=claude-opus-4.8,deepseek-v4-pro,deepseek-v4-flash
vendor.multi.preset.heavy.current=claude-opus-4.8
vendor.multi.preset.heavy.opus=claude-opus-4.8
vendor.multi.preset.heavy.sonnet=claude-sonnet-4.6
vendor.multi.preset.heavy.haiku=claude-haiku-4.5
vendor.multi.preset.lite.current=deepseek-v4-flash
vendor.multi.preset.lite.opus=deepseek-v4-flash
vendor.multi.preset.lite.sonnet=deepseek-v4-flash
vendor.multi.preset.lite.haiku=deepseek-v4-flash

# 单模型厂商
vendor.ds.url=https://api.deepseek.com
vendor.ds.key=sk-...
vendor.ds.models=deepseek-v4-pro,deepseek-v4-pro,deepseek-v4-flash

auto=multi
```

```bash
chmod 600 ~/.config/cc-tools/cc-tools.conf
```

或使用模板生成：

```bash
cc config init    # 从 template.conf 复制，已有配置自动备份
```

**2. 载入脚本**（`~/.zshrc` 末尾）：

```zsh
source ~/.config/zsh/submodule/cc-tools/cc.zsh
```

## 命令

### 厂商

```
cc vendor              列出当前厂商（URL/模型/预设）+ 可用厂商
cc vendor <name>       切换厂商，应用其 models 字段
cc <name>              同上（快捷）
cc official            恢复官方 Anthropic
```

### 模型

```
cc model                    显示 [Vendor] [Current] [Opus] [Sonnet] [Haiku] [Presets]
cc model <name>             切换预设（查 vendor.<v>.preset.<name>.*）
cc model <o> <s> <h>       自定义三档
cc model <o> <s> <h> <c>   自定义三档 + Current
```

### 配置

```
cc config init           生成默认配置文件（备份旧文件）
cc config reload         重载配置文件
```

### 更新

```
cc update                    更新到最新版本
cc update <ver>              更新到指定版本
cc update --latest|-L        查看最新版本号
cc update --rollback|-r      回退到上一版本
cc update --remove|-rm <ver> 删除指定版本（当前版本自动回退）
cc update --clean|-c         清理所有旧版本
cc update --list|-l          列出已安装版本
```

### 帮助

```
cc help    显示完整帮助
```

## 配置文件格式

`~/.config/cc-tools/cc-tools.conf`，`key=value` 纯文本，零依赖：

| 字段 | 格式 | 说明 |
|------|------|------|
| `vendor.<name>.url` | URL | API 地址（Claude 官方可省略） |
| `vendor.<name>.key` | string | API 密钥（必需） |
| `vendor.<name>.models` | `opus,sonnet,haiku` | 切换厂商时自动应用 |
| `vendor.<name>.preset.<n>.opus` | model | 预设 Opus（必需） |
| `vendor.<name>.preset.<n>.sonnet` | model | 预设 Sonnet（必需） |
| `vendor.<name>.preset.<n>.haiku` | model | 预设 Haiku（必需） |
| `vendor.<name>.preset.<n>.current` | model | ANTHROPIC_MODEL（可选，缺省取 opus） |
| `auto` | vendor name | 启动自动切换 |

`models` 和 `preset` 字段用逗号分隔，对应 ANTHROPIC 三档环境变量。

## 架构

```
cc (入口)
├── cc-config.zsh         配置加载（key=value → CC_VENDOR_* env）
│   cc config init         复制模板，备份旧文件
│   cc config reload       热重载
│
├── cc-vendor-switch.zsh   厂商管理
│   cc vendor              当前厂商详情 + 可用列表
│   cc vendor <name>       切 URL/Key + 应用 models
│   cc <name>              等效快捷
│   cc official            清空恢复
│
├── cc-model-switch.zsh    模型预设
│   cc model               显示 Current + 三档 + 预设列表
│   cc model <name>        切换预设
│   cc model o s h [c]     自定义
│
└── cc-update.zsh          CLI 版本管理
    cc update               安装/切换/回退/清理/列表
```

## 文件结构

```
cc-tools/
├── cc.zsh                    入口
├── cc-config.zsh             配置加载
├── cc-vendor-switch.zsh      厂商管理
├── cc-model-switch.zsh       模型预设
├── cc-update.zsh             版本管理
├── template.conf             配置模板（随仓库分发）
└── README.md

~/.config/cc-tools/
└── cc-tools.conf             用户配置（chmod 600）
```

## 平台支持

| | macOS | Linux | Windows |
|---|:---:|:---:|:---:|
| zsh | ✓ | ✓ | — |
| PowerShell | — | — | — |
