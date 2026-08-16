return {
  { "kepano/flexoki-neovim" },

  {
    "afonsofrancof/OSC11.nvim",
    priority = 1000,
    opts = {
      on_dark = function()
        vim.api.nvim_set_option_value("background", "dark", {})
      end,
      on_light = function()
        vim.api.nvim_set_option_value("background", "light", {})
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.schedule(function()
          if vim.o.background == "light" then
            vim.cmd("colorscheme flexoki-light")
          else
            vim.cmd("colorscheme flexoki-dark")
          end
        end)
      end,
    },
  },
}
