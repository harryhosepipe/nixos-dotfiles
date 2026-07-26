local MiniClue = require("mini.clue")

MiniClue.setup({
	triggers = {
		{ mode = { "n", "x" }, keys = "<Leader>" },
		{ mode = { "n", "x" }, keys = "g" },
		{ mode = { "n", "x" }, keys = "'" },
		{ mode = { "n", "x" }, keys = "`" },
		{ mode = { "n", "x" }, keys = '"' },
		{ mode = { "i", "c" }, keys = "<C-r>" },
		{ mode = "i", keys = "<C-x>" },
		{ mode = "n", keys = "<C-w>" },
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },
		{ mode = { "n", "x" }, keys = "z" },
	},

	clues = {
		{ mode = "n", keys = "<Leader>f", desc = "+Find" },
		{ mode = "n", keys = "<Leader>g", desc = "+Git" },
		{ mode = "n", keys = "<Leader>h", desc = "+Harpoon" },
		{ mode = "n", keys = "<Leader>r", desc = "+Restart/Replace" },
		{ mode = "n", keys = "<Leader>v", desc = "+View" },
		{ mode = "n", keys = "<Leader>x", desc = "+Explore/Diagnostics" },

		MiniClue.gen_clues.builtin_completion(),
		MiniClue.gen_clues.g(),
		MiniClue.gen_clues.marks(),
		MiniClue.gen_clues.registers(),
		MiniClue.gen_clues.windows(),
		MiniClue.gen_clues.z(),
		MiniClue.gen_clues.square_brackets(),
	},

	window = {
		delay = 300,
		config = {
			width = "auto",
		},
	},
})
