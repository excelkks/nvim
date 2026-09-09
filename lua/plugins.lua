vim.pack.add({
  "https://github.com/Mofiqul/vscode.nvim",
  "https://github.com/Saghen/blink.lib",
  "https://github.com/Saghen/blink.cmp",
  "https://github.com/lewis6991/gitsigns.nvim",
})

require("vscode").setup({
    style = "dark",
    transparent = false,
})

vim.cmd.colorscheme("vscode")
