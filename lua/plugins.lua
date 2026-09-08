vim.pack.add({
  "https://github.com/Mofiqul/vscode.nvim",
})

require("vscode").setup({
    style = "dark",
    transparent = false,
})

vim.cmd.colorscheme("vscode")
