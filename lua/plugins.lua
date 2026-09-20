vim.pack.add({
  "https://github.com/Mofiqul/vscode.nvim",
  "https://github.com/Saghen/blink.lib",
  "https://github.com/Saghen/blink.cmp",
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
