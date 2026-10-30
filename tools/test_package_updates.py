"""Updater contracts tested with fake release sources and real temporary Git repos."""

import base64
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import package_updates as updates


class FakeHttp:
    def __init__(self, values):
        self.values = values

    def json(self, url):
        value = self.values[url]
        if isinstance(value, Exception):
            raise value
        return value

    def github(self, repo, suffix):
        return self.json(f"{repo}/{suffix}")

    def text(self, url):
        return self.json(url)


class ReleaseTests(unittest.TestCase):
    def test_nightly_selection_ignores_stable_and_other_prereleases(self):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            (repo / "packages").mkdir()
            (repo / "packages/default.nix").write_text('  t3codeVersion = "0.1.2-nightly.20261021.9";\n')
            releases = [
                {"draft": False, "tag_name": "v9.0.0", "assets": []},
                {"draft": False, "tag_name": "v9.0.0-beta.1", "assets": []},
                {"draft": True, "tag_name": "v1.0.0-nightly.20261023.1", "assets": []},
            ]
            for number in [9, 10]:
                version = f"0.1.2-nightly.20261022.{number}"
                releases.append({"draft": False, "tag_name": "v" + version,
                                 "html_url": "https://example.invalid/release",
                                 "assets": [{"name": f"T3-Code-{version}-x86_64.AppImage"}]})
            client = FakeHttp({"pingdotgg/t3code/releases?per_page=100&page=1": releases})
            result = updates.Updater(repo, client).discover("t3code")
            self.assertEqual(result.status, "available")
            self.assertEqual(result.latest, "0.1.2-nightly.20261022.10")

    def npm_repo(self, repo):
        (repo / "nix/sanity-cli-npm").mkdir(parents=True)
        (repo / "packages").mkdir()
        package = "@sanity/cli"
        updates.write_json(repo / "nix/sanity-cli-npm/package.json", {"dependencies": {package: "8.1.0"}})
        updates.write_json(repo / "nix/sanity-cli-npm/package-lock.json", {
            "packages": {"node_modules/" + package: {"version": "8.1.0"}}})
        (repo / "packages/default.nix").write_text('  sanity-cli = {\n    version = "8.1.0";\n  };\n')

    def test_older_registry_version_is_not_a_downgrade(self):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            self.npm_repo(repo)
            client = FakeHttp({"https://registry.npmjs.org/@sanity/cli/latest": {"version": "8.0.0"}})
            result = updates.Updater(repo, client).discover("sanity-cli")
            self.assertEqual(result.status, "ahead-of-upstream")

    def test_release_failure_is_not_reported_as_up_to_date(self):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            self.npm_repo(repo)
            client = FakeHttp({"https://registry.npmjs.org/@sanity/cli/latest": updates.UpdateError("rate limited")})
            result = updates.Updater(repo, client).discover("sanity-cli")
            self.assertEqual(result.status, "failed")
            self.assertIn("rate limited", result.error)

    def test_lock_and_manifest_disagreement_requires_review(self):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            self.npm_repo(repo)
            path = repo / "nix/sanity-cli-npm/package-lock.json"
            lock = updates.read_json(path)
            lock["packages"]["node_modules/@sanity/cli"]["version"] = "8.0.0"
            updates.write_json(path, lock)
            result = updates.Updater(repo, FakeHttp({})).discover("sanity-cli")
            self.assertEqual(result.status, "failed")
            self.assertIn("lock and manifest disagree", result.error)

    def test_missing_integrity_is_filled_only_for_matching_source(self):
        tarball = "https://registry.npmjs.org/example/-/example-1.0.0.tgz"
        client = FakeHttp({"https://registry.npmjs.org/example/1.0.0": {
            "dist": {"tarball": tarball, "integrity": "sha512-expected"}}})
        updater = updates.Updater(".", client)
        lock = {"packages": {"node_modules/example": {"version": "1.0.0", "resolved": tarball}}}
        updater.fill_integrities(lock)
        self.assertEqual(lock["packages"]["node_modules/example"]["integrity"], "sha512-expected")
        lock["packages"]["node_modules/example"] = {"version": "1.0.0", "resolved": tarball + "?different"}
        with self.assertRaisesRegex(updates.UpdateError, "does not match"):
            updater.fill_integrities(lock)

    def test_download_rejects_checksum_mismatch(self):
        client = updates.Http()
        checksum = "sha256-" + base64.b64encode(hashlib.sha256(b"expected").digest()).decode()
        with tempfile.TemporaryDirectory() as folder, patch.object(client, "get", return_value=io.BytesIO(b"wrong")):
            with self.assertRaisesRegex(updates.UpdateError, "checksum mismatch"):
                client.download("https://example.invalid/download", Path(folder) / "download", checksum)


class ClaudeCodeAdapterTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        (self.repo / "packages").mkdir()
        self.path = self.repo / "packages/default.nix"
        self.original = '''  claude-code = pkgs.claude-code.overrideAttrs (finalAttrs: previousAttrs: {
    version = "2.1.177";
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${finalAttrs.version}/linux-x64/claude";
      hash = "old-claude-hash";
    };
    meta = previousAttrs.meta // { platforms = [ "x86_64-linux" ]; };
  });
  another-package = { version = "2.1.177"; hash = "unrelated-hash"; };
'''
        self.path.write_text(self.original)
        self.manifest_url = updates.CLAUDE_RELEASES + "/2.1.180/manifest.json"
        self.manifest = {"version": "2.1.180", "platforms": {
            "linux-x64": {"binary": "claude", "checksum": "ab" * 32}}}
        self.client = FakeHttp({updates.CLAUDE_RELEASES + "/latest": "2.1.180\n",
                                self.manifest_url: self.manifest})
        self.updater = updates.Updater(self.repo, self.client)

    def test_check_reads_native_release_and_matching_platform_without_writing(self):
        item = self.updater.discover("claude-code")
        self.assertEqual((item.current, item.latest, item.status), ("2.1.177", "2.1.180", "available"))
        self.assertEqual(item.channel, "latest")
        self.assertEqual(item.source, self.manifest_url)
        self.assertEqual(item.details["checksum"], "ab" * 32)
        self.assertEqual(self.path.read_text(), self.original)

    def test_current_and_newer_pins_are_not_downgraded(self):
        for current, status in [("2.1.180", "up-to-date"), ("2.1.181", "ahead-of-upstream")]:
            with self.subTest(current=current):
                self.path.write_text(self.original.replace('version = "2.1.177"', f'version = "{current}"'))
                self.assertEqual(self.updater.discover("claude-code").status, status)

    def test_prerelease_or_malformed_feed_is_rejected_before_fetching_manifest(self):
        for version in ["2.1.180-beta.1", "../other", "", "3.0"]:
            with self.subTest(version=version):
                self.client.values[updates.CLAUDE_RELEASES + "/latest"] = version
                self.assertIn("unsupported version", self.updater.discover("claude-code").error)

    def test_manifest_requires_matching_version_platform_binary_and_checksum(self):
        for manifest in [
            {**self.manifest, "version": "2.1.179"},
            {"version": "2.1.180", "platforms": {"linux-arm64": self.manifest["platforms"]["linux-x64"]}},
            {"version": "2.1.180", "platforms": {"linux-x64": {"binary": "other", "checksum": "ab" * 32}}},
            {"version": "2.1.180", "platforms": {"linux-x64": {"binary": "claude", "checksum": "invalid"}}},
        ]:
            with self.subTest(manifest=manifest):
                self.client.values[self.manifest_url] = manifest
                item = self.updater.discover("claude-code")
                self.assertEqual(item.status, "failed")
                self.assertIn("manifest must match", item.error)

    def test_network_failure_is_reported_as_failed(self):
        self.client.values[self.manifest_url] = updates.UpdateError("release feed unavailable")
        item = self.updater.discover("claude-code")
        self.assertEqual(item.status, "failed")
        self.assertIn("release feed unavailable", item.error)

    def test_update_verifies_binary_and_preserves_wrapper_and_other_packages(self):
        item = self.updater.discover("claude-code")
        with patch.object(self.client, "download", create=True, return_value="new-claude-hash") as download:
            self.updater.update_download(self.repo, item)
        expected = self.original.replace('version = "2.1.177"', 'version = "2.1.180"', 1)
        self.assertEqual(self.path.read_text(), expected.replace("old-claude-hash", "new-claude-hash"))
        self.assertEqual(download.call_args.args[0], updates.CLAUDE_RELEASES + "/2.1.180/linux-x64/claude")
        self.assertEqual(download.call_args.args[2], "sha256-" + base64.b64encode(bytes.fromhex("ab" * 32)).decode())

    def test_changed_native_packaging_requires_review_before_downloading(self):
        item = self.updater.discover("claude-code")
        for before in [self.original.replace("/linux-x64/", "/linux-arm64/"),
                       self.original.replace("pkgs.claude-code.overrideAttrs", "pkgs.stdenvNoCC.mkDerivation")]:
            with self.subTest(before=before):
                self.path.write_text(before)
                with patch.object(self.client, "download", create=True) as download:
                    with self.assertRaisesRegex(updates.UpdateError, "native packaging changed"):
                        self.updater.update_download(self.repo, item)
                    download.assert_not_called()
                self.assertEqual(self.path.read_text(), before)

    def test_failed_checksum_verification_does_not_change_package(self):
        item = self.updater.discover("claude-code")
        with patch.object(self.client, "download", create=True, side_effect=updates.UpdateError("checksum mismatch")):
            with self.assertRaisesRegex(updates.UpdateError, "checksum mismatch"):
                self.updater.update_download(self.repo, item)
        self.assertEqual(self.path.read_text(), self.original)


class TailscaleAdapterTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        (self.repo / "packages").mkdir()
        self.path = self.repo / "packages/tailscale.nix"
        self.original = '''{ stdenvNoCC, fetchurl, makeWrapper }:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tailscale";
  version = "1.104.1";
  src = fetchurl {
    url = "https://pkgs.tailscale.com/stable/tailscale_${finalAttrs.version}_amd64.tgz";
    hash = "old-hash";
  };
  installPhase = ''
    wrapProgram "$out/bin/tailscaled" --prefix PATH : /existing/tools
    install -Dm644 systemd/tailscaled.service "$out/lib/systemd/system/tailscaled.service"
  '';
})
'''
        self.path.write_text(self.original)
        self.feed = "https://pkgs.tailscale.com/stable/?mode=json"
        self.url = "https://pkgs.tailscale.com/stable/tailscale_1.104.4_amd64.tgz"
        self.metadata = {"Version": "9.9.9", "TarballsVersion": "1.104.4",
                         "Tarballs": {"amd64": "tailscale_1.104.4_amd64.tgz"}}
        self.client = FakeHttp({self.feed: self.metadata, self.url + ".sha256": "ab" * 32 + "\n"})
        self.updater = updates.Updater(self.repo, self.client)

    def test_stable_linux_feed_drives_discovery_without_downloading(self):
        item = self.updater.discover("tailscale")
        self.assertEqual((item.current, item.latest, item.status), ("1.104.1", "1.104.4", "available"))
        self.assertEqual(item.channel, "stable")
        self.assertEqual(item.details["tarball"], self.url)
        self.assertEqual(self.path.read_text(), self.original)

    def test_stable_feed_rejects_prereleases_and_wrong_or_missing_architecture(self):
        for version, tarballs in [
            ("1.105.0-beta.1", {"amd64": "tailscale_1.105.0-beta.1_amd64.tgz"}),
            ("1.104.4", {"arm64": "tailscale_1.104.4_arm64.tgz"}),
            ("1.104.4", {"amd64": "../unstable/tailscale_1.104.4_amd64.tgz"}),
        ]:
            with self.subTest(version=version, tarballs=tarballs):
                self.client.values[self.feed] = {"TarballsVersion": version, "Tarballs": tarballs}
                self.assertEqual(self.updater.discover("tailscale").status, "failed")

    def test_current_and_newer_pins_are_not_downgraded(self):
        for current, status in [("1.104.4", "up-to-date"), ("1.104.10", "ahead-of-upstream")]:
            with self.subTest(current=current):
                self.path.write_text(self.original.replace('version = "1.104.1"', f'version = "{current}"'))
                self.assertEqual(self.updater.discover("tailscale").status, status)

    def test_update_verifies_checksum_and_preserves_wrapper_and_service(self):
        item = self.updater.discover("tailscale")
        with patch.object(self.client, "download", create=True, return_value="new-hash") as download:
            self.updater.update_download(self.repo, item)
        self.assertEqual(self.path.read_text(), self.original.replace('version = "1.104.1"',
                         'version = "1.104.4"').replace("old-hash", "new-hash"))
        self.assertEqual(download.call_args.args[0], self.url)
        self.assertEqual(download.call_args.args[2], "sha256-" + base64.b64encode(bytes.fromhex("ab" * 32)).decode())

    def test_changed_source_requires_review_before_downloading(self):
        item = self.updater.discover("tailscale")
        before = self.original.replace("/stable/", "/unstable/")
        self.path.write_text(before)
        with patch.object(self.client, "download", create=True) as download:
            with self.assertRaisesRegex(updates.UpdateError, "source template changed"):
                self.updater.update_download(self.repo, item)
            download.assert_not_called()
        self.assertEqual(self.path.read_text(), before)

    def test_invalid_checksum_or_download_failure_keeps_package_unchanged(self):
        item = self.updater.discover("tailscale")
        with patch.object(self.client, "download", create=True,
                          side_effect=updates.UpdateError("published checksum mismatch")) as download:
            for checksum in ["not-a-checksum", "ab" * 32]:
                with self.subTest(checksum=checksum):
                    self.client.values[self.url + ".sha256"] = checksum
                    with self.assertRaises(updates.UpdateError):
                        self.updater.update_download(self.repo, item)
                    self.assertEqual(self.path.read_text(), self.original)
            self.assertEqual(download.call_count, 1)


class DesktopAdapterTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        (self.repo / "packages").mkdir()
        self.packages = self.repo / "packages/default.nix"
        self.original = '''  t3codeVersion = "0.1.2-nightly.20261021.9";
  t3codeSrc = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${t3codeVersion}/T3-Code-${t3codeVersion}-x86_64.AppImage";
    hash = "old-t3-hash";
  };
  photocraftVersion = "0.10.0";
  photocraftSrc = pkgs.fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${photocraftVersion}/photocraft-${photocraftVersion}-linux-x86_64.AppImage";
    hash = "old-photocraft-hash";
  };
  photocraft = pkgs.appimageTools.wrapAppImage {
    version = photocraftVersion;
    extraInstallCommands = 'wrapProgram $out/bin/photocraft --set-default PHOTOCRAFT_NATIVE_WAYLAND 1';
  };
'''
        self.packages.write_text(self.original)
        self.flake = self.repo / "flake.nix"
        self.flake.write_text('  handy.url = "github:cjpais/Handy/v0.9.8";\n# existing configuration\n')
        self.lock = self.repo / "flake.lock"
        updates.write_json(self.lock, {"root": "root", "nodes": {
            "root": {"inputs": {"handy": "handy", "nixpkgs": "nixpkgs"}},
            "handy": {"locked": {"type": "github", "owner": "cjpais", "repo": "Handy", "rev": "old"},
                      "original": {"type": "github", "owner": "cjpais", "repo": "Handy", "ref": "v0.9.8"}},
            "nixpkgs": {"locked": {"rev": "unrelated"}},
        }})

    def release(self, name, version):
        repo = "storytold/photocraft" if name == "photocraft" else "cjpais/Handy"
        return {"draft": False, "prerelease": False, "tag_name": "v" + version,
                "html_url": f"https://github.com/{repo}/releases/tag/v{version}",
                "assets": [{"name": f"photocraft-{version}-linux-x86_64.AppImage",
                            "browser_download_url": f"https://github.com/{repo}/releases/download/v{version}/photocraft-{version}-linux-x86_64.AppImage",
                            "digest": "sha256:" + "ab" * 32}]}

    def test_photocraft_stable_release_and_exact_linux_asset_are_required(self):
        release = self.release("photocraft", "0.11.0")
        client = FakeHttp({"storytold/photocraft/releases/latest": release})
        updater = updates.Updater(self.repo, client)
        result = updater.discover("photocraft")
        self.assertEqual((result.current, result.latest, result.status), ("0.10.0", "0.11.0", "available"))
        for field in ("draft", "prerelease"):
            with self.subTest(field=field):
                release[field] = True
                self.assertEqual(updater.discover("photocraft").status, "failed")
                release[field] = False
        release["assets"][0]["name"] = "photocraft-0.11.0-linux-aarch64.AppImage"
        self.assertEqual(updater.discover("photocraft").status, "failed")

    def test_photocraft_updates_only_its_version_and_hash_and_checks_published_digest(self):
        release = self.release("photocraft", "0.11.0")
        client = FakeHttp({"storytold/photocraft/releases/latest": release})
        updater = updates.Updater(self.repo, client)
        item = updater.discover("photocraft")
        with patch.object(client, "download", create=True, return_value="new-hash") as download:
            updater.update_download(self.repo, item)
        expected = self.original.replace('photocraftVersion = "0.10.0"', 'photocraftVersion = "0.11.0"')
        self.assertEqual(self.packages.read_text(), expected.replace("old-photocraft-hash", "new-hash"))
        self.assertEqual(download.call_args.args[2], "sha256-" + base64.b64encode(bytes.fromhex("ab" * 32)).decode())

    def test_photocraft_changed_source_requires_review_before_download(self):
        client = FakeHttp({"storytold/photocraft/releases/latest": self.release("photocraft", "0.11.0")})
        updater = updates.Updater(self.repo, client)
        item = updater.discover("photocraft")
        before = self.original.replace("github.com/storytold/photocraft", "example.invalid/photocraft")
        self.packages.write_text(before)
        with patch.object(client, "download", create=True) as download:
            with self.assertRaisesRegex(updates.UpdateError, "source template changed"):
                updater.update_download(self.repo, item)
            download.assert_not_called()
        self.assertEqual(self.packages.read_text(), before)

    def test_t3_download_still_updates_only_t3(self):
        version = "0.1.2-nightly.20261022.1"
        client = FakeHttp({})
        item = updates.Candidate(package="t3code", current="0.1.2-nightly.20261021.9", latest=version,
                                 details={"asset": {"browser_download_url": f"https://github.com/pingdotgg/t3code/releases/download/v{version}/T3-Code-{version}-x86_64.AppImage"}})
        with patch.object(client, "download", create=True, return_value="new-hash"):
            updates.Updater(self.repo, client).update_download(self.repo, item)
        expected = self.original.replace(item.current, version).replace("old-t3-hash", "new-hash")
        self.assertEqual(self.packages.read_text(), expected)

    def test_handy_updates_its_flake_pin_and_keeps_unrelated_inputs(self):
        client = FakeHttp({"cjpais/Handy/releases/latest": self.release("handy", "0.9.9")})
        updater = updates.Updater(self.repo, client)
        item = updater.discover("handy")
        self.assertEqual((item.current, item.latest, item.status), ("0.9.8", "0.9.9", "available"))
        before = self.flake.read_text()
        def lock_input(command, **kwargs):
            self.assertEqual(command, ["nix", "flake", "update", *updates.SAFE_NIX, "handy"])
            lock = updates.read_json(self.lock)
            lock["nodes"]["handy"]["original"]["ref"] = "v0.9.9"
            lock["nodes"]["handy"]["locked"]["rev"] = "new"
            updates.write_json(self.lock, lock)
        with patch.object(updates, "run", side_effect=lock_input):
            updater.update_flake(self.repo, item)
        self.assertEqual(self.flake.read_text(), before.replace("v0.9.8", "v0.9.9"))
        self.assertEqual(updates.read_json(self.lock)["nodes"]["nixpkgs"]["locked"]["rev"], "unrelated")

    def test_handy_mismatched_or_nonstable_pin_requires_review(self):
        client = FakeHttp({"cjpais/Handy/releases/latest": self.release("handy", "0.9.9")})
        updater = updates.Updater(self.repo, client)
        self.flake.write_text(self.flake.read_text().replace("v0.9.8", "v0.9.7"))
        self.assertIn("flake URL and lock pin disagree", updater.discover("handy").error)
        lock = updates.read_json(self.lock)
        lock["nodes"]["handy"]["original"]["ref"] = "main"
        updates.write_json(self.lock, lock)
        self.assertIn("stable release tag", updater.discover("handy").error)


class WorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name) / "dotfiles"
        self.repo.mkdir()
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        updates.git(self.repo, "config", "user.email", "tests@example.invalid")
        updates.git(self.repo, "config", "user.name", "Updater tests")
        (self.repo / "packages").mkdir()
        self.path = self.repo / "packages/vercel-cli.nix"
        self.original = '{ version = "1.0.0"; hash = "old"; }\n'
        self.path.write_text(self.original)
        updates.git(self.repo, "add", ".")
        updates.git(self.repo, "commit", "-qm", "fixture")

    def tearDown(self):
        self.temporary.cleanup()

    def candidate(self):
        return updates.Candidate(package="vercel-cli", current="1.0.0", latest="1.1.0", status="available")

    def update_package(self, updater, workspace, item):
        path = workspace / "packages/vercel-cli.nix"
        path.write_text(path.read_text().replace("1.0.0", "1.1.0"))

    def test_update_edits_current_checkout_and_repeat_run_checks_current_files(self):
        def check(_):
            item = self.candidate()
            if "1.1.0" in self.path.read_text():
                item.current, item.status = "1.1.0", "up-to-date"
            return [item]
        branch = updates.git(self.repo, "branch", "--show-current")
        with patch.object(updates.Updater, "check", side_effect=check), \
             patch.object(updates.Updater, "update_download", autospec=True, side_effect=self.update_package), \
             patch.object(updates, "validate_workspace", return_value={"status": "passed"}):
            first = updates.execute(self.repo, "update", "vercel-cli")
            self.assertEqual(first["summary"], {"updated": 1})
            self.assertIn("1.1.0", self.path.read_text())
            self.assertEqual(Path(first["worktree"]), self.repo)
            second = updates.execute(self.repo, "update", "vercel-cli")
            self.assertEqual(second["summary"], {"up-to-date": 1})
            self.assertEqual(first["branch"], branch)
            self.assertEqual(updates.git(self.repo, "branch", "--show-current"), branch)
            self.assertEqual(len(updates.git(self.repo, "worktree", "list").splitlines()), 1)

    def test_existing_edits_are_preserved_in_update_mode(self):
        self.path.write_text(self.original + "# custom wrapper settings\n")
        other = self.repo / "notes.txt"
        other.write_text("unrelated user changes\n")
        with patch.object(updates.Updater, "check", return_value=[self.candidate()]), \
             patch.object(updates.Updater, "update_download", autospec=True, side_effect=self.update_package), \
             patch.object(updates, "validate_workspace", return_value={"status": "passed"}):
            result = updates.execute(self.repo, "update", "vercel-cli")
        self.assertEqual(result["summary"], {"updated": 1})
        self.assertIn("# custom wrapper settings", self.path.read_text())
        self.assertEqual(other.read_text(), "unrelated user changes\n")

    def test_edits_during_release_check_are_not_overwritten(self):
        def check(_):
            self.path.write_text("human review changes\n")
            return [self.candidate()]
        with patch.object(updates.Updater, "check", side_effect=check), \
             patch.object(updates.Updater, "apply") as apply:
            with self.assertRaisesRegex(updates.UpdateError, "Working tree changed"):
                updates.execute(self.repo, "update", "vercel-cli")
            apply.assert_not_called()
        self.assertEqual(self.path.read_text(), "human review changes\n")

    def test_failed_package_edit_is_rolled_back(self):
        self.path.write_text(self.original + "# existing user edit\n")
        before = self.path.read_text()
        item = self.candidate()
        def fail(workspace, candidate):
            (workspace / "packages/vercel-cli.nix").write_text("partially updated\n")
            raise updates.UpdateError("checksum failed")
        updater = updates.Updater(self.repo)
        with patch.object(updater, "update_download", side_effect=fail):
            updater.apply(self.repo, item)
        self.assertEqual(item.status, "failed")
        self.assertEqual(self.path.read_text(), before)

    def test_concurrent_update_is_rejected_before_checking_releases(self):
        git_dir = Path(updates.git(self.repo, "rev-parse", "--absolute-git-dir"))
        with (git_dir / "nix-package-updates.lock").open("a") as lock:
            updates.fcntl.flock(lock, updates.fcntl.LOCK_EX | updates.fcntl.LOCK_NB)
            with patch.object(updates.Updater, "check") as check:
                with self.assertRaisesRegex(updates.UpdateError, "already running"):
                    updates.execute(self.repo, "update", "vercel-cli")
                check.assert_not_called()

    def test_unchanged_failed_workspace_can_retry(self):
        calls = []
        def temporarily_fail(updater, workspace, item):
            calls.append(item.package)
            if len(calls) == 1:
                raise updates.UpdateError("temporary download failure")
            self.update_package(updater, workspace, item)
        with patch.object(updates.Updater, "check", side_effect=lambda _: [self.candidate()]), \
             patch.object(updates.Updater, "update_download", autospec=True, side_effect=temporarily_fail), \
             patch.object(updates, "validate_workspace", return_value={"status": "passed"}):
            first = updates.execute(self.repo, "update", "vercel-cli")
            self.assertEqual(first["summary"], {"failed": 1})
            second = updates.execute(self.repo, "update", "vercel-cli")
            self.assertEqual(second["summary"], {"updated": 1})
            self.assertEqual(first["branch"], second["branch"])

    def test_failed_evaluation_retries_without_reapplying_packages(self):
        current = self.candidate()
        current.current, current.status = "1.1.0", "up-to-date"
        with patch.object(updates.Updater, "check", side_effect=[[self.candidate()], [current]]), \
             patch.object(updates.Updater, "update_download", autospec=True, side_effect=self.update_package) as apply, \
             patch.object(updates, "validate_workspace", side_effect=[{"status": "failed"}, {"status": "passed"}]):
            first = updates.execute(self.repo, "update", "vercel-cli")
            self.assertEqual(first["validation"]["status"], "failed")
            second = updates.execute(self.repo, "update", "vercel-cli")
            self.assertEqual(second["validation"]["status"], "passed")
            self.assertEqual(apply.call_count, 1)

    def test_check_mode_accepts_dirty_source_and_makes_no_branch(self):
        self.path.write_text("user changes\n")
        before = updates.git(self.repo, "branch", "--list")
        with patch.object(updates.Updater, "check", return_value=[self.candidate()]):
            report = updates.execute(self.repo, "check", "vercel-cli")
        self.assertEqual(report["summary"], {"available": 1})
        self.assertEqual(self.path.read_text(), "user changes\n")
        self.assertEqual(updates.git(self.repo, "branch", "--list"), before)

    def test_package_selection_order_is_canonical(self):
        with patch.object(updates.Updater, "check", return_value=[]) as check:
            updates.execute(self.repo, "check", "vercel-cli,pi,pi")
        self.assertEqual(check.call_args.args[0], ["pi", "vercel-cli"])

    def test_unknown_package_selection_is_rejected(self):
        with self.assertRaisesRegex(updates.UpdateError, "Unknown package"):
            updates.execute(self.repo, packages="all; touch something")

    def test_evaluation_explicitly_disables_import_from_derivation(self):
        with patch.object(updates, "run", return_value="/nix/store/test.drv") as runner:
            result = updates.validate_workspace(self.repo)
        command = runner.call_args.args[0]
        self.assertEqual(command[0:2], ["nix", "eval"])
        self.assertIn("allow-import-from-derivation", command)
        self.assertIn("false", command)
        self.assertIn("--no-write-lock-file", command)
        self.assertFalse(result["built"])
        self.assertFalse(result["activated"])


if __name__ == "__main__":
    unittest.main()
