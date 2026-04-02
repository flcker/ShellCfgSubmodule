-- colortheme.lua

-- 定义color theme
local colortheme = {}

-- 基础配色定义
colortheme.base = {
    bg      = "#1e1e2e",
    fg      = "#cdd6f4",
    red     = "#f38ba8",
    green   = "#a6e3a1",
    yellow  = "#f9e2af",
    blue    = "#89b4fa",
    magenta = "#cba6f7",
    cyan    = "#94e2d5",
    white   = "#bac2de",
}

-- onedark 主题配色定义
colortheme.onedark = {
    bg      = "#121212",
    fg      = "#e0e0e0",
    red     = "#ff5370",
    green   = "#c3e88d",
    yellow  = "#ffcb6b",
    blue    = "#82aaff",
    magenta = "#c792ea",
    cyan    = "#89ddff",
    white   = "#ffffff",
}

-- one monokai主题配色定义
colortheme.onemonokai = {
    bg      = "#272822",
    fg      = "#f8f8f2",
    red     = "#f92672",
    green   = "#a6e22e",
    yellow  = "#e6db74",
    blue    = "#66d9ef",
    magenta = "#ae81ff",
    cyan    = "#38bdf8",
    white   = "#f8f8f2",
}

-- 高亮组定义
local usingColortheme = colortheme.onedark -- 选择使用的主题配色
colortheme.highlights = {
    Normal     = { fg = usingColortheme.fg, bg = usingColortheme.bg },
    Comment    = { fg = usingColortheme.cyan, bg = usingColortheme.bg, italic = true },
    Constant   = { fg = usingColortheme.yellow },
    String     = { fg = usingColortheme.green },
    Identifier = { fg = usingColortheme.blue },
    Statement  = { fg = usingColortheme.magenta },
    PreProc    = { fg = usingColortheme.red },
    Type       = { fg = usingColortheme.yellow },
    Special    = { fg = usingColortheme.cyan },
    Underlined = { fg = usingColortheme.blue, underline = true },
    Todo       = { fg = usingColortheme.red, bg = usingColortheme.yellow, bold = true },
}

-- 应用highlight
for group, hl in pairs(colortheme.highlights) do
    vim.api.nvim_set_hl(0, group, hl)
end

return colortheme
