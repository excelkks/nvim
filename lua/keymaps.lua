local keymap = vim.keymap.set

local function noremap(mode, lhs, rhs)
    local opts = { noremap = true }
    keymap(mode, lhs, rhs, opts)
end

local function wsplit(dir)
    vim.ui.input({ prompt = "split open: ", completion = "file" }, function(name)
        if name == nil then
            return nil
        else
            if dir == "up" then
                vim.opt.splitbelow = false
                vim.cmd("split " .. name)
                vim.opt.splitbelow = true
            elseif dir == "down" then
                vim.opt.splitbelow = true
                vim.cmd("split " .. name)
            elseif dir == "left" then
                vim.opt.splitright = false
                vim.cmd("vsplit " .. name)
                vim.opt.splitright = true
            elseif dir == "right" then
                vim.opt.splitright = true
                vim.cmd("vsplit " .. name)
            else
                error("invalid split directory " .. dir)
            end
        end
    end)
end

-- Remap space as leader key
noremap("", "<space>", "<Nop>")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

noremap("n", "<leader>w", "<cmd>w<CR>")

-- open init.lua
local config_file = vim.fn.stdpath("config")
noremap("n", "<leader>rc", ":e " .. config_file .. "<CR>")

-- split window
noremap("n", "sh", function() wsplit("left") end)
noremap("n", "sj", function() wsplit("down") end)
noremap("n", "sk", function() wsplit("up") end)
noremap("n", "sl", function() wsplit("right") end)

-- window navigation
noremap("n", "<C-h>", "<C-w>h")
noremap("n", "<C-j>", "<C-w>j")
noremap("n", "<C-k>", "<C-w>k")
noremap("n", "<C-l>", "<C-w>l")

-- Navigate buffers
noremap("n", "<S-l>", ":bnext<CR>")
noremap("n", "<S-h>", ":bprevious<CR>")

-- Insert
-- Press jk fast to enter
noremap("i", "jk", "<ESC>")

-- Visual
-- Stay in indent mode
noremap("v", "<", "<gv")
noremap("v", ">", ">gv")

-- Move test up and down
noremap("v", "<A-j>", ":m .+1<CR>==")
noremap("v", "<A-k>", ":m .-2<CR>==")
noremap("v", "p", '"_dP')

-- Visual Block --
-- Move text up and down
noremap("x", "J", ":move '>+1<CR>gv-gv")
noremap("x", "K", ":move '<-2<CR>gv-gv")
noremap("x", "<A-j>", ":move '>+1<CR>gv-gv")
noremap("x", "<A-k>", ":move '<-2<CR>gv-gv")

-- Terminal
-- Better terminal navigation
noremap("t", "<C-h>", "<C-\\><C-N><C-w>h")
noremap("t", "<C-j>", "<C-\\><C-N><C-w>j")
noremap("t", "<C-k>", "<C-\\><C-N><C-w>k")
noremap("t", "<C-l>", "<C-\\><C-N><C-w>l")
noremap("t", "<C-o>", "<C-\\><C-N>")

-- Command
noremap("c", "jk", "<C-c>")
noremap("c", "<C-b>", "<Left>")
noremap("c", "<C-f>", "<Right>")
noremap("c", "<C-a>", "<Home>")
noremap("c", "<C-e>", "<End>")
noremap("c", "<C-p>", "<Up>")
noremap("c", "<C-n>", "<Down>")
noremap("c", "<C-k>", "<C-\\>e strpart(getcmdline(), 0, getcmdpos() - 1)<CR>")

-- resize window
noremap("n", "<Up>", function() vim.cmd("resize +2") end)
noremap("n", "<Down>", function() vim.cmd("resize -2") end)
noremap("n", "<Left>", function() vim.cmd("vertical resize -2") end)
noremap("n", "<Right>", function() vim.cmd("vertical resize +2") end)
