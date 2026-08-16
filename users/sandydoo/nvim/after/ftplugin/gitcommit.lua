-- Disable auto-wrapping of commit messages (overrides nvim's default textwidth=72)
vim.opt_local.textwidth = 0

-- Highlight characters past 50/72 on the first line (commit subject)
local function setup_commit_highlight()
  -- Match characters beyond 50 on first line (lighter warning)
  vim.fn.matchadd('ErrorMsg', '\\%1l\\%>50v.*', 10)
  -- Match characters beyond 72 on first line (stronger error)
  vim.fn.matchadd('WarningMsg', '\\%1l\\%>72v.*', 11)
end

-- Set up highlighting when buffer is loaded
vim.api.nvim_create_autocmd('BufWinEnter', {
  buffer = 0,
  callback = setup_commit_highlight,
})
