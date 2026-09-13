local cmp = require("blink.cmp")

-- Build the native fuzzy matcher if missing (no-op once built)
cmp.build():pwait()

cmp.setup({
  keymap = {
    preset = "super-tab",
    ["<CR>"] = { "accept", "fallback" },
  },
  appearance = {
    nerd_font_variant = "mono",
  },
  sources = {
    default = { "lsp", "path", "buffer" },
  },
})
