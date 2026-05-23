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

    hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"))
    hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
    hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("swapcol l"))
    hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
    hl.bind(mainMod .. " + CTRL + comma", hl.dsp.layout("colresize -conf"))
    hl.bind(mainMod .. " + CTRL + period", hl.dsp.layout("colresize +conf"))
    hl.bind(mainMod .. " + backslash", hl.dsp.layout("fit active"))
    hl.bind(mainMod .. " + SHIFT + backslash", hl.dsp.layout("consume_or_expel next"))
end
