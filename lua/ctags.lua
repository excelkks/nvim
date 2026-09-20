-- Project tags: :Ctags generates .vscode/tags and wires it into 'tags'

-- Project root = outermost ancestor of the current buffer that is a git repo
-- (works even when nvim was launched from another directory). Uses the same
-- "outermost" rule as rooter.nvim so the two never disagree on nested repos.
-- Fall back to cwd, e.g. for non-git projects opened in place.
local function project_root()
  local bufname = vim.api.nvim_buf_get_name(0)
  local base
  if bufname ~= "" then
    base = vim.fn.isdirectory(bufname) == 1 and bufname or vim.fn.fnamemodify(bufname, ":p:h")
  else
    base = vim.fn.getcwd()
  end
  local dir = vim.fn.fnamemodify(base, ":p")
  local found = nil
  while true do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then
      found = dir -- keep walking: outermost (highest) git ancestor wins
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return found or vim.fn.getcwd()
end

-- Point 'tags' at the current project's .vscode/tags (absolute path, so it works
-- from any subdirectory). Fall back to defaults when the file doesn't exist.
local last_root = nil
local function update_tags_option(force)
  local root = project_root()
  if not force and root == last_root then
    return
  end
  last_root = root
  local file = root .. "/.vscode/tags"
  if vim.fn.filereadable(file) == 1 then
    vim.opt.tags = { file, "./tags", "tags" }
  else
    vim.opt.tags = { "./tags", "tags" }
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "BufEnter" }, {
  callback = function()
    update_tags_option()
  end,
})

vim.api.nvim_create_user_command("Ctags", function()
  if vim.fn.executable("ctags") ~= 1 then
    vim.notify(
      "ctags not found — install it with: sudo apt install universal-ctags",
      vim.log.levels.ERROR
    )
    return
  end
  local root = project_root()
  local dir = root .. "/.vscode"
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  local file = dir .. "/tags"
  vim.system(
    {
      "ctags",
      "-R",
      "--exclude=.git",
      "--exclude=.vscode",
      "--exclude=node_modules",
      "-f",
      "tags",
      "..",
    },
    { cwd = dir },
    function(out)
      vim.schedule(function()
        if out.code == 0 then
          update_tags_option(true)
          vim.notify("Tags generated: " .. file)
        else
          vim.notify("ctags failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
        end
      end)
    end
  )
end, { desc = "Generate tags into .vscode/tags" })
