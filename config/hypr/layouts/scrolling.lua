return function(hl, mainMod)
    hl.config({
        general = {
            layout = "scrolling",
        },
    })

    hl.config({
        scrolling = {
            column_width = 0.5,
            direction = "right",
            follow_focus = true,
            focus_fit_method = 1,
            follow_min_visible = 0.4,
            explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
            wrap_focus = true,
            wrap_swapcol = true,
        },
    })
end
