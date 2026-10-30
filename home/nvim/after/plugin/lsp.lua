local lsp = require("lsp-zero")

-- Use the recommended preset
lsp.preset("recommended")

-- ---------------------------
-- Mason for LSP installation
-- ---------------------------
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "ts_ls", "lua_ls" }, -- add servers you need
    automatic_installation = true,
})

-- ---------------------------
-- Server-specific configs
-- ---------------------------
vim.lsp.config("ts_ls", {})

-- Lua LSP setup (replaces nvim_workspace)
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
        },
    },
})

-- ---------------------------
-- nvim-cmp setup (manual now)
-- ---------------------------
local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = false }), -- ✅ Enter to confirm
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
        { name = 'luasnip' },
    },
})

-- ---------------------------
-- Preferences
-- ---------------------------
lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn  = 'W',
        hint  = 'H',
        info  = 'I',
    }
})

-- ---------------------------
-- Keymaps
-- ---------------------------
lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
end)

-- ---------------------------
-- Finalize LSP
-- ---------------------------
lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
})

-- ---------------------------
-- GLSL filetypes
-- ---------------------------
vim.cmd [[
  autocmd BufRead,BufNewFile *.vs setfiletype glsl
  autocmd BufRead,BufNewFile *.fs setfiletype glsl
]]

