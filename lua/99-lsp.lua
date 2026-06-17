-- lsp.lua
-- LSP 配置：mason 管理安装，vim.lsp.config 配置各语言服务器（nvim 0.11+）
-- 所有 require 包裹 pcall，插件未安装时静默跳过

local ok_mason, mason = pcall(require, "mason")
local ok_mlsp, mason_lspconfig = pcall(require, "mason-lspconfig")
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

if not ok_mason or not ok_mlsp or not ok_cmp then
    vim.notify("LSP 插件未安装，执行 :Lazy sync 后重启 nvim", vim.log.levels.WARN)
    return
end

-- mason：LSP 安装管理器（自动安装缺失的服务器）
mason.setup()
mason_lspconfig.setup({
    ensure_installed = {
        "ts_ls",
        "pyright",
        "rust_analyzer",
        "clangd",
        "gopls",
        "lua_ls",
        "bashls",
        "taplo",
    },
    automatic_installation = true,
})

local caps = cmp_nvim_lsp.default_capabilities()

local on_attach = function(_, bufnr)
    local map = function(k, f) vim.keymap.set("n", k, f, { buffer = bufnr, silent = true }) end
    map("gd",          vim.lsp.buf.definition)
    map("gD",          vim.lsp.buf.declaration)
    map("gi",          vim.lsp.buf.implementation)
    map("gr",          vim.lsp.buf.references)
    map("K",           vim.lsp.buf.hover)
    map("<C-k>",       vim.lsp.buf.signature_help)
    map("<leader>rn",  vim.lsp.buf.rename)
    map("<leader>ca",  vim.lsp.buf.code_action)
    map("<leader>e",   vim.diagnostic.open_float)
    map("[d",          vim.diagnostic.goto_prev)
    map("]d",          vim.diagnostic.goto_next)
end

-- 只启动可执行的服务器（系统 PATH 或 mason bin 中存在时）
-- nvim 0.11+ 使用 vim.lsp.config() 替代 require("lspconfig")
local servers = {
    "ts_ls",
    "pyright",
    "rust_analyzer",
    "clangd",
    "gopls",
    "lua_ls",
    "bashls",
    "taplo",
}

for _, srv in ipairs(servers) do
    local ok, result = pcall(function()
        local cfg = vim.lsp.config[srv]
        if not cfg then return end
        -- cmd: table = 外部命令, function = 内建 LSP 模块
        local cmd = type(cfg.cmd) == "function" and cfg.cmd() or cfg.cmd
        -- 外部分命令需检查可执行性，内建模块直接启用
        if type(cmd) == "table" and cmd[1] then
            if vim.fn.executable(cmd[1]) ~= 1 then return end
        end
        vim.lsp.config(srv, { on_attach = on_attach, capabilities = caps })
        vim.lsp.enable(srv)
    end)
    if not ok then
        vim.notify("LSP " .. srv .. " setup failed: " .. tostring(result), vim.log.levels.WARN)
    end
end
