vim.diagnostic.config({ float = { border = "rounded" } })

vim.lsp.config("clangd", {
	cmd = {
		"clangd",
		"--background-index",
		"--header-insertion=iwyu",
	},

	filetypes = {
		"c",
		"cpp",
		"objc",
		"objcpp",
	},

	root_markers = {
		"compile_commands.json",
		"compile_flags.txt",
		".git",
    ".vscode",
	},
})

vim.lsp.enable("clangd")

local function on_attach(bufnr)
	local opts = { buffer = bufnr, noremap = true, silent = true }

	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)

	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	vim.keymap.set("n", "<leader>f", function()
		vim.lsp.buf.format({ async = true })
	end, opts)

	vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
	vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
	vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		on_attach(args.buf)
		if client and client.name == "clangd" then
			vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
		end
	end,
})
