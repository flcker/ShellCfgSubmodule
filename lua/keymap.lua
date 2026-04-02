-- keymap.lua
-- 设置Neovim keymap, 使用方式：
-- 先按 leader 键（空格），松开后再按对应键触发
-- 例如 <leader>w：按 Space 松开，再按 w
-- 有超时时间（默认1000ms），超时未按则放弃

-- 设置快捷键映射 注意nvim的api是vim.keymap
-- 第一个参数是模式（n: normal, v: visual, i: insert, etc.）, 标识 keymap 的适用模式
-- 第二个参数是按键组合，第三个参数是映射的命令，第四个参数是选项
-- 例如: map("n", "<leader>w", ":w<CR>", opts) 表示在 normal 模式下，按 <leader>w 保存文件
local map = vim.keymap.set

-- 通用选项
-- noremap = true 表示不递归映射，silent = true 表示不显示命令执行结果
local opts = { noremap = true, silent = true }

-- 设置leader键为空格
vim.g.mapleader = " "

-- Save file
map("n", "<leader>w", ":w<CR>", opts)
-- Quit
map("n", "<leader>q", ":q<CR>", opts)
-- Save and quit
map("n", "<leader>wq", ":wq<CR>", opts)

-- File Tree
map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- Split Vertically
map("n", "<leader>sv", ":vsplit<CR>", opts)
-- Split Horizontally
map("n", "<leader>sh", ":split<CR>", opts)

-- Cancel Highlight
map("n", "<leader>nh", ":nohlsearch<CR>", opts)

-- Switch between panes
map("n", "<leader>h", "<C-w>h", opts)       -- 左
map("n", "<leader>j", "<C-w>j", opts)       -- 下
map("n", "<leader>k", "<C-w>k", opts)       -- 上
map("n", "<leader>l", "<C-w>l", opts)       -- 右
map("n", "<leader><Left>", "<C-w>h", opts)  -- 左
map("n", "<leader><Down>", "<C-w>j", opts)  -- 下
map("n", "<leader><Up>", "<C-w>k", opts)    -- 上
map("n", "<leader><Right>", "<C-w>l", opts) -- 右
