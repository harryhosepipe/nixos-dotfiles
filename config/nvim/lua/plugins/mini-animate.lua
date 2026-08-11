local MiniAnimate = require("mini.animate")

local snappy_timing = MiniAnimate.gen_timing.quadratic({
	duration = 100,
	easing = "out",
	unit = "total",
})

MiniAnimate.setup({
	cursor = {
		enable = true,
	},
	scroll = {
		timing = snappy_timing,
	},
	resize = {
		timing = snappy_timing,
	},
	open = {
		timing = snappy_timing,
	},
	close = {
		timing = snappy_timing,
	},
})
