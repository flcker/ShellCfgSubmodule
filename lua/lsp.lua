-- lsp.lua
-- LSP 配置：mason 管理安装，nvim-lspconfig 配置各语言服务器

-- mason：LSP 安装管理器（自动安装缺失的服务器）
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "tsserver",
        "pyright",
        "rust_analyzer",
        "clangd",
        "gopls",
        "lua_ls",
    },
    automatic_installation = true,
})

local lspconfig = require("lspconfig")
local caps = require("cmp_nvim_lsp").default_capabilities()

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
local servers = {
    "tsserver",
    "pyright",
    "rust_analyzer",
    "clangd",
    "gopls",
    "lua_ls",
}

for _, srv in ipairs(servers) do
    local ok, cfg = pcall(function() return lspconfig[srv] end)
    if not ok then goto continue end
    local default_cmd = cfg.document_config and cfg.document_config.default_config and cfg.document_config.default_config.cmd
    if default_cmd and vim.fn.executable(default_cmd[1]) == 1 then
        cfg.setup({ on_attach = on_attach, capabilities = caps })
    end
    ::continue::
end
