return function(hl, mainMod)
    hl.config({
        general = {
            layout = "dwindle",
        },
    })

    hl.config({
        dwindle = {
            preserve_split = true,
        },
    })

    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + SHIFT + backslash", hl.dsp.layout("togglesplit"))
end
