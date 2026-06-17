-- lsp.lua
-- LSP 配置：mason 管理安装，nvim-lspconfig 配置各语言服务器
-- 所有 require 包裹 pcall，插件未安装时静默跳过

local ok_mason, mason = pcall(require, "mason")
local ok_mlsp, mason_lspconfig = pcall(require, "mason-lspconfig")
local ok_lcfg, lspconfig = pcall(require, "lspconfig")
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

if not ok_mason or not ok_mlsp or not ok_lcfg or not ok_cmp then
    vim.notify("LSP 插件未安装，执行 :Lazy sync 后重启 nvim", vim.log.levels.WARN)
    return
end

-- mason：LSP 安装管理器（自动安装缺失的服务器）
mason.setup()
mason_lspconfig.setup({
    ensure_installed = {
        "tsserver",
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
local servers = {
    "tsserver",
    "pyright",
    "rust_analyzer",
    "clangd",
    "gopls",
    "lua_ls",
    "bashls",
    "taplo",
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
