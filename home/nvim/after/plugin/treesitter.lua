-- nvim-treesitter (main branch) doesn't auto-enable highlighting.
-- pcall: silently skip filetypes with no installed parser.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})
