-- Neovim Lua Config

-- 设置编码
-- 默认utf8
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- Line Number
vim.opt.number = true
vim.opt.relativenumber = false

-- 鼠标支持
vim.opt.mouse = "a" -- 启用鼠标支持

-- 缩紧
-- 默认 4 个空格缩进
vim.opt.tabstop = 4        -- 制表符宽度
vim.opt.softtabstop = 4    -- 软缩进
vim.opt.shiftwidth = 4     -- 缩进宽度
vim.opt.smartindent = true -- 智能缩进
vim.opt.expandtab = true   -- 使用空格代替制表符

-- 搜索
vim.opt.hlsearch = true   -- 搜索时高亮显示匹配项
vim.opt.incsearch = true  -- 搜索时实时显示匹配项
vim.opt.smartcase = true  -- 搜索时智能大小写
vim.opt.ignorecase = true -- 搜索时忽略大小写

-- 外观
vim.opt.termguicolors = true -- 启用 24 位颜色
vim.opt.cursorline = true    -- 高亮当前行

-- 状态栏
vim.opt.laststatus = 3              -- 全局状态栏
vim.opt.statusline = "%<%f%m%r%h%w" -- 状态栏显示文件名、修改状态、只读状态、隐藏文件、窗口标题

-- Clipboard
vim.opt.clipboard = "unnamedplus" -- 使用系统剪贴板

-- Syntax Highlighting
vim.cmd("syntax on") -- 启用语法高亮


-- load lua subscripts
-- lua/*.lua
local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local lua_dir = script_dir .. "/lua"
-- 将 lua 目录加入 package.path，使 require() 能找到模块
package.path = lua_dir .. "/?.lua;" .. package.path
-- 同时加入 rtp，供 lazy.nvim 等插件使用
vim.opt.rtp:prepend(script_dir)
local lua_files = vim.fn.glob(lua_dir .. "/*.lua", false, true)
for _, file in ipairs(lua_files) do
    local module = vim.fn.fnamemodify(file, ":t:r")
    local ok, err = pcall(require, module)
    if not ok then
        vim.notify("Failed to load module: " .. module .. " - " .. err, vim.log.levels.ERROR)
    else
        vim.notify("Loaded module: " .. module, vim.log.levels.DEBUG)
    end
end
