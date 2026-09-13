-- Auto-switch cwd to the project root (rooter.nvim)

require("rooter").setup({
  root_patterns = {
    ".git/",
    ".vscode/",
    ".hg/",
    ".svn/",
    ".root",
    ".project",
    "package.json",
    "Cargo.toml",
    "go.mod",
    "pyproject.toml",
    "pom.xml",
  },
  outermost = true,
  enable_cache = true,
  project_non_root = "", -- don't touch cwd when the file isn't inside a project
})
