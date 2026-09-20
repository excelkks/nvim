local state = require("telescope.state")
local builtin = require("telescope.builtin")

require("telescope").setup({
  defaults = {
    -- 结果在上、预览在下（上下堆叠），而非默认的左右并排
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        prompt_position = "top",
        width = 0.9,
        height = 0.9,
        -- 窗口太矮时直接不显示预览，避免把结果挤没
        preview_cutoff = 20,
      },
    },
    cache_picker = {
      num_pickers = 10,
    },
  },
})

-- live_grep 会用 highlighter_only 这个 sorter 对"路径:行号:内容"整行做模糊高亮，
-- 导致路径里的字符（如 TLibCom**mon**）也被 `TelescopeMatching` 标成命中。
-- 该 sorter 只被 live_grep 使用（grep_string/其余走 generic_sorter），安全覆盖它，
-- 让高亮只落在正文部分。社区 empty()/only_sort_text 方案要么关掉高亮要么够不到这里。
pcall(function()
  local sorters = require("telescope.sorters")
  local fzy = require("telescope.algos.fzy")

  sorters.highlighter_only = function()
    return sorters.Sorter:new {
      scoring_function = function()
        return 1
      end,
      -- 高亮：先定位正文起点（跳过 "路径:行号:列:" 这段头）。
      -- 优先高亮正文里「输入原文」的字面命中（忽略大小写），符号你直接搜的这个词本身；
      -- 找不到字面命中（说明输入是正则之类）才回退 fzy 模糊。
      highlighter = function(_, prompt, display)
        if not prompt or prompt == "" then
          return
        end
        local text_start = 1
        local m1 = display:find(":%d+:%d+:", 1)
        local seg = m1 and display:sub(m1):match("^:%d+:%d+:")
        if seg then
          text_start = m1 + #seg
        else
          local m2 = display:find(":%d+:", 1)
          local seg2 = m2 and display:sub(m2):match("^:%d+:")
          if seg2 then
            text_start = m2 + #seg2
          end
        end
        local text = text_start > 1 and display:sub(text_start) or display
        if text == "" then
          return
        end
        local out = {}
        -- 1) 字面命中：text 里所有等于 prompt(忽略大小写) 的位置
        local needle = prompt:lower()
        local hay = text:lower()
        if #needle > 0 then
          local s = 1
          while true do
            local found = hay:find(needle, s, true)
            if not found then
              break
            end
            for i = found, found + #needle - 1 do
              out[#out + 1] = i + text_start - 1
            end
            s = found + #needle
          end
        end
        -- 2) 无字面命中才回退模糊
        if #out == 0 and #needle > 0 then
          for _, p in ipairs(fzy.positions(prompt, text)) do
            out[#out + 1] = p + text_start - 1
          end
        end
        return out
      end,
    }
  end
end)

-- Most recently created picker's object. Telescope registers each open picker
-- under its prompt buffer; the newest one has the highest bufnr.
local function last_opened_picker()
  local highest = 0
  for _, b in ipairs(state.get_existing_prompt_bufnrs()) do
    if b > highest then
      highest = b
    end
  end
  if highest == 0 then
    return nil
  end
  return state.get_status(highest).picker
end

-- Remember the picker object each command last opened, keyed by our own label.
-- Matching by object identity (not by prompt_title, which telescope can change)
-- means this never breaks across telescope updates.
local last_by_label = {}

-- Reopen the cached search opened under this same label, or start a new one.
local function resume_or_run(label, run)
  local prev = last_by_label[label]
  if prev then
    local cached = state.get_global_key("cached_pickers") or {}
    for i, picker in ipairs(cached) do
      if picker == prev then
        return builtin.resume({ cache_index = i })
      end
    end
    -- previous picker was evicted/cleared, not cached anymore
    last_by_label[label] = nil
  end
  run()
  last_by_label[label] = last_opened_picker()
end

-- 运行并把"最新打开的那个 picker"记到 last_by_label
local function run_and_remember(label, run, saved)
  run(saved)
  last_by_label[label] = last_opened_picker()
end

-- live_grep 专用 "resume"：不依赖 builtin.resume（它对依赖后台 rg job 的 picker，
-- 恢复历史查询时往往不会重跑任务，结果像空搜索）。这里直接取出上次搜的查询
-- default_text，重新自己跑一次 live_grep，rg 必定重跑，即"恢复上次搜索结果"。
local function resume_grep(label, run)
  local prev = last_by_label[label]
  if prev then
    local cached = state.get_global_key("cached_pickers") or {}
    for _, picker in ipairs(cached) do
      if picker == prev then
        -- 缓存里 default_text 即用户最后输入的查询
        local q = picker.default_text or ""
        return run_and_remember(label, run, { default_text = q })
      end
    end
  end
  last_by_label[label] = nil
  return run_and_remember(label, run, { default_text = "" })
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
  resume_grep("Live Grep", function(saved)
    builtin.live_grep({
      default_text = saved.default_text,
      additional_args = project_ignore_args(),
    })
  end)
end, { desc = "Live grep (resume last query)" })

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
