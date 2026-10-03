import { App, Astal, Gdk, Gtk } from "astal/gtk3"
import { execAsync } from "astal/process"
import style from "./style.scss"

const WINDOW_NAME = "audio-popup"
const POPUP_VERSION = "audio-popup pactl-ui v5"

let onVisibilityChanged = (_visible: boolean) => {}

function setPopupVisible(visible: boolean) {
    // The click-away layer must always follow the popup, including on Escape.
    const dismiss = App.get_window(`${WINDOW_NAME}-dismiss`)
    const popup = App.get_window(WINDOW_NAME)
    if (visible) {
        dismiss?.show()
        popup?.show()
    } else {
        popup?.hide()
        dismiss?.hide()
    }
    onVisibilityChanged(visible)
}

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
        execAsync("pactl get-default-sink"),
        execAsync("pactl -f json list sinks"),
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
    let pendingVolumeChanges = 0
    let volumeRevision = 0
    let volumeWrites = Promise.resolve()
    let queuedVolume: { name: string; value: number } | null = null
    let volumeWriteTimer: ReturnType<typeof setTimeout> | null = null
    let refreshTimer: ReturnType<typeof setInterval> | null = null
    let deviceSignature = ""
    let switching = false

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
    addClass(volumeLabel, "volume-value")
    const muteButton = new Gtk.Button({ sensitive: false, tooltipText: "Mute output (M)" })
    addClass(muteButton, "mute-button")
    const muteLabel = new Gtk.Label({ label: "Mute" })
    const muteContent = new Gtk.Box({ spacing: 6 })
    muteContent.add(volumeIcon)
    muteContent.add(muteLabel)
    muteButton.add(muteContent)
    const statusLabel = new Gtk.Label({ label: "", xalign: 0, wrap: true, noShowAll: true })
    addClass(statusLabel, "error")
    const showError = (error: unknown) => {
        print(error)
        statusLabel.label = "Couldn’t update audio. Please try again."
        statusLabel.show()
    }
    const volumeScale = new Gtk.Scale({
        orientation: Gtk.Orientation.HORIZONTAL,
        drawValue: false,
        hexpand: true,
        sensitive: false,
    })
    volumeScale.set_size_request(240, 36)
    volumeScale.set_range(0, 100)
    volumeScale.set_increments(1, 5)
    volumeScale.tooltipText = "Output volume · Left/Right to adjust by 5%"

    const volumeDownButton = new Gtk.Button({ label: "−", tooltipText: "Decrease volume by 5% (Left)", sensitive: false })
    const volumeUpButton = new Gtk.Button({ label: "+", tooltipText: "Increase volume by 5% (Right)", sensitive: false })
    addClass(volumeDownButton, "volume-step")
    addClass(volumeUpButton, "volume-step")

    const activeOutput = () => outputs.find((output) => output.active) ?? null

    const renderVolume = () => {
        const output = activeOutput()
        muteButton.sensitive = !!output && !switching
        volumeDownButton.sensitive = !!output && output.volume > 0
        volumeUpButton.sensitive = !!output && output.volume < 100
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
        volumeIcon.iconName = output.muted || output.volume === 0 ? "audio-volume-muted-symbolic"
            : output.volume < 34 ? "audio-volume-low-symbolic"
            : output.volume < 67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic"
        muteLabel.label = output.muted ? "Unmute" : "Mute"
        muteButton.tooltipText = output.muted ? "Unmute output (M)" : "Mute output (M)"
        setClass(muteButton, "is-muted", output.muted)
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

            const detailParts = [output.active ? "Selected" : "Switch output"]
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
                label: output.active ? "✓" : "",
                xalign: 1,
            })
            addClass(state, "device-state")
            if (output.active) addClass(state, "active-state")
            row.pack_end(state, false, false, 0)

            button.add(row)
            button.connect("clicked", async () => {
                if (outputs.find((item) => item.name === output.name)?.active || switching) return

                switching = true
                deviceList.sensitive = false
                state.label = "…"
                flushVolume()
                try {
                    await volumeWrites
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
                    showError(error)
                } finally {
                    switching = false
                    deviceList.sensitive = true
                    deviceSignature = ""
                }
                await refresh()
            })
            deviceList.add(button)
        }

        deviceList.show_all()
        renderVolume()
    }

    async function refresh() {
        if (refreshing || pendingVolumeChanges > 0 || queuedVolume || switching) return
        refreshing = true
        const revision = volumeRevision
        try {
            const loadedOutputs = await loadOutputs()
            // A read started before an adjustment must not reset the slider.
            if (pendingVolumeChanges > 0 || queuedVolume || switching || revision !== volumeRevision) return
            outputs = loadedOutputs
            const signature = JSON.stringify(outputs.map(({ volume, muted, ...device }) => device))
            if (signature !== deviceSignature) {
                deviceSignature = signature
                renderDevices()
            } else {
                renderVolume()
            }
        } catch (error) {
            showError(error)
        } finally {
            refreshing = false
        }
    }

    function flushVolume() {
        if (volumeWriteTimer !== null) clearTimeout(volumeWriteTimer)
        volumeWriteTimer = null
        const change = queuedVolume
        if (!change) return
        queuedVolume = null
        pendingVolumeChanges++
        volumeWrites = volumeWrites
            .then(() => execAsync(["pactl", "set-sink-volume", change.name, `${change.value}%`]))
            .then(() => {})
            .catch(showError)
            .finally(() => { pendingVolumeChanges-- })
    }

    const setVolume = (requested: number) => {
        const output = activeOutput()
        if (!output || switching) return

        const value = Math.max(0, Math.min(100, Math.round(requested)))
        if (value === output.volume) return
        output.volume = value
        renderVolume()
        statusLabel.hide()
        volumeRevision++
        // Combine drag events into at most one write per 40 ms.
        if (queuedVolume && queuedVolume.name !== output.name) flushVolume()
        queuedVolume = { name: output.name, value }
        if (volumeWriteTimer === null) volumeWriteTimer = setTimeout(flushVolume, 40)
    }

    const toggleMute = () => {
        const output = activeOutput()
        if (!output || switching) return
        flushVolume()
        output.muted = !output.muted
        const muted = output.muted
        renderVolume()
        statusLabel.hide()
        volumeRevision++
        pendingVolumeChanges++
        volumeWrites = volumeWrites
            .then(() => execAsync(["pactl", "set-sink-mute", output.name, muted ? "1" : "0"]))
            .then(() => {})
            .catch(showError)
            .finally(() => { pendingVolumeChanges-- })
    }

    const adjustVolume = (delta: number) => {
        const output = activeOutput()
        if (output) setVolume(output.volume + delta)
    }

    volumeDownButton.connect("clicked", () => adjustVolume(-5))
    volumeUpButton.connect("clicked", () => adjustVolume(5))
    muteButton.connect("clicked", toggleMute)
    volumeScale.connect("value-changed", () => {
        if (!settingVolume) setVolume(volumeScale.get_value())
    })

    const watch = (visible: boolean) => {
        if (refreshTimer !== null) clearInterval(refreshTimer)
        refreshTimer = null
        if (visible) {
            refresh()
            refreshTimer = setInterval(refresh, 1000)
        } else {
            flushVolume()
        }
    }
    onVisibilityChanged = watch

    const mixerButton = new Gtk.Button({
        tooltipText: "Playback, recording, inputs, outputs, and device profiles",
    })
    addClass(mixerButton, "mixer")
    const mixerContent = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 5 })
    mixerContent.pack_start(new Gtk.Image({ iconName: "emblem-system-symbolic", pixelSize: 14 }), false, false, 0)
    mixerContent.pack_start(new Gtk.Label({ label: "All audio controls" }), false, false, 0)
    mixerButton.add(mixerContent)
    mixerButton.connect("clicked", async () => {
        await execAsync(["sh", "-lc", "pwvucontrol >/tmp/pwvucontrol.log 2>&1 &"]).catch(print)
        setPopupVisible(false)
    })

    const win = <window
        name={WINDOW_NAME}
        application={App}
        gdkmonitor={gdkmonitor}
        visible={true}
        className="AudioPopup"
        anchor={TOP | RIGHT}
        keymode={Astal.Keymode.EXCLUSIVE}
        exclusivity={Astal.Exclusivity.IGNORE}
        onDestroy={() => watch(false)}
        onKeyPressEvent={(_, event) => {
            const key = event.get_keyval()[1]
            if (key === Gdk.KEY_Escape) {
                setPopupVisible(false)
                return true
            }
            if (key === Gdk.KEY_Left || key === Gdk.KEY_Right) {
                adjustVolume(key === Gdk.KEY_Left ? -5 : 5)
                return true
            }
            if (key === Gdk.KEY_m || key === Gdk.KEY_M) {
                toggleMute()
                return true
            }
            return false
        }}>
        <box className="panel" orientation={Gtk.Orientation.VERTICAL} spacing={16}>
            <box className="heading" spacing={12}>
                <label className="title" label="Sound" xalign={0} hexpand={true} />
                <button className="close" label="×" tooltipText="Close (Esc)" onClicked={() => setPopupVisible(false)} />
            </box>
            <box className="volume-card" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                <box spacing={12}>
                    <label className="section-label" label="Volume" xalign={0} hexpand={true} />
                    {volumeLabel}
                </box>
                {currentOutputLabel}
                <box className="volume" spacing={10}>
                    {volumeDownButton}
                    {volumeScale}
                    {volumeUpButton}
                </box>
                <box>
                    {muteButton}
                    <label className="hint" label="← / →  adjust · M  mute" xalign={1} hexpand={true} />
                </box>
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                <label className="section-label" label="Output device" xalign={0} />
                {deviceList}
            </box>
            {statusLabel}
            <box className="footer" orientation={Gtk.Orientation.HORIZONTAL}>
                <label label="Esc to close" xalign={0} hexpand={true} />
                {mixerButton}
            </box>
        </box>
    </window>

    // Plain Gtk children do not inherit the JSX widgets' visible default.
    win.show_all()
    watch(true)
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
        keymode={Astal.Keymode.NONE}
        exclusivity={Astal.Exclusivity.IGNORE}
        onButtonPressEvent={() => setPopupVisible(false)} />
}

App.start({
    instanceName: WINDOW_NAME,
    css: style,
    requestHandler(request: string, response: (message: string) => void) {
        const win = App.get_window(WINDOW_NAME)
        if (request === "health") {
            response(win ? "ready" : "missing-window")
            return
        }
        if (request === "toggle") {
            if (!win) {
                response("missing-window")
                return
            }
            setPopupVisible(!win.visible)
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
