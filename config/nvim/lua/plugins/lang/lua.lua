return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {},
          },
        },
      },
    },
  },

  {
    {
      "stevearc/conform.nvim",
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
        },
      },
    },
  },
}
