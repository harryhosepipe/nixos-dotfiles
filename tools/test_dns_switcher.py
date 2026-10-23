"""Exercise DNS recovery without touching the machine's network configuration."""

import importlib.util
from pathlib import Path
import socket
import struct
import threading
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "dns_backend", Path(__file__).resolve().parents[1] / "config/dns-switcher/backend.py"
)
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


class AddressTests(unittest.TestCase):
    def test_ipv4_ipv6_and_duplicates(self):
        self.assertEqual(backend.parse_addresses("1.1.1.1, 2606:4700:4700::1111 1.1.1.1"),
                         ("1.1.1.1", "2606:4700:4700::1111"))

    def test_invalid_inputs_never_reach_privileged_command(self):
        for value in ("", "example.com", "1.1.1.1;reboot", "0.0.0.0", "224.0.0.1",
                      "fe80::1%eth0", "1.1.1.1 8.8.8.8 9.9.9.9 1.0.0.1"):
            with self.subTest(value=value), patch.object(backend, "run_resolvconf") as run:
                with self.assertRaises(backend.DNSError):
                    backend.change_dns((value,))
                run.assert_not_called()

    def test_resolver_parsing_ignores_comments_and_options(self):
        self.assertEqual(backend.nameservers("# nameserver 9.9.9.9\nsearch home\nnameserver 1.1.1.1 # test\noptions edns0\n"), ("1.1.1.1",))


class ResolverTests(unittest.TestCase):
    def setUp(self):
        self.override = ""
        self.default = "nameserver 192.168.88.247\n"
        self.effective = backend.nameservers(self.default)
        self.fail_next = None
        self.calls = []
        self.patches = [patch.object(backend, "run_resolvconf", self.run_resolver),
                        patch.object(backend, "current_servers", lambda: self.effective)]
        for item in self.patches:
            item.start()
            self.addCleanup(item.stop)

    def run_resolver(self, args, content=None, privileged=False):
        self.calls.append((args, content, privileged))
        if args[0] == "-i":
            return backend.KEY if self.override else ""
        self.assertEqual(args[-1], backend.KEY)
        if args[0] == "-l":
            return self.override
        self.assertTrue(privileged)
        if self.fail_next == "permission":
            self.fail_next = None
            raise backend.DNSError("Permission denied")
        self.override = content if args[0] == "-x" else ""
        if self.fail_next == "verification":
            self.fail_next = None
            return ""
        self.effective = backend.nameservers(self.override or self.default)
        return ""

    def test_switch_replaces_pihole_and_restore_keeps_default(self):
        result = backend.change_dns(backend.PRESETS["Cloudflare"])
        self.assertEqual(result, ("1.1.1.1", "1.0.0.1"))
        self.assertEqual(self.default, "nameserver 192.168.88.247\n")
        self.assertEqual(backend.change_dns(), ("192.168.88.247",))
        self.assertEqual(self.override, "")

    def test_failed_first_change_removes_own_override(self):
        self.fail_next = "verification"
        with self.assertRaisesRegex(backend.DNSError, "previous DNS settings have been restored"):
            backend.change_dns(backend.PRESETS["Cloudflare"])
        self.assertEqual(self.override, "")
        self.assertEqual(self.effective, ("192.168.88.247",))

    def test_failed_change_restores_previous_custom_override(self):
        backend.change_dns(("8.8.8.8",))
        self.fail_next = "verification"
        with self.assertRaises(backend.DNSError):
            backend.change_dns(backend.PRESETS["Quad9"])
        self.assertEqual(self.effective, ("8.8.8.8",))
        self.assertEqual(backend.nameservers(self.override), ("8.8.8.8",))

    def test_permission_failure_does_not_claim_success(self):
        self.fail_next = "permission"
        with self.assertRaisesRegex(backend.DNSError, "Permission denied"):
            backend.change_dns(backend.PRESETS["Cloudflare"])
        self.assertEqual(self.effective, ("192.168.88.247",))

    def test_failed_rollback_is_reported(self):
        with patch.object(backend, "write_override", side_effect=backend.DNSError("resolver locked")):
            with self.assertRaisesRegex(backend.DNSError, "Could not restore"):
                backend.change_dns(backend.PRESETS["Cloudflare"])


class ProbeTests(unittest.TestCase):
    def check_reply(self, transform):
        # A local UDP responder exercises the real packet code, with no internet.
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as responder:
            responder.bind(("127.0.0.1", 0))
            responder.settimeout(2)
            endpoint = responder.getsockname()
            def respond():
                request, peer = responder.recvfrom(4096)
                responder.sendto(transform(request), peer)
            thread = threading.Thread(target=respond, daemon=True)
            thread.start()
            real_socket = socket.socket
            class RedirectedSocket(real_socket):
                def connect(self, _endpoint):
                    super().connect(endpoint)
            with patch.object(backend.socket, "socket", RedirectedSocket):
                result = backend.probe("127.0.0.1", timeout=1)
            thread.join(timeout=2)
            return result

    def test_valid_reply(self):
        ok, duration = self.check_reply(lambda q: q[:2] + struct.pack("!5H", 0x8180, 1, 1, 0, 0) + q[12:] + b"\xc0\x0c\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04\x01\x02\x03\x04")
        self.assertTrue(ok)
        self.assertTrue(duration.endswith(" ms"))

    def test_wrong_transaction_and_dns_errors(self):
        self.assertFalse(self.check_reply(lambda q: b"\x00")[0])
        self.assertFalse(self.check_reply(lambda q: q[:2] + struct.pack("!5H", 0x8182, 1, 0, 0, 0) + q[12:])[0])
        self.assertFalse(self.check_reply(lambda q: bytes([q[0] ^ 255, q[1]]) + struct.pack("!5H", 0x8180, 1, 1, 0, 0) + q[12:])[0])


if __name__ == "__main__":
    unittest.main()
