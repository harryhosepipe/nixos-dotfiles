#!/usr/bin/env python3
"""Check selected Nix packages and prepare updates without building anything.

Only update mode writes package files, directly in the current checkout. Subprocesses
use argument arrays; package lifecycle scripts and Nix import-from-derivation
are disabled. The Swamp behavior calls the same entry point as the local CLI.
"""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import dataclasses
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request


TARGETS = {
    "codex-desktop": {
        "kind": "codex", "repo": "ilysenko/codex-desktop-linux",
        "channel": "upstream Linux packaging branch", "input": "codex-desktop-linux",
        "files": ["flake.lock"],
    },
    "claude-code": {
        "kind": "claude-native", "channel": "latest",
        "files": ["packages/default.nix"],
    },
    "hermes-desktop": {
        "kind": "hermes", "repo": "NousResearch/hermes-agent", "channel": "stable",
        "input": "hermes-agent",
        "files": ["flake.nix", "flake.lock", "modules/home/hermes.nix"],
    },
    "pi": {
        "kind": "npm", "npm": "@earendil-works/pi-coding-agent", "channel": "latest",
        "manifest": "nix/pi-npm", "nix": "modules/home/pi.nix", "variable": "piVersion",
        "files": ["modules/home/pi.nix", "nix/pi-npm/package.json", "nix/pi-npm/package-lock.json"],
    },
    "t3code": {
        "kind": "appimage", "repo": "pingdotgg/t3code", "channel": "nightly",
        "variable": "t3codeVersion", "source": "t3codeSrc",
        "asset": "T3-Code-{version}-x86_64.AppImage",
        "files": ["packages/default.nix"],
    },
    "photocraft": {
        "kind": "appimage", "repo": "storytold/photocraft", "channel": "stable",
        "variable": "photocraftVersion", "source": "photocraftSrc",
        "asset": "photocraft-{version}-linux-x86_64.AppImage",
        "files": ["packages/default.nix"],
    },
    "handy": {
        "kind": "stable-flake", "repo": "cjpais/Handy", "channel": "stable",
        "input": "handy", "files": ["flake.nix", "flake.lock"],
    },
    "dokploy-cli": {
        "kind": "pnpm", "repo": "Dokploy/cli", "channel": "stable",
        "files": ["packages/default.nix"],
    },
    "vercel-cli": {
        "kind": "native-npm", "npm": "@vercel/vc-native-linux-x64", "channel": "latest",
        "files": ["packages/vercel-cli.nix"],
    },
    "tailscale": {
        "kind": "tailscale", "channel": "stable",
        "files": ["packages/tailscale.nix"],
    },
    "sanity-cli": {
        "kind": "npm", "npm": "@sanity/cli", "channel": "latest",
        "manifest": "nix/sanity-cli-npm", "nix": "packages/default.nix",
        "files": ["packages/default.nix", "nix/sanity-cli-npm/package.json", "nix/sanity-cli-npm/package-lock.json"],
    },
}
SAFE_NIX = ["--option", "allow-import-from-derivation", "false"]
CLAUDE_RELEASES = "https://downloads.claude.ai/claude-code-releases"
VERSION = re.compile(r"^(\d+)\.(\d+)\.(\d+)(?:-nightly\.(\d{8})\.(\d+))?$")


class UpdateError(Exception):
    pass


def run(args, *, cwd=None, env=None, timeout=1800):
    """Capture noisy tool output, exposing a bounded diagnostic on failure."""
    result = subprocess.run(
        [str(x) for x in args], cwd=cwd, env={**os.environ, **(env or {})},
        text=True, capture_output=True, timeout=timeout,
    )
    if result.returncode:
        detail = (result.stderr or result.stdout).strip()[-2500:]
        raise UpdateError(f"{args[0]} exited {result.returncode}: {detail}")
    return result.stdout.strip()


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def version_key(value):
    match = VERSION.fullmatch(value)
    if not match:
        raise UpdateError(f"Unsupported release version: {value!r}")
    major, minor, patch, date, sequence = match.groups()
    return tuple(map(int, (major, minor, patch))) + (int(date or 0), int(sequence or 0))


def package_block(text, name):
    match = re.search(rf"(?m)^  {re.escape(name)} = ", text)
    if not match:
        raise UpdateError(f"Cannot find the {name} package definition")
    following = re.search(r"(?m)^  [A-Za-z_][\w-]* = ", text[match.end():])
    end = match.end() + following.start() if following else len(text)
    return match.start(), end


def assignment(text, name):
    matches = re.findall(rf'(?m)^\s*{re.escape(name)} = "([^"\n]+)";', text)
    if len(matches) != 1:
        raise UpdateError(f"Expected one {name} assignment, found {len(matches)}")
    return matches[0]


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise UpdateError(f"Expected one occurrence of {old!r}; packaging needs review")
    return text.replace(old, new, 1)


class Http:
    def get(self, url):
        if not url.startswith("https://"):
            raise UpdateError("Release downloads must use HTTPS")
        headers = {"User-Agent": "nix-dot-package-updates/1"}
        if urllib.parse.urlparse(url).hostname == "api.github.com":
            token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
            if token:
                headers["Authorization"] = "Bearer " + token
        for attempt in range(3):
            try:
                return urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60)
            except urllib.error.HTTPError as exc:
                if exc.code not in (429, 500, 502, 503, 504) or attempt == 2:
                    raise UpdateError(f"HTTP {exc.code} fetching {url}") from exc
            except (OSError, TimeoutError) as exc:
                if attempt == 2:
                    raise UpdateError(f"Failed fetching {url}: {exc}") from exc
            time.sleep(attempt + 1)
        raise AssertionError("unreachable")

    def json(self, url):
        with self.get(url) as response:
            return json.load(response)

    def text(self, url):
        with self.get(url) as response:
            return response.read().decode()

    def github(self, repo, suffix):
        return self.json(f"https://api.github.com/repos/{repo}/{suffix}")

    def raw_json(self, repo, ref, path):
        return self.json(f"https://raw.githubusercontent.com/{repo}/{ref}/{path}")

    def download(self, url, path, integrity=None):
        sha256 = hashlib.sha256()
        expected = None
        check = None
        if integrity:
            algorithm, encoded = integrity.split("-", 1)
            if algorithm not in ("sha1", "sha256", "sha384", "sha512"):
                raise UpdateError(f"Unsupported published checksum algorithm: {algorithm}")
            expected = base64.b64decode(encoded, validate=True)
            check = hashlib.new(algorithm)
        size = 0
        with self.get(url) as response, Path(path).open("wb") as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
                sha256.update(chunk)
                if check:
                    check.update(chunk)
                size += len(chunk)
        if not size or (check and check.digest() != expected):
            raise UpdateError(f"Empty download or published checksum mismatch: {url}")
        return "sha256-" + base64.b64encode(sha256.digest()).decode()


@dataclasses.dataclass
class Candidate:
    package: str
    current: str = "unknown"
    latest: str = "unknown"
    status: str = "failed"
    source: str = ""
    channel: str = ""
    error: str | None = None
    details: dict = dataclasses.field(default_factory=dict)
    changedFiles: list = dataclasses.field(default_factory=list)


class Updater:
    def __init__(self, repo, http=None):
        self.repo = Path(repo).resolve()
        self.http = http or Http()
        self._tools = {}

    def tool(self, attribute, executable):
        """Resolve an existing tool from the locked Nixpkgs; never realise it."""
        key = (attribute, executable)
        if key not in self._tools:
            root = json.dumps(str(self.repo)).replace("${", "\\${")
            expression = (
                f"let f = builtins.getFlake {root}; "
                "p = import f.inputs.nixpkgs { system = builtins.currentSystem; }; "
                f'in "${{p.{attribute}}}/bin/{executable}"'
            )
            path = run(["nix", "eval", *SAFE_NIX, "--impure", "--raw", "--expr", expression], cwd=self.repo)
            if not Path(path).is_file():
                raise UpdateError(
                    f"Required tool {attribute} is not available locally. "
                    "No build was attempted; install the update tools through your Nix configuration."
                )
            self._tools[key] = path
        return self._tools[key]

    def current(self, name):
        target = TARGETS[name]
        kind = target["kind"]
        if kind in ("codex", "hermes", "stable-flake"):
            lock = read_json(self.repo / "flake.lock")
            node = lock["nodes"][lock["nodes"][lock["root"]]["inputs"][target["input"]]]
            expected_owner, expected_repo = target["repo"].split("/")
            if (node["locked"].get("type"), node["locked"].get("owner"), node["locked"].get("repo")) != ("github", expected_owner, expected_repo):
                raise UpdateError(f"{name}: flake source changed; review the update adapter")
            if kind == "codex":
                if "ref" in node["original"] or "rev" in node["original"]:
                    raise UpdateError("Codex input now uses a specific ref; review its release policy")
                revision = node["locked"]["rev"]
                pins = self.http.raw_json(target["repo"], revision, "nix/upstream-linux-packages.json")
                return pins["version"], {"revision": revision}
            ref = node["original"].get("ref", "")
            if not re.fullmatch(r"v\d+\.\d+\.\d+", ref):
                raise UpdateError(f"{name} is not pinned to a supported stable release tag")
            version = ref.removeprefix("v")
            if kind == "stable-flake" and (self.repo / "flake.nix").read_text().count(f'github:{target["repo"]}/{ref}"') != 1:
                raise UpdateError(f"{name}: flake URL and lock pin disagree")
            if kind == "hermes" and assignment((self.repo / "modules/home/hermes.nix").read_text(), "version") != version:
                raise UpdateError("Hermes flake pin and module version disagree")
            return version, {"revision": node["locked"]["rev"]}
        if kind == "npm":
            manifest = read_json(self.repo / target["manifest"] / "package.json")
            version = manifest["dependencies"][target["npm"]]
            text = (self.repo / target["nix"]).read_text()
            if name == "sanity-cli":
                start, end = package_block(text, name)
                text = text[start:end]
            if assignment(text, target.get("variable", "version")) != version:
                raise UpdateError(f"{name}: Nix version and npm manifest disagree")
            lock = read_json(self.repo / target["manifest"] / "package-lock.json")
            if lock["packages"][f"node_modules/{target['npm']}"]["version"] != version:
                raise UpdateError(f"{name}: npm lock and manifest disagree")
            return version, {}
        text = (self.repo / target["files"][0]).read_text()
        if kind == "appimage":
            return assignment(text, target["variable"]), {}
        if kind in ("pnpm", "claude-native"):
            start, end = package_block(text, name)
            text = text[start:end]
        return assignment(text, "version"), {}

    def discover(self, name):
        target = TARGETS[name]
        item = Candidate(package=name, channel=target["channel"])
        try:
            item.current, item.details = self.current(name)
            kind = target["kind"]
            if kind == "codex":
                commits = self.http.github(target["repo"], "commits?per_page=1")
                revision = commits[0]["sha"]
                pins = self.http.raw_json(target["repo"], revision, "nix/upstream-linux-packages.json")
                item.latest = pins["version"]
                item.source = f"https://github.com/{target['repo']}/commit/{revision}"
                item.details["candidateRevision"] = revision
                item.status = "available" if revision != item.details["revision"] else "up-to-date"
                if version_key(item.latest) < version_key(item.current):
                    raise UpdateError("Upstream packaging would downgrade Codex Desktop")
                return item
            if kind == "claude-native":
                item.latest = self.http.text(CLAUDE_RELEASES + "/latest").strip()
                if not re.fullmatch(r"\d+\.\d+\.\d+", item.latest):
                    raise UpdateError("Claude Code's latest channel returned an unsupported version")
                item.source = f"{CLAUDE_RELEASES}/{item.latest}/manifest.json"
                manifest = self.http.json(item.source)
                platform = manifest.get("platforms", {}).get("linux-x64", {})
                checksum = platform.get("checksum", "")
                if (manifest.get("version") != item.latest or platform.get("binary") != "claude"
                        or not re.fullmatch(r"[A-Fa-f0-9]{64}", checksum)):
                    raise UpdateError("Claude Code's manifest must match the release and provide a Linux x64 SHA-256 checksum")
                item.details["checksum"] = checksum
            elif kind == "tailscale":
                item.source = "https://pkgs.tailscale.com/stable/"
                metadata = self.http.json(item.source + "?mode=json")
                item.latest = metadata["TarballsVersion"]
                filename = f"tailscale_{item.latest}_amd64.tgz"
                if metadata.get("Tarballs", {}).get("amd64") != filename:
                    raise UpdateError("Tailscale stable metadata does not contain the expected Linux amd64 tarball")
                item.details["tarball"] = item.source + filename
            elif "npm" in target:
                metadata = self.http.json(f"https://registry.npmjs.org/{target['npm']}/latest")
                item.latest = metadata["version"]
                item.source = f"https://www.npmjs.com/package/{target['npm']}/v/{item.latest}"
                item.details["dist"] = {key: value for key, value in metadata.get("dist", {}).items()
                                        if key in ("tarball", "integrity", "shasum")}
            elif kind == "appimage" and target["channel"] == "nightly":
                if "-nightly." not in item.current:
                    raise UpdateError("T3 no longer tracks a nightly; review its release policy")
                releases = []
                for page in range(1, 4):
                    page_releases = self.http.github(target["repo"], f"releases?per_page=100&page={page}")
                    releases.extend(r for r in page_releases if not r["draft"] and re.fullmatch(
                        r"v\d+\.\d+\.\d+-nightly\.\d{8}\.\d+", r["tag_name"]))
                    if releases or len(page_releases) < 100:
                        break
                if not releases:
                    raise UpdateError("No nightly T3 release found in the latest 300 releases")
                release = max(releases, key=lambda r: version_key(r["tag_name"][1:]))
                item.latest = release["tag_name"][1:]
                item.source = release["html_url"]
            else:
                release = self.http.github(target["repo"], "releases/latest")
                if release["draft"] or release["prerelease"]:
                    raise UpdateError("Expected a published stable release")
                item.latest = release["tag_name"].removeprefix("v")
                item.source = release["html_url"]
                item.details["tag"] = release["tag_name"]
            if target["channel"] != "nightly" and not re.fullmatch(r"\d+\.\d+\.\d+", item.latest):
                raise UpdateError("The stable release source returned a prerelease or unsupported version")
            if kind == "appimage":
                asset_name = target["asset"].format(version=item.latest)
                assets = [a for a in release["assets"] if a["name"] == asset_name]
                if len(assets) != 1:
                    raise UpdateError(f"Release must contain exactly one {asset_name}")
                item.details["asset"] = {key: value for key, value in assets[0].items()
                                         if key in ("name", "browser_download_url", "digest", "size")}
            comparison = (version_key(item.latest) > version_key(item.current)) - (version_key(item.latest) < version_key(item.current))
            item.status = "available" if comparison > 0 else "up-to-date" if comparison == 0 else "ahead-of-upstream"
        except Exception as exc:
            item.status, item.error = "failed", str(exc)
        return item

    def check(self, names):
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            return list(pool.map(self.discover, names))

    def update_flake(self, workspace, item):
        target = TARGETS[item.package]
        before = read_json(workspace / "flake.lock")
        if target["kind"] in ("hermes", "stable-flake"):
            path = workspace / "flake.nix"
            old = f"github:{target['repo']}/v{item.current}"
            path.write_text(replace_once(path.read_text(), old, f"github:{target['repo']}/{item.details['tag']}"))
        if target["kind"] == "hermes":
            path = workspace / "modules/home/hermes.nix"
            path.write_text(replace_once(path.read_text(), f'version = "{item.current}";', f'version = "{item.latest}";'))
        run(["nix", "flake", "update", *SAFE_NIX, target["input"]], cwd=workspace)
        after = read_json(workspace / "flake.lock")
        roots = before["nodes"][before["root"]]["inputs"]
        for key, value in roots.items():
            if key == target["input"] or not isinstance(value, str):
                continue
            new_value = after["nodes"][after["root"]]["inputs"].get(key)
            if not isinstance(new_value, str) or before["nodes"][value].get("locked") != after["nodes"][new_value].get("locked"):
                raise UpdateError(f"Updating {target['input']} unexpectedly changed unrelated input {key}")
        node = after["nodes"][after["nodes"][after["root"]]["inputs"][target["input"]]]
        if target["kind"] == "codex" and node["locked"]["rev"] != item.details["candidateRevision"]:
            raise UpdateError("Upstream advanced during the check; rerun to check the new revision")
        if target["kind"] in ("hermes", "stable-flake") and node["original"].get("ref") != item.details["tag"]:
            raise UpdateError(f"The {item.package} lock does not match the selected release")

    def fill_integrities(self, lock):
        for location, package in lock["packages"].items():
            if not location or package.get("link") or package.get("integrity"):
                continue
            resolved = package.get("resolved", "")
            if not resolved.startswith("https://registry.npmjs.org/"):
                raise UpdateError(f"Missing integrity for non-registry dependency {location}")
            name = location.rsplit("node_modules/", 1)[-1]
            metadata = self.http.json(f"https://registry.npmjs.org/{name}/{package['version']}")
            if metadata["dist"]["tarball"] != resolved:
                raise UpdateError(f"Registry source does not match the lock for {location}")
            package["integrity"] = metadata["dist"]["integrity"]

    def update_npm(self, workspace, item):
        target = TARGETS[item.package]
        folder = workspace / target["manifest"]
        manifest = read_json(folder / "package.json")
        manifest["version"] = item.latest
        manifest["dependencies"][target["npm"]] = item.latest
        write_json(folder / "package.json", manifest)
        with tempfile.TemporaryDirectory(prefix="nix-package-npm-") as temporary:
            run([self.tool("nodejs_24", "npm"), "install", "--package-lock-only", "--ignore-scripts", "--no-audit", "--no-fund",
                 "--registry=https://registry.npmjs.org"],
                cwd=folder, env={"npm_config_cache": temporary, "npm_config_userconfig": "/dev/null"})
        lock = read_json(folder / "package-lock.json")
        self.fill_integrities(lock)
        if lock["packages"][f"node_modules/{target['npm']}"]["version"] != item.latest:
            raise UpdateError("npm did not lock the selected package version")
        write_json(folder / "package-lock.json", lock)
        path = workspace / target["nix"]
        text = path.read_text()
        if item.package == "pi":
            if "npmDepsFetcherVersion = 2;" not in text:
                raise UpdateError("Pi's npm dependency fetcher changed; review the adapter")
            text = replace_once(text, f'piVersion = "{item.current}";', f'piVersion = "{item.latest}";')
            prefetch = self.tool("prefetch-npm-deps", "prefetch-npm-deps")
            output = run([prefetch, folder / "package-lock.json"], env={"NPM_FETCHER_VERSION": "2"})
            hashes = re.findall(r"sha256-[A-Za-z0-9+/]{43}=", output)
            if not hashes:
                raise UpdateError("npm prefetch did not return a dependency hash")
            old_hash = assignment(text, "npmDepsHash")
            text = replace_once(text, old_hash, hashes[-1])
        else:
            start, end = package_block(text, item.package)
            block = replace_once(text[start:end], f'version = "{item.current}";', f'version = "{item.latest}";')
            text = text[:start] + block + text[end:]
        path.write_text(text)

    def source_archive(self, repo, tag):
        url = f"https://github.com/{repo}/archive/refs/tags/{urllib.parse.quote(tag, safe='')}.tar.gz"
        return json.loads(run(["nix", "store", "prefetch-file", "--unpack", "--json", url]))

    def pnpm_hash(self, source):
        """Fetch only dependencies; mirror the pinned fetchPnpmDeps v3 format.

        No Nix derivation is built. All lifecycle scripts and pnpmfile hooks
        are disabled. Tool versions come from this repository's locked Nixpkgs.
        """
        if any(source.glob(".pnpmfile.*")):
            raise UpdateError("Dokploy now uses a pnpmfile hook; review the packaging before updating")
        pnpm = self.tool("pnpm_10", "pnpm")
        jq = self.tool("jq", "jq")
        tar = self.tool("gnutar", "tar")
        zstd = self.tool("zstd", "zstd")
        with tempfile.TemporaryDirectory(prefix="nix-package-pnpm-") as temporary:
            root = Path(temporary)
            project, store, output = root / "source", root / "store", root / "output"
            shutil.copytree(source, project)
            for path in project.rglob("*"):
                if not path.is_symlink():
                    path.chmod(0o755 if path.is_dir() or os.access(path, os.X_OK) else 0o644)
            project.chmod(0o755)
            output.mkdir()
            if (project / ".npmrc").exists():
                config = (project / ".npmrc").read_text()
                if re.search(r"(?m)^\s*(?:global-pnpmfile|pnpmfile|node-linker|store-dir|virtual-store-dir)\s*=", config):
                    raise UpdateError("Dokploy's pnpm configuration needs packaging review")
            run([pnpm, "install", "--force", "--ignore-scripts", "--ignore-pnpmfile", "--frozen-lockfile",
                 "--store-dir", store, "--registry=https://registry.npmjs.org",
                 "--config.manage-package-manager-versions=false", "--config.side-effects-cache=false",
                 "--config.update-notifier=false"], cwd=project,
                env={"npm_config_userconfig": "/dev/null", "CI": "true"})
            for version in ("v3", "v10", "v11"):
                for name in ("tmp", "projects"):
                    shutil.rmtree(store / version / name, ignore_errors=True)
            if (store / "v11" / "index.db").exists():
                raise UpdateError("pnpm store changed to SQLite; review the fetcher before updating")
            for path in store.rglob("*.json"):
                normalized = run([jq, "--sort-keys", "del(.. | .checkedAt?)", path])
                path.write_text(normalized + "\n")
            for path in store.rglob("*"):
                if path.is_file():
                    path.chmod(0o555 if path.name.endswith("-exec") else 0o444)
                elif path.is_dir():
                    path.chmod(0o555)
            store.chmod(0o555)
            (output / ".fetcher-version").write_text("3\n")
            run([tar, "--sort=name", "--mtime=@315532800", "--owner=0", "--group=0", "--numeric-owner",
                 "--pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime", "--zstd", "-cf",
                 output / "pnpm-store.tar.zst", "."], cwd=store,
                env={"PATH": str(Path(zstd).parent) + os.pathsep + os.environ.get("PATH", "")})
            result = run(["nix", "hash", "path", "--type", "sha256", output])
            # TemporaryDirectory must be able to remove the read-only cache.
            for path in store.rglob("*"):
                if path.is_dir():
                    path.chmod(0o755)
            store.chmod(0o755)
            return result

    def update_download(self, workspace, item):
        target = TARGETS[item.package]
        path = workspace / target["files"][0]
        text = path.read_text()
        kind = target["kind"]
        if kind == "claude-native":
            start, end = package_block(text, item.package)
            block = text[start:end]
            source_url = CLAUDE_RELEASES + "/${finalAttrs.version}/linux-x64/claude"
            if assignment(block, "url") != source_url or "pkgs.claude-code.overrideAttrs" not in block:
                raise UpdateError("Claude Code's native packaging changed; review the adapter")
            checksum = item.details["checksum"]
            if not re.fullmatch(r"[A-Fa-f0-9]{64}", checksum):
                raise UpdateError("Claude Code did not publish a valid SHA-256 checksum")
            integrity = "sha256-" + base64.b64encode(bytes.fromhex(checksum)).decode()
            url = source_url.replace("${finalAttrs.version}", item.latest)
            with tempfile.TemporaryDirectory(prefix="nix-package-claude-") as temporary:
                digest = self.http.download(url, Path(temporary) / "claude", integrity)
            block = replace_once(block, f'version = "{item.current}";', f'version = "{item.latest}";')
            block = replace_once(block, assignment(block, "hash"), digest)
            path.write_text(text[:start] + block + text[end:])
            return
        if kind == "pnpm":
            start, end = package_block(text, item.package)
            block = text[start:end]
            if "fetcherVersion = 3;" not in block or "pnpm = pkgs.pnpm_10;" not in block:
                raise UpdateError("Dokploy's dependency fetcher changed; update adapter needs review")
            if 'owner = "Dokploy";' not in block or 'repo = "cli";' not in block:
                raise UpdateError("Dokploy's source repository changed; review the adapter")
            archive = self.source_archive(target["repo"], item.details["tag"])
            hashes = re.findall(r'hash = "([^"]+)";', block)
            if len(hashes) != 2:
                raise UpdateError("Expected Dokploy source and dependency hashes")
            dependency_hash = self.pnpm_hash(Path(archive["storePath"]))
            block = replace_once(block, f'version = "{item.current}";', f'version = "{item.latest}";')
            block = replace_once(block, hashes[0], archive["hash"])
            block = replace_once(block, hashes[1], dependency_hash)
            path.write_text(text[:start] + block + text[end:])
            return
        with tempfile.TemporaryDirectory(prefix="nix-package-download-") as temporary:
            if kind == "tailscale":
                source_url = "https://pkgs.tailscale.com/stable/tailscale_${finalAttrs.version}_amd64.tgz"
                if assignment(text, "url") != source_url:
                    raise UpdateError("Tailscale's source template changed; review the adapter")
                url = source_url.replace("${finalAttrs.version}", item.latest)
                if item.details["tarball"] != url:
                    raise UpdateError("Unexpected Tailscale stable tarball URL")
                checksum = self.http.text(url + ".sha256").strip()
                if not re.fullmatch(r"[A-Fa-f0-9]{64}", checksum):
                    raise UpdateError("Tailscale did not publish a valid SHA-256 checksum")
                integrity = "sha256-" + base64.b64encode(bytes.fromhex(checksum)).decode()
                digest = self.http.download(url, Path(temporary) / "package.tgz", integrity)
                text = replace_once(text, f'version = "{item.current}";', f'version = "{item.latest}";')
                text = replace_once(text, assignment(text, "hash"), digest)
            elif kind == "native-npm":
                if "https://registry.npmjs.org/@vercel/vc-native-linux-x64/-/vc-native-linux-x64-${finalAttrs.version}.tgz" not in text:
                    raise UpdateError("Vercel's source template changed; review the adapter")
                distribution = item.details["dist"]
                integrity = distribution.get("integrity")
                if not integrity:
                    raise UpdateError("npm did not publish an integrity checksum")
                url = distribution["tarball"]
                if urllib.parse.urlparse(url).hostname != "registry.npmjs.org":
                    raise UpdateError("Unexpected registry tarball host")
                digest = self.http.download(url, Path(temporary) / "package.tgz", integrity)
                text = replace_once(text, f'version = "{item.current}";', f'version = "{item.latest}";')
                text = replace_once(text, assignment(text, "hash"), digest)
            else:
                variable = target["variable"]
                source = re.escape(target["source"])
                match = re.search(rf"(?s)(  {source} = pkgs.fetchurl \{{)(.*?)(\n  \}};)", text)
                if not match:
                    raise UpdateError(f"Cannot find the {item.package} source definition")
                version_template = "${" + variable + "}"
                source_url = (f"https://github.com/{target['repo']}/releases/download/v{version_template}/"
                              + target["asset"].format(version=version_template))
                if assignment(match[2], "url") != source_url:
                    raise UpdateError(f"{item.package}'s source template changed; review the adapter")
                asset = item.details["asset"]
                expected_url = (f"https://github.com/{target['repo']}/releases/download/v{item.latest}/"
                                + target["asset"].format(version=item.latest))
                if asset["browser_download_url"] != expected_url:
                    raise UpdateError(f"Unexpected {item.package} release asset URL")
                checksum = asset.get("digest")
                integrity = None
                if checksum:
                    algorithm, hexadecimal = checksum.split(":", 1)
                    integrity = algorithm + "-" + base64.b64encode(bytes.fromhex(hexadecimal)).decode()
                digest = self.http.download(asset["browser_download_url"], Path(temporary) / "app.AppImage", integrity)
                body = replace_once(match[2], assignment(match[2], "hash"), digest)
                text = text[:match.start(2)] + body + text[match.end(2):]
                text = replace_once(text, f'{variable} = "{item.current}";', f'{variable} = "{item.latest}";')
        path.write_text(text)

    def apply(self, workspace, item):
        files = TARGETS[item.package]["files"]
        before = {name: (workspace / name).read_bytes() for name in files}
        status_before = set(changed_files(workspace))
        try:
            kind = TARGETS[item.package]["kind"]
            if kind in ("codex", "hermes", "stable-flake"):
                self.update_flake(workspace, item)
            elif kind == "npm":
                self.update_npm(workspace, item)
            else:
                self.update_download(workspace, item)
            unexpected = set(changed_files(workspace)) - status_before - set(files)
            if unexpected:
                raise UpdateError(f"Update touched unexpected files: {sorted(unexpected)}")
            for name in files:
                if name.endswith(".nix"):
                    run(["nix-instantiate", "--parse", workspace / name], cwd=workspace)
            run(["git", "diff", "--check", "--", *files], cwd=workspace)
            item.changedFiles = [name for name in files if (workspace / name).read_bytes() != before[name]]
            if not item.changedFiles:
                raise UpdateError("The selected update produced no file changes")
            item.status = "updated"
        except Exception as exc:
            for name, content in before.items():
                (workspace / name).write_bytes(content)
            item.status, item.error = "failed", str(exc)


def git(repo, *args):
    return run(["git", *args], cwd=repo)


def changed_files(repo):
    tracked = git(repo, "diff", "--name-only", "HEAD").splitlines()
    untracked = git(repo, "ls-files", "--others", "--exclude-standard").splitlines()
    return sorted(set(tracked + untracked))


def fingerprint(repo):
    digest = hashlib.sha256(git(repo, "diff", "--binary", "HEAD").encode())
    for name in sorted(git(repo, "ls-files", "--others", "--exclude-standard").splitlines()):
        digest.update(name.encode())
        path = Path(repo) / name
        digest.update(path.read_bytes() if path.is_file() else b"not-a-regular-file")
    return digest.hexdigest()


def summarize(items):
    counts = {}
    for item in items:
        counts[item["status"]] = counts.get(item["status"], 0) + 1
    return counts


def validate_workspace(workspace):
    try:
        derivation = run(["nix", "eval", *SAFE_NIX, "--no-write-lock-file", "--raw",
                          ".#nixosConfigurations.desktop.config.system.build.toplevel.drvPath"], cwd=workspace)
        return {"status": "passed", "derivation": derivation, "built": False, "activated": False}
    except Exception as exc:
        return {"status": "failed", "error": str(exc), "built": False, "activated": False}


def prepare_updates(updater, items, report):
    repo = updater.repo
    updates = [item for item in items if item.status == "available"]
    for item in updates:
        updater.apply(repo, item)
    report.update({"branch": git(repo, "branch", "--show-current"), "worktree": str(repo),
                   "results": [dataclasses.asdict(item) for item in items]})
    # Also validate repeat runs with no new releases, including after a failed evaluation.
    report["validation"] = validate_workspace(repo)
    report["summary"] = summarize(report["results"])
    return report


def execute(repo, mode="check", packages="all", http=None):
    names = list(TARGETS) if packages == "all" else list(dict.fromkeys(p.strip() for p in packages.split(",")))
    if not names or any(name not in TARGETS for name in names):
        raise UpdateError("Unknown package selection. Choose all or a comma-separated list of: " + ", ".join(TARGETS))
    names = [name for name in TARGETS if name in names]
    if mode not in ("check", "update"):
        raise UpdateError("Mode must be check or update")
    updater = Updater(repo, http)
    if Path(git(updater.repo, "rev-parse", "--show-toplevel")).resolve() != updater.repo:
        raise UpdateError("Repository path must be its Git root")
    if mode == "update":
        git_dir = Path(git(updater.repo, "rev-parse", "--absolute-git-dir"))
        with (git_dir / "nix-package-updates.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as exc:
                raise UpdateError("Another package update is already running") from exc
            base = git(updater.repo, "rev-parse", "HEAD")
            before = fingerprint(updater.repo)
            report = execute(updater.repo, "check", packages, http)
            if git(updater.repo, "rev-parse", "HEAD") != base or fingerprint(updater.repo) != before:
                raise UpdateError("Working tree changed while checking releases; rerun the update")
            report["mode"] = "update"
            items = [Candidate(**item) for item in report["results"]]
            return prepare_updates(updater, items, report)
    items = updater.check(names)
    report = {"mode": mode, "repository": str(updater.repo),
              "checkedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
              "results": [dataclasses.asdict(item) for item in items],
              "validation": {"status": "not-run", "reason": "check-only"},
              "built": False, "activated": False}
    report["summary"] = summarize(report["results"])
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--mode", choices=["check", "update"], default="check")
    parser.add_argument("--packages", default="all", help="all or comma-separated package IDs")
    args = parser.parse_args()
    try:
        report = execute(args.repo, args.mode, args.packages)
        print(json.dumps(report, indent=2))
        return 1 if report["summary"].get("failed") or report["validation"]["status"] == "failed" else 0
    except Exception as exc:
        print(json.dumps({"error": str(exc), "built": False, "activated": False}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
