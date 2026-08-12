import { App, Astal, Gdk, Gtk } from "astal/gtk3"
import { execAsync } from "astal/process"
import style from "./style.scss"

const WINDOW_NAME = "audio-popup"
const POPUP_VERSION = "audio-popup pactl-ui v3"

type PactlSink = {
    name: string
    description?: string
    mute?: boolean
    volume?: Record<string, { value_percent?: string }>
    properties?: Record<string, string>
    active_port?: string | { name?: string; description?: string }
    ports?: Record<string, { description?: string; availability?: string }> | Array<{ name?: string; description?: string; availability?: string }>
}

type Output = {
    name: string
    label: string
    detail: string
    icon: string
    active: boolean
    muted: boolean
    volume: number
}

type StyledWidget = Gtk.Widget & {
    get_style_context: () => Gtk.StyleContext
}

function addClass(widget: StyledWidget, name: string): void {
    widget.get_style_context().add_class(name)
}

function setClass(widget: StyledWidget, name: string, enabled: boolean): void {
    const style = widget.get_style_context()
    if (enabled) style.add_class(name)
    else style.remove_class(name)
}

function volumePercent(sink: PactlSink): number {
    const first = Object.values(sink.volume ?? {})[0]?.value_percent ?? "0%"
    return Math.max(0, Math.min(100, Number.parseInt(first.replace("%", ""), 10) || 0))
}

function isVirtual(sink: PactlSink): boolean {
    const props = sink.properties ?? {}
    const text = `${sink.name} ${sink.description ?? ""} ${props["node.name"] ?? ""}`.toLowerCase()

    return props["node.virtual"] === "true"
        || text.includes("easyeffects")
        || text.includes("null")
        || text.includes("obs")
        || text.includes("monitor")
}

function activePortDetail(sink: PactlSink): string {
    if (!sink.active_port) return ""
    if (typeof sink.active_port !== "string") {
        const description = sink.active_port.description ?? ""
        return description && description !== sink.description ? description : ""
    }

    const ports = sink.ports
    const port = Array.isArray(ports)
        ? ports.find((item) => item.name === sink.active_port)
        : ports?.[sink.active_port]
    if (!port?.description || port.description === sink.description) return ""
    return port.description
}

function friendlyLabel(sink: PactlSink): string {
    const props = sink.properties ?? {}
    const explicit = props["bluez.alias"]
        || props["device.product.name"]
        || props["device.description"]
        || sink.description
        || sink.name

    // Keep manufacturer/product names intact (for example, DragonFly Red and
    // Audeze Maxwell). Genericising every sink containing "headset" made the
    // most important distinction in this picker disappear.
    return explicit
        .replace(/^alsa_output\./, "")
        .replace(/\.(analog|digital|hdmi).*$/i, "")
        .replace(/[_-]+/g, " ")
        .trim()
}

function iconName(output: Output): string {
    const text = `${output.name} ${output.label} ${output.detail}`.toLowerCase()
    if (text.includes("bluetooth") || text.includes("bluez")) return "audio-headphones-symbolic"
    if (text.includes("headphone") || text.includes("headset")) return "audio-headphones-symbolic"
    if (text.includes("hdmi") || text.includes("display")) return "video-display-symbolic"
    if (text.includes("usb")) return "audio-card-symbolic"
    return "audio-speakers-symbolic"
}

async function loadOutputs(): Promise<Output[]> {
    const [defaultSink, rawSinks] = await Promise.all([
        execAsync("pactl get-default-sink").catch(() => ""),
        execAsync("pactl -f json list sinks").catch(() => "[]"),
    ])
    const sinks = JSON.parse(rawSinks || "[]") as PactlSink[]

    return sinks
        .filter((sink) => !isVirtual(sink))
        .map((sink) => {
            const label = friendlyLabel(sink)
            const detail = activePortDetail(sink)
            const output = {
                name: sink.name,
                label,
                detail,
                active: sink.name === defaultSink.trim(),
                muted: sink.mute ?? false,
                volume: volumePercent(sink),
                icon: "audio-speakers-symbolic",
            }
            output.icon = iconName(output)
            return output
        })
}

function AudioPopup(gdkmonitor: Gdk.Monitor) {
    const { TOP, RIGHT } = Astal.WindowAnchor

    let outputs: Output[] = []
    let refreshing = false
    let settingVolume = false

    const deviceList = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL,
        spacing: 4,
    })
    const currentOutputLabel = new Gtk.Label({
        label: "Finding output…",
        xalign: 0,
        hexpand: true,
        ellipsize: 3,
    })
    addClass(currentOutputLabel, "current-output")
    const volumeIcon = new Gtk.Image({ iconName: "audio-volume-medium-symbolic", pixelSize: 16 })
    const volumeLabel = new Gtk.Label({ label: "--%", xalign: 1 })
    const volumeScale = new Gtk.Scale({
        orientation: Gtk.Orientation.HORIZONTAL,
        drawValue: false,
        hexpand: true,
        sensitive: false,
    })
    volumeScale.set_size_request(180, 24)
    volumeScale.set_range(0, 100)
    volumeScale.set_increments(1, 5)

    const activeOutput = () => outputs.find((output) => output.active) ?? outputs[0] ?? null

    const renderVolume = () => {
        const output = activeOutput()
        if (!output) {
            currentOutputLabel.label = "No output selected"
            volumeLabel.label = "--%"
            volumeScale.sensitive = false
            return
        }

        currentOutputLabel.label = output.label
        volumeScale.sensitive = true
        settingVolume = true
        volumeScale.set_value(output.volume)
        settingVolume = false
        volumeLabel.label = `${output.volume}%`
        volumeIcon.iconName = output.muted ? "audio-volume-muted-symbolic" : "audio-volume-medium-symbolic"
        setClass(volumeScale, "muted", output.muted)
        setClass(volumeLabel, "muted", output.muted)
    }

    const renderDevices = () => {
        for (const child of deviceList.get_children()) child.destroy()

        if (outputs.length === 0) {
            const emptyLabel = new Gtk.Label({
                label: "No output devices",
                xalign: 0,
            })
            addClass(emptyLabel, "empty")
            deviceList.add(emptyLabel)
            deviceList.show_all()
            renderVolume()
            return
        }

        for (const output of outputs) {
            const button = new Gtk.Button()
            addClass(button, "device")
            setClass(button, "active", output.active)

            const row = new Gtk.Box({
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 10,
                hexpand: true,
            })
            const text = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 1,
                hexpand: true,
            })
            const label = new Gtk.Label({
                label: output.label,
                xalign: 0,
                hexpand: true,
                ellipsize: 3,
            })
            addClass(label, "device-name")
            text.pack_start(label, false, false, 0)

            const detailParts = [output.active ? "Current output" : "Use this output"]
            if (output.detail) detailParts.push(output.detail)
            const detail = new Gtk.Label({
                label: detailParts.join(" · "),
                xalign: 0,
                hexpand: true,
                ellipsize: 3,
            })
            addClass(detail, "detail")
            if (output.active) addClass(detail, "active-detail")
            text.pack_start(detail, false, false, 0)

            row.pack_start(new Gtk.Image({ iconName: output.icon, pixelSize: 16 }), false, false, 0)
            row.pack_start(text, true, true, 0)
            const state = new Gtk.Label({
                label: output.active ? "CURRENT" : "SELECT",
                xalign: 1,
            })
            addClass(state, "device-state")
            if (output.active) addClass(state, "active-state")
            row.pack_end(state, false, false, 0)

            button.add(row)
            button.connect("clicked", async () => {
                if (output.active) return

                button.sensitive = false
                state.label = "SWITCHING…"
                try {
                    await execAsync(["pactl", "set-default-sink", output.name])
                    const rawInputs = await execAsync(["pactl", "list", "short", "sink-inputs"])
                    const inputIds = rawInputs
                        .split("\n")
                        .map((line) => line.split("\t")[0])
                        .filter(Boolean)
                    for (const inputId of inputIds) {
                        await execAsync(["pactl", "move-sink-input", inputId, output.name]).catch(print)
                    }
                } catch (error) {
                    print(error)
                }
                await refresh()
            })
            deviceList.add(button)
        }

        deviceList.show_all()
        renderVolume()
    }

    async function refresh() {
        if (refreshing) return
        refreshing = true
        try {
            outputs = await loadOutputs()
            print(`${POPUP_VERSION}: loaded ${outputs.length} output(s): ${outputs.map((output) => `${output.active ? "*" : ""}${output.label}:${output.volume}%`).join(", ")}`)
            renderDevices()
        } catch (error) {
            print(error)
        } finally {
            refreshing = false
        }
    }

    volumeScale.connect("value-changed", () => {
        if (settingVolume) return
        const output = activeOutput()
        if (!output) return

        const value = Math.round(volumeScale.get_value())
        output.volume = value
        volumeLabel.label = `${value}%`
        execAsync(`pactl set-sink-volume @DEFAULT_SINK@ ${value}%`).catch(print)
    })

    const refreshTimer = setInterval(refresh, 1000)

    const mixerButton = new Gtk.Button({ tooltipText: "Open full audio settings" })
    addClass(mixerButton, "mixer")
    const mixerContent = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 5 })
    mixerContent.pack_start(new Gtk.Image({ iconName: "emblem-system-symbolic", pixelSize: 14 }), false, false, 0)
    mixerContent.pack_start(new Gtk.Label({ label: "More settings" }), false, false, 0)
    mixerButton.add(mixerContent)
    mixerButton.connect("clicked", () => execAsync("pavucontrol").catch(print))

    const win = <window
        name={WINDOW_NAME}
        application={App}
        gdkmonitor={gdkmonitor}
        visible={true}
        className="AudioPopup"
        anchor={TOP | RIGHT}
        keymode={Astal.Keymode.ON_DEMAND}
        exclusivity={Astal.Exclusivity.IGNORE}
        onDestroy={() => clearInterval(refreshTimer)}
        onKeyPressEvent={(_, event) => {
            if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                App.quit()
            }
        }}>
        <box className="panel" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
            <box className="heading" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label className="title" label="Sound output" xalign={0} />
                <label className="subtitle" label="Choose where your audio plays" xalign={0} />
            </box>
            <box className="current" orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                <label className="current-label" label="PLAYING THROUGH" xalign={0} />
                {currentOutputLabel}
            </box>
            <box className="volume" orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                {volumeIcon}
                {volumeScale}
                {volumeLabel}
            </box>
            {deviceList}
            <box className="footer" orientation={Gtk.Orientation.HORIZONTAL}>
                <label label="CLICK A DEVICE TO SWITCH ALL PLAYING APPS" xalign={0} hexpand={true} />
                {mixerButton}
            </box>
        </box>
    </window>

    refresh()
    return win
}

function DismissLayer(gdkmonitor: Gdk.Monitor) {
    const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor

    return <window
        name={`${WINDOW_NAME}-dismiss`}
        application={App}
        gdkmonitor={gdkmonitor}
        visible={true}
        className="AudioPopupDismiss"
        anchor={TOP | RIGHT | BOTTOM | LEFT}
        keymode={Astal.Keymode.ON_DEMAND}
        exclusivity={Astal.Exclusivity.IGNORE}
        onButtonPressEvent={() => App.quit()} />
}

App.start({
    instanceName: WINDOW_NAME,
    css: style,
    requestHandler(argv: string[], response: (message: string) => void) {
        const win = App.get_window(WINDOW_NAME)
        if (argv[0] === "health") {
            response(win ? "ready" : "missing-window")
            return
        }
        if (argv[0] === "toggle") {
            if (!win) {
                response("missing-window")
                return
            }
            if (win.visible) win.hide()
            else {
                win.show()
            }
            response("ok")
            return
        }
        response("unknown command")
    },
    main() {
        print(`${POPUP_VERSION}: starting`)
        const monitor = App.get_monitors()[0]
        DismissLayer(monitor)
        AudioPopup(monitor)
    },
})
