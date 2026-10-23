"""Temporary DNS overrides for this host's openresolv configuration."""

import ipaddress
import os
from pathlib import Path
import re
import secrets
import socket
import struct
import subprocess
import time

KEY = "dns-switcher.manual"
RESOLVCONF = "/run/current-system/sw/bin/resolvconf"
SUDO = "/run/wrappers/bin/sudo"
PRESETS = {
    "Pi-hole": ("192.168.88.247",),
    "Cloudflare": ("1.1.1.1", "1.0.0.1"),
    "Quad9": ("9.9.9.9", "149.112.112.112"),
}


class DNSError(Exception):
    pass


def parse_addresses(text):
    values = re.split(r"[\s,]+", text.strip()) if text.strip() else []
    if not values:
        raise DNSError("Enter at least one DNS IP address.")
    addresses = []
    for value in values:
        try:
            address = ipaddress.ip_address(value)
            if address.is_unspecified or address.is_multicast or "%" in value:
                raise ValueError()
        except ValueError:
            raise DNSError(f"“{value}” is not a usable IPv4 or IPv6 address.") from None
        if str(address) not in addresses:
            addresses.append(str(address))
    if len(addresses) > 3:
        raise DNSError("Use up to three DNS addresses, separated by spaces or commas.")
    return tuple(addresses)


def nameservers(text):
    return tuple(
        line.split()[1]
        for line in text.splitlines()
        if len(line.split()) >= 2 and line.split()[0] == "nameserver"
    )


def current_servers():
    try:
        return nameservers(Path("/etc/resolv.conf").read_text())
    except OSError as error:
        raise DNSError(f"Cannot read the current DNS settings: {error}") from error


def provider_name(servers):
    return next((name for name, ips in PRESETS.items() if ips == servers), "Custom DNS")


def run_resolvconf(args, content=None, privileged=False):
    command = [RESOLVCONF, *args]
    if privileged:
        # Elevate only the resolver command, never this Python application.
        # This host already grants its desktop user passwordless sudo.
        command = [SUDO, "-n", "--", *command]
    try:
        result = subprocess.run(
            command, input=content, text=True, capture_output=True, timeout=20,
            env={**os.environ, "LC_ALL": "C"},
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise DNSError(f"The DNS service could not finish the request: {error}") from error
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip() or "Unknown resolver error"
        raise DNSError(detail)
    return result.stdout


def override_content():
    # A pattern with no matches exits nonzero in openresolv; list keys first.
    if KEY not in run_resolvconf(["-i"]).split():
        return ""
    return run_resolvconf(["-l", KEY])


def write_override(content):
    if nameservers(content):
        # Exclusive prevents a failed Pi-hole from staying in the fallback list.
        run_resolvconf(["-x", "-a", KEY], content, privileged=True)
    else:
        run_resolvconf(["-f", "-d", KEY], privileged=True)


def change_dns(addresses=None):
    """None restores defaults; otherwise replace only our exclusive override."""
    if addresses is not None:
        addresses = parse_addresses(" ".join(addresses))
    before = override_content()
    previous_servers = current_servers()
    content = "" if addresses is None else "".join(f"nameserver {ip}\n" for ip in addresses)
    try:
        write_override(content)
        actual = current_servers()
        if not actual or (addresses is not None and actual != addresses):
            raise DNSError("The system did not adopt the requested DNS addresses.")
        if addresses is None and nameservers(override_content()):
            raise DNSError("The temporary override was not removed.")
        return actual
    except DNSError as error:
        try:
            write_override(before)
            if current_servers() != previous_servers:
                raise DNSError("The previous DNS addresses could not be verified.")
        except DNSError as rollback_error:
            raise DNSError(
                f"{error}\nCould not restore the previous settings: {rollback_error}\n"
                "Use Restore defaults to try again."
            ) from error
        raise DNSError(f"{error}\nYour previous DNS settings have been restored.") from error


def probe(server, timeout=2):
    """Query an IP directly, so checks work even when system DNS is broken."""
    query_id = secrets.randbits(16)
    question = b"\x07example\x03com\x00" + struct.pack("!HH", 1, 1)
    packet = struct.pack("!6H", query_id, 0x0100, 1, 0, 0, 0) + question
    started = time.monotonic()
    try:
        family = socket.AF_INET6 if ipaddress.ip_address(server).version == 6 else socket.AF_INET
        with socket.socket(family, socket.SOCK_DGRAM) as sock:
            sock.settimeout(timeout)
            sock.connect((server, 53))
            sock.send(packet)
            reply = sock.recv(4096)
        if len(reply) < 12:
            return False, "Invalid reply"
        ident, flags, questions, answers, _, _ = struct.unpack("!6H", reply[:12])
        if ident != query_id or not flags & 0x8000 or questions != 1 or reply[12:12 + len(question)] != question:
            return False, "Invalid reply"
        if flags & 0x000F or not answers or flags & 0x0200:
            return False, "DNS error"
        return True, f"{max(1, round((time.monotonic() - started) * 1000))} ms"
    except (OSError, ValueError):
        return False, "No reply"
