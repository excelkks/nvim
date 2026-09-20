local M = { buf = nil }

local TERM_HEIGHT = 14

-- 关闭给定的终端窗口（若可见），保留 buffer
local function close_window(buf)
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

function M.toggle()
  local buf = M.buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      -- 已可见 -> 收起（关闭窗口，进程继续）
      vim.api.nvim_win_close(win, true)
      return
    end
    -- buffer 还在但窗口隐藏 -> 重新在底部展开
    vim.cmd("belowright sbuffer " .. buf)
    vim.cmd("resize " .. TERM_HEIGHT)
    vim.cmd("startinsert")
    return
  end

  -- 首次：底部新建一个终端 buffer
  vim.cmd("belowright terminal " .. vim.fn.fnameescape(vim.o.shell))
  M.buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_height(0, TERM_HEIGHT)
  vim.cmd("startinsert")
end

-- 在普通 buffer 里：开/关终端
vim.keymap.set("n", "<C-~>", M.toggle, { desc = "Toggle terminal (panel)" })

-- 终端聚焦时：Ctrl+` 退出终端模式并收起
vim.keymap.set("t", "<C-~>", "<C-\\><C-N><Cmd>lua vim.schedule(require('terminal-toggle').toggle)<CR>",
  { noremap = true, desc = "Toggle terminal (panel)" })

vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle terminal (panel)" })

return M
