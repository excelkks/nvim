local state = require("telescope.state")
local builtin = require("telescope.builtin")

require("telescope").setup({
  defaults = {
    cache_picker = {
      num_pickers = 10,
    },
  },
})

-- Reopen the cached search of the same type, or start a new one
local function resume_or_run(prompt_title, run)
  local cached = state.get_global_key("cached_pickers") or {}
  for i, picker in ipairs(cached) do
    if picker.prompt_title == prompt_title then
      return builtin.resume({ cache_index = i })
    end
  end
  run()
end

-- 项目本地忽略规则：项目根有 .vscode/rgignore（gitignore 语法）时传给 rg
local function project_ignore_args()
  if vim.fn.filereadable(vim.fn.getcwd() .. "/.vscode/rgignore") == 1 then
    return { "--ignore-file", ".vscode/rgignore" }
  end
  return {}
end

local keymap = vim.keymap.set

keymap("n", "<leader>ff", function()
  resume_or_run("Find Files", function()
    builtin.find_files({
      find_command = vim.list_extend({ "rg", "--files", "--color", "never" }, project_ignore_args()),
    })
  end)
end, { desc = "Find files (resume)" })

keymap("n", "<leader>fg", function()
  resume_or_run("Live Grep", function()
    builtin.live_grep({ additional_args = project_ignore_args() })
  end)
end, { desc = "Live grep (resume)" })

local function get_visual_selection()
  local mode = vim.fn.visualmode()
  if mode == "" then
    return ""
  end
  local region = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = mode })
  return table.concat(region, "\n")
end

keymap("v", "<leader>fg", function()
  local text = get_visual_selection()
  if text == "" then
    return
  end
  builtin.live_grep({
    default_text = text,
    additional_args = vim.list_extend({ "--fixed-strings" }, project_ignore_args()),
  })
end, { desc = "Live grep selected text" })

keymap("n", "<leader>fb", function()
  resume_or_run("Buffers", builtin.buffers)
end, { desc = "Buffers (resume)" })

keymap("n", "<leader>fh", function()
  resume_or_run("Help", builtin.help_tags)
end, { desc = "Help tags (resume)" })

keymap("n", "<leader>fo", function()
  resume_or_run("Oldfiles", builtin.oldfiles)
end, { desc = "Recent files (resume)" })

keymap("n", "<leader>fc", function()
  resume_or_run("Git Commits", builtin.git_commits)
end, { desc = "Git commits (resume)" })

keymap("n", "<leader>fs", function()
  resume_or_run("Git Status", builtin.git_status)
end, { desc = "Git status (resume)" })

keymap("n", "<leader>fi", function()
  local dir = vim.fn.getcwd() .. "/.vscode"
  local file = dir .. "/rgignore"
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  if vim.fn.filereadable(file) == 0 then
    local f = io.open(file, "w")
    if f then
      f:close()
    end
  end

  vim.cmd("split " .. vim.fn.fnameescape(file))
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "gitignore"

  -- 改动即自动保存，这样 :q 时 buffer 已是未修改状态，可直接退出并销毁
  local function autosave()
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
      vim.cmd("silent write!")
    end
  end
  for _, event in ipairs({ "TextChanged", "TextChangedI", "InsertLeave" }) do
    vim.api.nvim_create_autocmd(event, { buffer = bufnr, callback = autosave })
  end
end, { desc = "Edit project .vscode/rgignore" })
