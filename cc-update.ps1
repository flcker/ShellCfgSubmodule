# ============================================================
# Claude Code 更新脚本 (PowerShell)
# ============================================================
# 下载指定版本的 Claude Code CLI 并更新本地 symlink。
#
# 使用方法:
#   Invoke-CCUpdate                # 更新到最新版本
#   Invoke-CCUpdate -Version 2.1.173  # 更新到指定版本
#   Invoke-CCUpdate -Rollback      # 回退到上一版本
#   Invoke-CCUpdate -List          # 列出已安装版本
#   Invoke-CCUpdate -Latest        # 查看最新版本号
#   Invoke-CCUpdate -Remove 2.1.173  # 删除指定版本
#   Invoke-CCUpdate -Clean         # 清理所有旧版本
#
# 参考: claude-update.md
# ============================================================

# ============================================================
# 统一配置
# ============================================================

if (-not (Test-Path Env:CC_DIST_BASE)) {
    $env:CC_DIST_BASE = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819"
}
$script:CC_VERSIONS_DIR = "$HOME/.local/share/claude/versions"
$script:CC_BIN_DIR       = "$HOME/.local/bin"
$script:CC_BIN_NAME      = if ($IsWindows) { "claude.exe" } else { "claude" }

# ============================================================
# ANSI 颜色（如果尚未定义）
# ============================================================

if (-not (Test-Path Variable:script:C_DARK_GRAY)) {
    $script:C_DARK_GRAY = "`e[37m"
    $script:C_GREEN     = "`e[32m"
    $script:C_CYAN      = "`e[36m"
    $script:C_YELLOW    = "`e[33m"
    $script:C_RED       = "`e[31m"
    $script:C_RESET     = "`e[0m"
}

# ============================================================
# 平台检测
# ============================================================

function Get-Arch {
    # 返回统一架构名：arm64 / x64
    $procArch = if ($PSVersionTable.PSVersion.Major -ge 6) {
        [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    } else {
        $Env:PROCESSOR_ARCHITECTURE
    }
    switch ($procArch) {
        "Arm64"  { return "arm64" }
        "X64"    { return "x64" }
        "AMD64"  { return "x64" }
        "x86_64" { return "x64" }
        "aarch64"{ return "arm64" }
        default {
            # 回退到 uname（macOS/Linux）
            $uname = try { uname -m 2>$null } catch { "" }
            if ($uname -match "arm64|aarch64") { return "arm64" }
            if ($uname -match "x86_64")         { return "x64" }
            Write-Host "${C_RED}✗ 不支持的架构: ${procArch}${C_RESET}"
            return $null
        }
    }
}

function Get-CCPlatform {
    $arch = Get-Arch
    if (-not $arch) { return $null }

    if ($IsMacOS)    { return "darwin-${arch}" }
    if ($IsLinux)    { return "linux-${arch}" }
    if ($IsWindows)  { return "win32-${arch}" }

    Write-Host "${C_RED}✗ 不支持的操作系统${C_RESET}"
    return $null
}

# ============================================================
# 获取最新版本号（从发布清单 / latest 标记）
# ============================================================

function Get-LatestVersion {
    $latestUrl = "$env:CC_DIST_BASE/claude-code-releases/latest"
    try {
        $version = Invoke-RestMethod -Uri $latestUrl -ErrorAction Stop
        if (-not $version) { throw "empty response" }
        return $version.Trim()
    } catch {
        Write-Host "${C_RED}✗ 无法获取最新版本号${C_RESET}"
        return $null
    }
}

# ============================================================
# 构建下载 URL
# ============================================================

function Get-DownloadUrl {
    param([string]$Version, [string]$Platform)
    return "$env:CC_DIST_BASE/claude-code-releases/${Version}/${Platform}/${CC_BIN_NAME}"
}

# ============================================================
# 跨平台链接（Windows 非管理员回退：符号链接 → 硬链接 → 复制）
# ============================================================

function Set-CCLink {
    param([string]$Path, [string]$Target)
    # Windows 允许删除运行中的 exe（标记为待删除，进程退出后释放），先删再建避免占用冲突
    Remove-Item -Force $Path -ErrorAction SilentlyContinue
    try {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force -ErrorAction Stop | Out-Null
    } catch {
        if ($IsWindows) {
            try {
                New-Item -ItemType HardLink -Path $Path -Target $Target -Force -ErrorAction Stop | Out-Null
            } catch {
                Copy-Item -Force $Target $Path
            }
        } else {
            throw
        }
    }
}

# ============================================================
# 运行时二元排序
# ============================================================

function Sort-VersionsDescending {
    param([string[]]$Versions)
    return $Versions | Sort-Object {
        $parts = $_ -split '\.'
        [long]$parts[0] * 1000000 + [long]$parts[1] * 1000 + [long]$parts[2]
    } -Descending
}

# ============================================================
# 列出已安装版本
# ============================================================

function Show-InstalledVersions {
    Write-Host "${C_DARK_GRAY}已安装版本 (${CC_VERSIONS_DIR}):${C_RESET}"
    if (-not (Test-Path $CC_VERSIONS_DIR) -or (Get-ChildItem $CC_VERSIONS_DIR -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }).Count -eq 0) {
        Write-Host "  (无)"
        return
    }

    $currentTarget = ""
    $binPath = Join-Path $CC_BIN_DIR $CC_BIN_NAME
    try {
        $currentTarget = (Get-Item $binPath -ErrorAction Stop).Target
    } catch {}

    Get-ChildItem $CC_VERSIONS_DIR -File | ForEach-Object {
        $vname = $_.Name
        $marker = ""
        if ($_.FullName -eq $currentTarget) {
            $marker = " ${C_GREEN}← 当前${C_RESET}"
        }
        Write-Host "  ${C_CYAN}${vname}${marker}${C_RESET}"
    }
}

# ============================================================
# 回退到上一版本
# ============================================================

function Invoke-Rollback {
    $binPath = Join-Path $CC_BIN_DIR $CC_BIN_NAME
    $currentTarget = ""
    try { $currentTarget = (Get-Item $binPath -ErrorAction Stop).Target } catch {}

    if (-not (Test-Path $CC_VERSIONS_DIR) -or (Get-ChildItem $CC_VERSIONS_DIR -File -ErrorAction SilentlyContinue | Where-Object { $true }).Count -eq 0) {
        Write-Host "${C_YELLOW}⚠ 没有已安装的版本可回退${C_RESET}"
        return $false
    }

    # 收集除当前版本外的所有版本
    $candidates = @(Get-ChildItem $CC_VERSIONS_DIR -File | Where-Object { $_.FullName -ne $currentTarget })
    if ($candidates.Count -eq 0) {
        Write-Host "${C_YELLOW}⚠ 只有当前一个版本，无法回退${C_RESET}"
        return $false
    }

    # 按版本号降序取第一个
    $target = $candidates | ForEach-Object {
        $ver = $_.Name -replace '^claude-', ''
        [PSCustomObject]@{ Version = $ver; Path = $_.FullName }
    } | Sort-Object {
        $parts = $_.Version -split '\.'
        [long]$parts[0] * 1000000 + [long]$parts[1] * 1000 + [long]$parts[2]
    } -Descending | Select-Object -First 1

    $targetName = Split-Path -Leaf $target.Path
    $currentName = if ($currentTarget) { Split-Path -Leaf $currentTarget } else { "(无)" }

    Write-Host "${C_DARK_GRAY}回退: ${currentName} → ${C_CYAN}${targetName}${C_RESET}"
    Set-CCLink -Path $binPath -Target $target.Path
    Write-Host "${C_GREEN}✓ 已切换到 ${targetName}${C_RESET}"
    return $true
}

# ============================================================
# 跨平台文件同一性检测（覆盖符号链接、硬链接、复制）
# ============================================================

function Test-SameFile {
    param([string]$Path1, [string]$Path2)
    if (-not (Test-Path $Path1) -or -not (Test-Path $Path2)) { return $false }

    $item1 = Get-Item $Path1 -Force
    $item2 = Get-Item $Path2 -Force

    # 解析符号链接 / junction
    $real1 = if ($item1.Target) { $item1.Target } else { $item1.FullName }
    $real2 = if ($item2.Target) { $item2.Target } else { $item2.FullName }
    if ($real1 -eq $real2) { return $true }

    # 硬链接检测：同一文件共享所有属性；复制品的 CreationTime 不同
    try {
        $stat1 = Get-Item $real1
        $stat2 = Get-Item $real2
        if ($stat1.Length -eq $stat2.Length -and
            $stat1.CreationTimeUtc -eq $stat2.CreationTimeUtc -and
            $stat1.LastWriteTimeUtc -eq $stat2.LastWriteTimeUtc) {
            return $true
        }
    } catch {}
    return $false
}

# ============================================================
# 删除指定版本
# ============================================================

function Remove-Version {
    param([string]$Ver)
    $binPath = Join-Path $CC_BIN_DIR $CC_BIN_NAME

    # 解析文件名：支持 claude-2.1.121 和 2.1.121 两种写法
    $targetPath = $null
    $path1 = Join-Path $CC_VERSIONS_DIR "claude-${Ver}"
    $path2 = Join-Path $CC_VERSIONS_DIR $Ver
    if (Test-Path $path1 -PathType Leaf) { $targetPath = $path1 }
    elseif (Test-Path $path2 -PathType Leaf) { $targetPath = $path2 }
    else {
        Write-Host "${C_RED}✗ 版本不存在: ${Ver}${C_RESET}"
        return $false
    }

    # 判断是否为当前使用的版本（覆盖符号链接、硬链接、复制）
    $isCurrent = $false
    try {
        $isCurrent = Test-SameFile -Path1 $targetPath -Path2 $binPath
    } catch {}

    if ($isCurrent) {
        # 查找其他已安装版本用于回退
        $versions = @(Get-ChildItem $CC_VERSIONS_DIR -File | Where-Object { $_.FullName -ne $targetPath })
        if ($versions.Count -gt 0) {
            Write-Host "${C_YELLOW}⚠ ${Ver} 是当前版本，正在回退...${C_RESET}"
            $rollbackTarget = $versions | ForEach-Object {
                $v = $_.Name -replace '^claude-', ''
                [PSCustomObject]@{ Version = $v; Path = $_.FullName }
            } | Sort-Object {
                $parts = $_.Version -split '\.'
                [long]$parts[0] * 1000000 + [long]$parts[1] * 1000 + [long]$parts[2]
            } -Descending | Select-Object -First 1

            Set-CCLink -Path $binPath -Target $rollbackTarget.Path
            Write-Host "${C_GREEN}✓ 已回退到 $(Split-Path -Leaf $rollbackTarget.Path)${C_RESET}"
        } else {
            Write-Host "${C_YELLOW}⚠ ${Ver} 是唯一安装的版本，一并移除 bin${C_RESET}"
            Remove-Item -Force $binPath -ErrorAction SilentlyContinue
            Write-Host "${C_DARK_GRAY}  已删除 $(Split-Path -Leaf $binPath)${C_RESET}"
        }
    }

    Remove-Item -Force $targetPath
    Write-Host "${C_GREEN}✓ 已删除 $(Split-Path -Leaf $targetPath)${C_RESET}"
    return $true
}

# ============================================================
# 清理所有旧版本（保留当前）
# ============================================================

function Invoke-CleanVersions {
    $binPath = Join-Path $CC_BIN_DIR $CC_BIN_NAME
    $currentTarget = ""
    try { $currentTarget = (Get-Item $binPath -ErrorAction Stop).Target } catch {}

    if (-not (Test-Path $CC_VERSIONS_DIR) -or (Get-ChildItem $CC_VERSIONS_DIR -File -ErrorAction SilentlyContinue | Where-Object { $true }).Count -eq 0) {
        Write-Host "${C_YELLOW}⚠ 没有已安装的版本${C_RESET}"
        return
    }

    $toDelete = @(Get-ChildItem $CC_VERSIONS_DIR -File | Where-Object { $_.FullName -ne $currentTarget })
    if ($toDelete.Count -eq 0) {
        Write-Host "${C_DARK_GRAY}没有可清理的旧版本${C_RESET}"
        return
    }

    $freed = 0
    foreach ($f in $toDelete) {
        $size = "{0:N0}K" -f ($f.Length / 1KB)
        Remove-Item -Force $f.FullName
        $freed++
        Write-Host "${C_DARK_GRAY}  删除: $($f.Name) (${size})${C_RESET}"
    }

    $currentName = if ($currentTarget) { Split-Path -Leaf $currentTarget } else { "(无)" }
    Write-Host "${C_GREEN}✓ 已清理 ${freed} 个旧版本，当前保留: ${currentName}${C_RESET}"
}

# ============================================================
# 主函数
# ============================================================

function Invoke-CCUpdate {
    param(
        [switch]$List,
        [switch]$Rollback,
        [string]$Remove,
        [switch]$Clean,
        [switch]$Latest,
        [switch]$Help,
        [string]$Version
    )

    # ----- 确保目录存在 -----
    New-Item -ItemType Directory -Force -Path $CC_VERSIONS_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $CC_BIN_DIR | Out-Null

    # ----- 子命令分发 -----
    if ($Help) {
        Write-Host "用法: ${C_GREEN}Invoke-CCUpdate${C_RESET} [版本号|--latest|-L|--rollback|-r|--remove|-rm|--clean|-c|--list|-l]"
        Write-Host ""
        Write-Host "  ${C_DARK_GRAY}# 更新${C_RESET}"
        Write-Host "    ${C_GREEN}Invoke-CCUpdate${C_RESET}               更新到最新版本"
        Write-Host "    ${C_GREEN}Invoke-CCUpdate 2.1.173${C_RESET}       更新到指定版本"
        Write-Host ""
        Write-Host "  ${C_DARK_GRAY}# 查询${C_RESET}"
        Write-Host "    ${C_GREEN}--latest|-L${C_RESET}                    查看最新版本号"
        Write-Host "    ${C_GREEN}--list|-l${C_RESET}                     列出已安装版本"
        Write-Host ""
        Write-Host "  ${C_DARK_GRAY}# 管理${C_RESET}"
        Write-Host "    ${C_GREEN}--rollback|-r${C_RESET}                 回退到上一版本"
        Write-Host "    ${C_GREEN}--remove|-rm <ver>${C_RESET}           删除指定版本"
        Write-Host "    ${C_GREEN}--clean|-c${C_RESET}                   清理旧版本（保留当前）"
        return
    }

    if ($List) {
        Show-InstalledVersions
        return
    }

    if ($Rollback) {
        Invoke-Rollback
        return
    }

    if ($Remove) {
        Remove-Version -Ver $Remove
        return
    }

    if ($Clean) {
        Invoke-CleanVersions
        return
    }

    if ($Latest) {
        $platform = Get-CCPlatform
        if (-not $platform) { return }
        Write-Host "${C_DARK_GRAY}正在获取最新版本...${C_RESET}"
        $latestVer = Get-LatestVersion
        if (-not $latestVer) { return }
        Write-Host "${C_GREEN}最新版本: ${C_CYAN}${latestVer}${C_RESET}"
        return
    }

    # ----- 平台检测 -----
    $platform = Get-CCPlatform
    if (-not $platform) { return }

    # ----- 确定版本 -----
    $ver = $Version
    if (-not $ver) {
        Write-Host "${C_DARK_GRAY}正在获取最新版本...${C_RESET}"
        $ver = Get-LatestVersion
        if (-not $ver) { return }
    }

    $targetPath = Join-Path $CC_VERSIONS_DIR "claude-${ver}"
    $downloadUrl = Get-DownloadUrl -Version $ver -Platform $platform

    # ----- 已是最新？-----
    $binPath = Join-Path $CC_BIN_DIR $CC_BIN_NAME
    if ((Test-Path $binPath) -and (Test-Path $targetPath -PathType Leaf)) {
        if (Test-SameFile -Path1 $targetPath -Path2 $binPath) {
            Write-Host "${C_GREEN}✓ 已是最新版本 ${C_CYAN}${ver}${C_RESET}"
            return
        }
    }

    # ----- 版本已存在？-----
    if (Test-Path $targetPath -PathType Leaf) {
        Write-Host "${C_DARK_GRAY}版本 ${C_CYAN}${ver}${C_DARK_GRAY} 已下载，直接切换...${C_RESET}"
    } else {
        # ----- 下载 -----
        Write-Host "${C_DARK_GRAY}下载中 ${downloadUrl}${C_RESET}"
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $targetPath -ErrorAction Stop
        } catch {
            Write-Host "${C_RED}✗ 下载失败${C_RESET}"
            Remove-Item -Force $targetPath -ErrorAction SilentlyContinue
            return
        }

        # ----- 校验（检查是否为有效二进制）-----
        if ($IsWindows) {
            # Windows: 检查 PE 魔数 (MZ)
            $size = (Get-Item $targetPath).Length
            if ($size -eq 0) {
                Write-Host "${C_RED}✗ 下载的文件为空${C_RESET}"
                Remove-Item -Force $targetPath -ErrorAction SilentlyContinue
                return
            }
            $magic = [System.IO.File]::ReadAllBytes($targetPath)[0..1]
            if ($magic[0] -ne 0x4D -or $magic[1] -ne 0x5A) {
                Write-Host "${C_RED}✗ 下载的文件不是有效 PE 二进制${C_RESET}"
                Remove-Item -Force $targetPath -ErrorAction SilentlyContinue
                return
            }
        } else {
            # macOS/Linux: file 命令检查
            $fileCmd = if ($IsMacOS) { "/usr/bin/file" } else { "file" }
            $fileResult = & $fileCmd $targetPath 2>$null
            if ($fileResult -notmatch "executable|Mach-O|ELF") {
                Write-Host "${C_RED}✗ 下载的文件不是有效二进制${C_RESET}"
                Remove-Item -Force $targetPath -ErrorAction SilentlyContinue
                return
            }
            # 确保可执行
            & /bin/chmod +x $targetPath 2>$null
        }

        # ----- 完整性检查（试运行 --version）-----
        try {
            $null = & $targetPath --version 2>$null
            if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
        } catch {
            Write-Host "${C_RED}✗ 下载的文件无法运行（可能损坏或不完整）${C_RESET}"
            Remove-Item -Force $targetPath -ErrorAction SilentlyContinue
            return
        }

        Write-Host "${C_GREEN}✓ 下载完成 (${targetPath})${C_RESET}"
    }

    # ----- 记录当前版本（用于回退）-----
    $prevTarget = ""
    try { $prevTarget = (Get-Item $binPath -ErrorAction Stop).Target } catch {}

    # ----- 创建/更新链接 -----
    Set-CCLink -Path $binPath -Target $targetPath

    if ($prevTarget -and $prevTarget -ne $targetPath) {
        Write-Host "${C_DARK_GRAY}切换: $(Split-Path -Leaf $prevTarget) → ${C_CYAN}claude-${ver}${C_RESET}"
    }
    Write-Host "${C_GREEN}✓ Claude Code ${ver} (${platform}) 已就绪${C_RESET}"
}

# ============================================================
# 启动提示
# ============================================================

Write-Host "${C_DARK_GRAY}[cc-update] 已加载，可用: ${C_GREEN}Invoke-CCUpdate [-List|-Rollback|-Remove <ver>|-Clean|-Latest|-Help]${C_RESET}"
