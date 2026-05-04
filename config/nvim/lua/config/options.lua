-- OPTIONS
local set = vim.opt

--line nums
set.relativenumber = true
set.number = true
set.wrap = false

-- indentation and tabs
set.tabstop = 4
set.shiftwidth = 4
set.softtabstop = 4
set.autoindent = true
set.expandtab = true

-- search settings
set.ignorecase = true
set.smartcase = true
set.incsearch = true
set.hlsearch = true

-- appearance
set.termguicolors = true
set.background = "dark"
set.signcolumn = "yes"

-- cursor line
set.cursorline = true

-- 80th column
set.colorcolumn = "80"

-- clipboard
set.clipboard:append("unnamedplus")

-- backspace
set.backspace = "indent,eol,start"

-- split windows
set.splitbelow = true
set.splitright = true

-- dw/diw/ciw works on full-word
set.iskeyword:append("-")

-- keep cursor at least 8 rows from top/bot
set.scrolloff = 16
set.sidescrolloff = 10

-- undo dir settings
set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.config/nvim/.undodir"
set.undofile = true

set.updatetime = 50

