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
