-- Multi-keyword highlight:
--   <leader>hh  toggle highlight of the word under cursor / visual selection
--   <leader>hc  clear all highlights

local M = {}

local matches = {}  -- keyword -> match id in the current window
local keywords = {} -- ordered list of active keywords

-- Derive HLWord from the active colorscheme so it stays consistent with the
-- theme (instead of hardcoding One Dark colors that clash with vscode.dark).
local function refresh_hl()
  local visual = vim.api.nvim_get_hl(0, { name = "Visual", link = true })
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = true })
  vim.api.nvim_set_hl(0, "HLWord", {
    bg = visual.bg or "#555555",
    fg = normal.fg or "#ffffff",
  })
end
refresh_hl()
-- Re-derive if the user switches colorscheme at runtime
vim.api.nvim_create_autocmd("ColorScheme", { callback = refresh_hl })

local function escape_pattern(s)
  return vim.fn.escape(s, "\\/.*$^~[]")
end

local function clear_matches()
  for _, id in pairs(matches) do
    pcall(vim.fn.matchdelete, id)
  end
  matches = {}
end

local function apply()
  clear_matches()
  for _, kw in ipairs(keywords) do
    local ok, id = pcall(vim.fn.matchadd, "HLWord", escape_pattern(kw))
    if ok then
      matches[kw] = id
    end
  end
end

local function toggle(kw)
  if kw == "" then
    return
  end
  for i, k in ipairs(keywords) do
    if k == kw then
      table.remove(keywords, i)
      apply()
      return
    end
  end
  table.insert(keywords, kw)
  apply()
end

function M.toggle_word()
  toggle(vim.fn.expand("<cword>"))
end

local function get_visual_selection()
  local mode = vim.fn.visualmode()
  if mode == "" then
    return ""
  end
  local region = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = mode })
  return table.concat(region, "\n")
end

function M.toggle_selection()
  local text = get_visual_selection()
  if text == "" then
    text = vim.fn.expand("<cword>")
  end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then
    return
  end
  if text:find("\n") then
    vim.notify("hl-words: 不支持多行选择", vim.log.levels.WARN)
    return
  end
  toggle(text)
end

function M.clear()
  keywords = {}
  clear_matches()
end

vim.keymap.set("n", "<leader>hh", M.toggle_word, { desc = "Toggle highlight word" })
vim.keymap.set(
  "v",
  "<leader>hh",
  "<Esc>:lua require('hl-words').toggle_selection()<CR>",
  { noremap = true, silent = true, desc = "Toggle highlight selection" }
)
vim.keymap.set("n", "<leader>hc", M.clear, { desc = "Clear all highlights" })

-- Keep highlights in sync across buffers/windows
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  callback = apply,
})

return M
