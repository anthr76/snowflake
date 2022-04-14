local map = vim.api.nvim_set_keymap

-- LSPSaga Mappings
map('n', '<leader>cd', '<cmd>Lspsaga show_line_diagnostics<cr>', { noremap=true, silent=true })
map('n', '[e', '<cmd>Lspsaga diagnostic_jump_next<cr>', { noremap=true, silent=true })
map('n', ']e', '<cmd>Lspsaga diagnostic_jump_prev<cr>', { noremap=true, silent=true })
map('n', '<A-d>', '<cmd>Lspsaga open_floaterm<cr>', { noremap=true, silent=true })
map('t', '<A-d>', '<C-\\><C-n><cmd>Lspsaga close_floaterm<cr>', { noremap = true, silent=true })

-- Telescope Mappings

map('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { noremap=true })
map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { noremap=true })
map('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { noremap=true })
map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { noremap=true })

-- Map Leader

vim.g.mapleader = ','

vim.o.termguicolors  = true               -- Enable 24 bit colors
vim.o.secure         = true               -- No commands in .nvimrc, .exrc
vim.o.hidden         = true               -- Allow hidden buffers
vim.o.spell          = true               -- Enable spell checking
vim.o.spelllang      = 'en'               -- Spell checking language
vim.o.backup         = false              -- Do not keep backup file after write
vim.o.writebackup    = true               -- Create backup and keep until file is written
vim.o.swapfile       = false              -- Disable swap files
vim.o.startofline    = false              -- Try to preserve cursor column
vim.o.fileformat     = 'unix'             -- Use unix EOL
vim.o.encoding       = 'utf-8'            -- Use UTF-8
vim.o.fileencoding   = 'utf-8'            -- Use UTF-8
vim.o.nrformats      = 'bin,hex,alpha'    -- Number formats for increment/decrement
vim.o.backspace      = 'indent,eol,start' -- Backspace deletes across lines and indents
vim.o.history        = 100                -- History size
vim.o.matchpairs     = '(:),{:},[:],<:>'  -- Characters that form pairs
vim.o.completeopt    = 'menu,menuone,noselect'
vim.o.clipboard      = 'unnamedplus'      -- Sets the clipboard

vim.o.tabstop     = 4     -- Number of visual spaces per tab
vim.o.softtabstop = 4     -- Number of spaces in tab
vim.o.shiftwidth  = 4     -- Indent width
vim.o.shiftround  = true  -- Round indents to specified indent width
vim.o.expandtab   = true  -- Use spaces for tabs
vim.o.joinspaces  = false -- Use one space (not two) after punctuation and when joining

vim.o.incsearch  = true      -- Enable incremental search
vim.o.hlsearch   = true      -- Highlight search matches
vim.o.ignorecase = true      -- Case-insensitive search by default
vim.o.smartcase  = true      -- Switch to case-sensitive search if there's capital letter
vim.o.inccommand = 'nosplit' -- Live substitute preview

vim.o.number     = true    -- Show line numbers
vim.o.showmode   = false   -- Don't show mode
vim.o.listchars = 'eol:↲,nbsp:␣,tab:▸→,extends:❯,precedes:❮,trail:∙' -- Characters to display for invisible Characters
vim.o.fillchars  = 'eob: ' -- Customise fill characters
