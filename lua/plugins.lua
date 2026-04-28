-- plugins.lua
-- Neovim plugins: LazyVim

-- Plugin manager: LazyVim
-- 自动安装 lazy.vim (https://github.com/folke/lazy.nvim)
-- data 目录为 `XDG_DATA_HOME` 默认为 `~/.local/share`(mac/linux) 或 `%localappdata%`
-- lazy.vim 会 clone 到 `nvim`(mac/linux) 或 `nvm-data`(windows)目录下
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        "--depth=1",       -- depth 1
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- plugin list
local plugins = {
    -- file tree (文件树)
    { "nvim-tree/nvim-tree.lua" },
    -- status line (状态栏)
    { "nvim-lualine/lualine.nvim" },
    -- completion (补全)
    { "hrsh7th/nvim-cmp" },
    -- treesitter (语法高亮)
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    -- web devicons (图标)
    { "nvim-tree/nvim-web-devicons" },
    -- markdown syntax
    { "plasticboy/vim-markdown" },
    -- LSP
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
}

require("lazy").setup(plugins)

-- plugin setup
-- nvim-tree
pcall(function()
    require("nvim-tree").setup({})
end)

-- lualine
pcall(function()
    require("lualine").setup({
        options = { theme = "auto" }
    })
end)

-- nvim-cmp
pcall(function()
    require("cmp").setup({
        sources = require("cmp").config.sources({
            { name = "nvim_lsp" },
            { name = "buffer" },
        }),
    })
end)

-- nvim-treesitter
pcall(function()
    require("nvim-treesitter.configs").setup({
        highlight = { enable = true }, -- 语法高亮
        indent = { enable = true },    -- 缩进高亮
    })
end)

-- vim-markdown
pcall(function()
    vim.cmd([[
        let g:vim_markdown_folding_disabled = 1
        let g:vim_markdown_folding_style_pythonic = 1
    ]])
end)
