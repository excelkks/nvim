local state = require("telescope.state")
local builtin = require("telescope.builtin")

require("telescope").setup({
  defaults = {
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        prompt_position = "top",
        width = 0.9,
        height = 0.9,
        preview_cutoff = 20,
      },
    },
    cache_picker = {
      num_pickers = 20, -- 确保缓存池足够大
    },
  },
})

-- ===================================================================
-- 核心修复：精准捕获 Picker 句柄，保证回车打开文件后依然能稳固 Resume
-- ===================================================================

local last_by_label = {}

-- 绑定该 Picker：在 Picker 初始化的第一时间（attach_mappings 执行时）就把状态绑死
local function bind_picker(label, opts)
  opts = opts or {}
  local user_attach = opts.attach_mappings
  opts.attach_mappings = function(prompt_bufnr, map)
    -- 获取当前的 picker 对象并强行记录到 label 映射表中
    local picker = state.get_status(prompt_bufnr).picker
    if picker then
      last_by_label[label] = picker
    end

    if user_attach then
      return user_attach(prompt_bufnr, map)
    end
    return true
  end
  return opts
end

-- 通用 Resume 逻辑
local function resume_or_run(label, run_func)
  local prev = last_by_label[label]
  if prev then
    local cached = state.get_global_key("cached_pickers") or {}
    for i, picker in ipairs(cached) do
      if picker == prev then
        -- 缓存命中：完美恢复上次搜索词、选项列表及光标指示行
        return builtin.resume({ cache_index = i })
      end
    end
    -- 若已被清理出缓存池，清空无效引用
    last_by_label[label] = nil
  end

  -- 初次运行或缓存失效时重新跑，并挂载绑定钩子
  run_func()
end

-- 获取 Visual 模式选中文本（修复选区未及时更新问题）
local function get_visual_selection()
  vim.cmd("normal! \27")
  local mode = vim.fn.visualmode()
  if mode == "" then
    return ""
  end
  local region = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = mode })
  return table.concat(region, "\n")
end

-- 项目本地 .vscode/rgignore 过滤参数
local function project_ignore_args()
  local ignore_file = vim.fn.getcwd() .. "/.vscode/rgignore"
  if vim.fn.filereadable(ignore_file) == 1 then
    return { "--ignore-file", ignore_file }
  end
  return {}
end

-- ===================================================================
-- 快捷键映射
-- ===================================================================
local keymap = vim.keymap.set

-- 1. Find Files 文件查找（选中任何文件回车后，再次 <leader>ff 都能准确恢复状态和光标）
keymap("n", "<leader>ff", function()
  resume_or_run("Find Files", function()
    builtin.find_files(bind_picker("Find Files", {
      find_command = vim.list_extend({ "rg", "--files", "--color", "never" }, project_ignore_args()),
    }))
  end)
end, { desc = "Find files (Resume)" })

-- 2. Live Grep 全局搜索（Normal 模式）
keymap("n", "<leader>fg", function()
  resume_or_run("Live Grep", function()
    builtin.live_grep(bind_picker("Live Grep", {
      additional_args = project_ignore_args(),
    }))
  end)
end, { desc = "Live grep (Resume)" })

-- 3. Live Grep 选中文本搜索（Visual 模式）
keymap("v", "<leader>fg", function()
  local text = get_visual_selection()
  if text == "" then
    return
  end
  builtin.live_grep(bind_picker("Live Grep Visual", {
    default_text = text,
    additional_args = vim.list_extend({ "--fixed-strings" }, project_ignore_args()),
  }))
end, { desc = "Live grep visual selection" })

-- 4. Buffers
keymap("n", "<leader>fb", function()
  resume_or_run("Buffers", function()
    builtin.buffers(bind_picker("Buffers"))
  end)
end, { desc = "Buffers (Resume)" })

-- 5. Oldfiles
keymap("n", "<leader>fo", function()
  resume_or_run("Oldfiles", function()
    builtin.oldfiles(bind_picker("Oldfiles"))
  end)
end, { desc = "Recent files (Resume)" })

-- 6. Help
keymap("n", "<leader>fh", function()
  resume_or_run("Help", function()
    builtin.help_tags(bind_picker("Help"))
  end)
end, { desc = "Help tags (Resume)" })

-- 7. Git Commits
keymap("n", "<leader>fc", function()
  resume_or_run("Git Commits", function()
    builtin.git_commits(bind_picker("Git Commits"))
  end)
end, { desc = "Git commits (Resume)" })

-- 8. Git Status
keymap("n", "<leader>fs", function()
  resume_or_run("Git Status", function()
    builtin.git_status(bind_picker("Git Status"))
  end)
end, { desc = "Git status (Resume)" })

-- 9. 编辑项目本地 .vscode/rgignore
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

  local group = vim.api.nvim_create_augroup("RgIgnoreAutosave_" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
        vim.cmd("silent write!")
      end
    end,
  })
end, { desc = "Edit project .vscode/rgignore" })
