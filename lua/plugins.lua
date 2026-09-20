vim.pack.add({
  "https://github.com/Mofiqul/vscode.nvim",
  {
    src = "https://github.com/Saghen/blink.cmp",
    -- Pin to stable v1 release line (v1.10.2) instead of main/v2-dev.
    version = "v1.10.2",
  },
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/wsdjeg/rooter.nvim",
  "https://github.com/nvim-tree/nvim-tree.lua",
})

require("vscode").setup({
    style = "light",
    transparent = false,
})

vim.cmd.colorscheme("vscode")
