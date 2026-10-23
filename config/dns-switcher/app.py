#!/usr/bin/env python3
"""A small, native Wayland DNS rescue panel."""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, Gio, GLib, Gtk  # noqa: E402

import backend  # noqa: E402


def label(text, css=None, **kwargs):
    kwargs.setdefault("xalign", 0)
    widget = Gtk.Label(label=text, **kwargs)
    if css:
        widget.add_css_class(css)
    return widget


class DNSWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="DNS", default_width=440, resizable=False)
        self.add_css_class("dns-window")
        self.busy = False
        self.generation = 0
        self.servers = ()
        self.override = False
        self.selected = "Pi-hole"
        self.pool = ThreadPoolExecutor(max_workers=5)
        self.rows = {}
        self.badges = {}

        header = Gtk.HeaderBar(show_title_buttons=True)
        header.set_title_widget(label("NETWORK", "eyebrow"))
        self.set_titlebar(header)
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        root.add_css_class("content")
        self.set_child(root)
        heading = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        heading.append(label("A clear way online.", "heading"))
        heading.append(label("Switch DNS when your home server needs a break.", "muted", wrap=True))
        root.append(heading)

        status = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        status.add_css_class("status-card")
        top = Gtk.Box(spacing=8)
        top.append(label("CURRENT DNS", "eyebrow", hexpand=True))
        self.health = label("Checking…", "health")
        top.append(self.health)
        status.append(top)
        self.provider = label("Reading settings…", "provider")
        self.addresses = label("", "addresses", selectable=True, wrap=True)
        status.append(self.provider)
        status.append(self.addresses)
        root.append(status)

        choices = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        choices.append(label("CHOOSE A RESOLVER", "eyebrow"))
        descriptions = {
            "Pi-hole": "Home server · your usual filtering",
            "Cloudflare": "Public fallback · no Pi-hole filtering",
            "Quad9": "Public fallback · blocks known threats",
            "Custom": "Use your own DNS addresses",
        }
        for name, description in descriptions.items():
            button = Gtk.Button()
            button.add_css_class("resolver")
            row = Gtk.Box(spacing=12)
            radio = label("○", "radio")
            row.append(radio)
            text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3, hexpand=True)
            text.append(label(name, "resolver-title"))
            text.append(label(description, "resolver-description"))
            row.append(text)
            badge = label("Checking…" if name != "Custom" else "", "badge")
            row.append(badge)
            button.set_child(row)
            button.connect("clicked", lambda _, n=name: self.select(n))
            self.rows[name] = (button, radio)
            self.badges[name] = badge
            choices.append(button)
        root.append(choices)

        self.custom = Gtk.Revealer(transition_type=Gtk.RevealerTransitionType.SLIDE_DOWN)
        custom_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        self.entry = Gtk.Entry(placeholder_text="e.g. 1.1.1.1, 1.0.0.1")
        self.entry.set_tooltip_text("Up to three IPv4 or IPv6 addresses, separated by spaces or commas")
        self.entry.connect("changed", lambda _: self.update_action())
        self.entry.connect("activate", lambda _: self.apply() if self.apply_button.get_sensitive() else None)
        custom_box.append(self.entry)
        self.custom_hint = label("Separate IPv4 or IPv6 addresses with commas.", "muted", wrap=True)
        custom_box.append(self.custom_hint)
        self.custom.set_child(custom_box)
        root.append(self.custom)

        self.message = label("", "message", wrap=True)
        self.message.set_visible(False)
        root.append(self.message)
        actions = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        self.apply_button = Gtk.Button(label="Checking DNS…")
        self.apply_button.add_css_class("apply")
        self.apply_button.connect("clicked", lambda _: self.apply())
        actions.append(self.apply_button)
        secondary = Gtk.Box(spacing=10, homogeneous=True)
        self.restore_button = Gtk.Button(label="Restore defaults")
        self.restore_button.add_css_class("secondary")
        self.restore_button.connect("clicked", lambda _: self.apply(restore=True))
        self.refresh_button = Gtk.Button(label="Check again")
        self.refresh_button.add_css_class("secondary")
        self.refresh_button.connect("clicked", lambda _: self.refresh())
        secondary.append(self.restore_button)
        secondary.append(self.refresh_button)
        actions.append(secondary)
        root.append(actions)
        root.append(label("Only this computer · resets on reboot", "footnote", xalign=0.5))

        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self.on_key)
        self.add_controller(keys)
        self.connect("close-request", self.on_close)
        self.select("Pi-hole")
        self.refresh(initial=True)

    def on_key(self, _controller, key, _code, _state):
        if key == Gdk.KEY_Escape and not self.busy:
            self.close()
            return True
        return False

    def on_close(self, _window):
        if self.busy:
            return True
        self.generation += 1
        self.pool.shutdown(wait=False, cancel_futures=True)
        return False

    def background(self, work, done):
        future = self.pool.submit(work)
        def finish(result):
            try:
                value, error = result.result(), None
            except Exception as exc:
                value, error = None, str(exc)
            GLib.idle_add(done, value, error)
        future.add_done_callback(finish)

    def select(self, name):
        self.selected = name
        for key, (button, radio) in self.rows.items():
            if key == name:
                button.add_css_class("selected")
            else:
                button.remove_css_class("selected")
            radio.set_text("●" if key == name else "○")
        self.custom.set_reveal_child(name == "Custom")
        self.update_action()

    def chosen_addresses(self):
        if self.selected == "Custom":
            return backend.parse_addresses(self.entry.get_text())
        return backend.PRESETS[self.selected]

    def update_action(self):
        self.custom_hint.remove_css_class("error")
        self.custom_hint.set_text("Separate IPv4 or IPv6 addresses with commas.")
        try:
            same = self.chosen_addresses() == self.servers
            valid = True
        except backend.DNSError as error:
            same, valid = False, False
            if self.entry.get_text():
                self.custom_hint.set_text(str(error))
                self.custom_hint.add_css_class("error")
        self.apply_button.set_label("Applying…" if self.busy else "Already active" if same else f"Use {self.selected}")
        self.apply_button.set_sensitive(valid and not same and not self.busy)
        self.restore_button.set_sensitive(self.override and not self.busy)

    def show_message(self, text, error=False):
        self.message.set_text(text)
        self.message.set_visible(bool(text))
        self.message.remove_css_class("error")
        if error:
            self.message.add_css_class("error")

    def refresh(self, initial=False):
        self.generation += 1
        generation = self.generation
        self.health.set_text("Checking…")
        self.health.remove_css_class("error")
        def done(value, error):
            if generation != self.generation:
                return False
            if error:
                self.show_message(error, True)
                self.health.set_text("Unavailable")
                return False
            self.servers, self.override = value
            self.provider.set_text(backend.provider_name(self.servers) if self.servers else "No DNS configured")
            self.addresses.set_text("  ·  ".join(self.servers))
            if initial:
                name = backend.provider_name(self.servers)
                if name == "Custom DNS":
                    self.entry.set_text(", ".join(self.servers))
                    name = "Custom"
                self.select(name)
            self.update_action()
            targets = {ips[0] for ips in backend.PRESETS.values()}
            if self.servers:
                targets.add(self.servers[0])
            else:
                self.health.set_text("Not configured")
            for server in targets:
                self.background(lambda s=server: backend.probe(s),
                                lambda value, error, s=server: self.probed(generation, s, value, error))
            return False
        self.background(lambda: (backend.current_servers(), bool(backend.nameservers(backend.override_content()))), done)

    def probed(self, generation, server, result, error):
        if generation != self.generation:
            return False
        ok, text = result if result is not None else (False, "Check failed")
        for name, ips in backend.PRESETS.items():
            if ips[0] == server:
                badge = self.badges[name]
                badge.set_text(text)
                badge.set_tooltip_text(f"DNS lookup using {server} (primary server)")
                badge.remove_css_class("error")
                if not ok:
                    badge.add_css_class("error")
        if self.servers and self.servers[0] == server:
            self.health.set_text(f"● Responding · {text}" if ok else "● Primary not responding")
            self.health.remove_css_class("error")
            if not ok:
                self.health.add_css_class("error")
        return False

    def apply(self, restore=False):
        if self.busy:
            return
        try:
            addresses = None if restore else self.chosen_addresses()
        except backend.DNSError as error:
            self.show_message(str(error), True)
            return
        self.busy = True
        self.generation += 1
        self.show_message("")
        self.update_action()
        for button, _ in self.rows.values():
            button.set_sensitive(False)
        self.entry.set_sensitive(False)
        self.refresh_button.set_sensitive(False)
        def done(value, error):
            self.busy = False
            for button, _ in self.rows.values():
                button.set_sensitive(True)
            self.entry.set_sensitive(True)
            self.refresh_button.set_sensitive(True)
            self.show_message(error or ("Default DNS restored." if restore else "DNS changed. Your connection stayed up."), bool(error))
            self.refresh(initial=True)
            return False
        self.background(lambda: backend.change_dns(addresses), done)


class DNSApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="io.github.nixdot.DNSSwitcher", flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

    def do_activate(self):
        window = self.get_active_window()
        if window is None:
            Gtk.Settings.get_default().set_property("gtk-application-prefer-dark-theme", True)
            css = Gtk.CssProvider()
            css.load_from_path(str(Path(__file__).with_name("style.css")))
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            window = DNSWindow(self)
        else:
            if not window.busy:
                window.refresh()
        window.present()


if __name__ == "__main__":
    sys.exit(DNSApp().run(sys.argv))
