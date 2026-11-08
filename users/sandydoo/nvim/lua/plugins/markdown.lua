return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local linter = require("lint").linters["markdownlint-cli2"]
      opts.linters["markdownlint-cli2"] = require("lint.util").wrap(linter, function(diagnostic)
        if not vim.startswith(diagnostic.message, "MD013/") then
          return diagnostic
        end
      end)
    end,
  },
}
