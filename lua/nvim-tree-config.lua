-- File explorer: nvim-tree.lua
--   <leader>e  toggle the tree (focused)
--   <leader>E  focus the tree without closing it
--
-- Sized for a log-heavy workflow: the tree is *not* shown on startup and
-- hides itself only when you focus a file window, so it never disturbs
-- streaming big logs. Filtered to skip .git/.vscode noise.

-- Don't auto-open the tree on startup (keeps big-file log viewing clean)
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3

require("nvim-tree").setup({
  -- 大文件模式 / 常规目录过滤
  filters = {
    dotfiles = false,
    custom = { "^.git$", "^.vscode$", "^node_modules$", "__pycache__" },
  },
  disable_netrw = true, -- 用 nvim-tree 取代内置 netrw
  hijack_netrw = true,
  auto_reload_on_write = true,
  view = {
    width = 32,
    side = "left",
    preserve_window_proportions = true,
    number = false,
    relativenumber = false,
  },
  renderer = {
    root_folder_label = ":t", -- 只显示仓库名，不显示整条路径
    highlight_git = false,    -- log 场景不折腾，避免 git 状态拖慢
    icons = {
      show = { git = false, folder = false, file = true, folder_arrow = false },
    },
  },
  update_focused_file = {
    enable = false,           -- 不自动跟随当前文件，减少大目录下的事件开销
  },
  git = { enable = false },   -- 关掉 git 集成，只用文件浏览
  actions = {
    open_file = { quit_on_open = false },
  },
})

local nmap = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<leader>e", function()
  vim.cmd("NvimTreeToggle")
end, "Toggle file explorer (nvim-tree)")

nmap("<leader>E", function()
  vim.cmd("NvimTreeFocus")
end, "Focus file explorer (nvim-tree)")