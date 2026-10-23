# Security disclosure research — 22 October 2026

Research window: **15–22 October 2026**, using the user's Africa/Johannesburg date. Older vulnerabilities are included where they match the installed workstation or were recently exploited. This is a defensive, read-only assessment; no exploit was run, and no system configuration, packages, or services were changed.

Machine-specific evidence and remediation priorities are recorded separately in [the machine audit](security-machine-audit-2026-10-22.md). Version comparisons below use inventory supplied by the local audit. They identify affected upstream versions, not proof that an attacker has successfully exploited this machine. Distribution patches, runtime reachability, and application configuration matter.

## What the recent surge actually contains

There is substantial new disclosure activity, but a security fix, public proof of concept, and observed criminal exploitation are different evidence categories. Google's October 20 desktop release reports **353 security fixes**, while its October 15 release reports **10**. These counts are fixes, not a claim that 363 independent working exploits were released or that every fix affects Chrome 149. Google often restricts technical details while users update. Sources: [October 20 Chrome release](https://chromereleases.googleblog.com/2026/10/stable-channel-update-for-desktop_02018666648.html), [October 15 Chrome release](https://chromereleases.googleblog.com/2026/10/stable-channel-update-for-desktop_01886704284.html).

The CISA-owned KEV JSON retrieved during this review was **catalogVersion 2026.10.21**, released **2026-10-21T14:04:39.8983Z**, containing **1,754** entries. Filtering `dateAdded` inclusively from October 15 through 22 returned **9** entries. This is a complete list of additions in that retrieved snapshot, not a complete list of vulnerabilities or attacks worldwide. The CISA website returned HTTP 403; the CISA-owned repository supplied the data. [CISA KEV source](https://raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json).

| KEV added | CVE | Product | Attack category |
| --- | --- | --- | --- |
| October 15 | CVE-2026-21589 | Atlassian server products | Unauthenticated access to application files |
| October 16 | CVE-2026-102764 | BeyondTrust Remote Support | Authentication bypass; appliance file operations |
| October 16 | CVE-2025-61624 | Fortinet products | Administrative path traversal |
| October 20 | CVE-2026-106931 | EG Secure Solutions SiteGuard Server Edition | OS command injection |
| October 20 | CVE-2026-96652 | Plex Media Server | SSRF |
| October 20 | CVE-2026-96654 | Plex Media Server | Internal-function access |
| October 20 | CVE-2026-96655 | Plex Media Server | SSRF/token-exposure chain |
| October 20 | CVE-2026-96656 | Plex Media Server | Arbitrary file write |
| October 20 | CVE-2026-110936 | Siemens Software Center | Local DLL search-path abuse |

The [Plex vendor advisory](https://forums.plex.tv/t/important-security-update-for-plex-media-server-v1-43-2-and-earlier/942319) distinguishes its September 1 patch announcement from the October 16 public proof of concept and October 19 confirmation of widespread attacks. The four vulnerabilities can chain into unauthenticated server-process code execution; **1.43.3.10861 and later** are unaffected. Other KEV entries should be assessed against their product-specific vendor instructions: [Atlassian](https://confluence.atlassian.com/security/cve-2026-21589-arbitrary-file-access-vulnerability-impacts-multiple-products-1870495748.html), [BeyondTrust](https://www.beyondtrust.com/trust-center/security-advisories/bt26-05), [Fortinet](https://fortiguard.fortinet.com/psirt/FG-IR-26-122), [SiteGuard](https://www.eg-secure.co.jp/siteguard/news/alert-202610-1), [Siemens](https://productcert.siemens.com/productcert/html/ssa-580366.html). Those vendor links are the KEV remediation references; their complete version matrices were not independently audited here.

## Findings relevant to this workstation

### Linux kernel: newly disclosed issue and older confirmed exploitation

The booted kernel reported by the audit is **6.18.35**. The Linux CNA records specify these first fixed versions in the same branch:

| CVE | Disclosure / exploitation evidence | First fixed 6.18 version | Conditions and conclusion |
| --- | --- | --- | --- |
| **CVE-2026-99999 — PwnEscape** | CNA published October 15; researcher demonstrated memory disclosure and laboratory host execution | **6.18.57** | Malformed checksum metadata reaches host IPv4 processing from local/guest virtual networking. 6.18.35 is in the affected range. This is not evidence of arbitrary unauthenticated Internet-packet RCE. |
| **CVE-2026-53362 — IPv6 fragmentation** | CNA published July 4; CISA KEV added August 27 | **6.18.38** | CNA explicitly describes an unprivileged UDPv6 path. 6.18.35 is in the affected range; IPv6 availability/reachability matters. |
| **CVE-2026-53266 — ebtables ARP rewrite** | CNA published June 25; CISA KEV added September 18 | **6.18.36** | A particular bridge ebtables SNAT ARP rewrite can write into a splice-backed page. 6.18.35 is in the affected range; bridge/netfilter configuration and ability to establish the path matter. |
| **CVE-2026-74580 — Vghost** | CNA published August 21; public exploit publicity occurred October 14, outside the strict week | **6.18.45** | vhost vring reconfiguration with an attached device IOTLB. Affected version, with exposure dependent on vhost access/use. |

Primary affected-version records: [PwnEscape Linux CNA](https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/2026/99xxx/CVE-2026-99999.json), [IPv6 Linux CNA](https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/2026/53xxx/CVE-2026-53362.json), [ebtables Linux CNA](https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/2026/53xxx/CVE-2026-53266.json), [vhost Linux CNA](https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/2026/74xxx/CVE-2026-74580.json). Exploitation classification comes from the [CISA catalog](https://raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json), not the version match.

The [6.18.57 changelog](https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.18.57) contains the PwnEscape backport `f3e835af6226f1dd12160cbd696081e9b6155de0`, derived from upstream `6785011f8b16abf40b1e9d8b2e332232b3e68822`. It identifies both TUN and packet-socket checksum-offload paths; it also says further ingress validation is forthcoming. [Kernel.org](https://www.kernel.org/) lists **6.18.58**, released October 21, as the latest 6.18 release observed here. That is a more appropriate update target than stopping exactly at the first fix.

The [researcher's report](https://pwn.ai/blog/pwnescape) carefully separates host-memory disclosure demonstrated against the provider from full host execution demonstrated on owned laboratory systems. [Red Hat's assessment](https://access.redhat.com/security/cve/cve-2026-99999) identifies a local attacker or untrusted guest VM as the entry point. Checking `CONFIG_INET`, `CONFIG_PACKET`, `CONFIG_TUN`, virtual networking, network capabilities, and user namespaces is useful reachability triage, but their presence alone does not establish a successful exploit chain. No PwnEscape KEV entry was present in the retrieved snapshot.

Two other recently catalogued Linux issues, **CVE-2025-39964** and **CVE-2025-39682**, were fixed in mainline **6.17**. Therefore kernel 6.18.35 is beyond their upstream fixes; do not report them as vulnerable merely because CISA added them in September. [AF_ALG CNA record](https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/2025/39xxx/CVE-2025-39964.json), [TLS CNA record](https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/2025/39xxx/CVE-2025-39682.json).

### Nix: strong local privilege-escalation match

**Nix 2.34.7** is below the **2.34.9** fix for **CVE-2026-110450**, disclosed October 13. An untrusted but allowed daemon client can replace store contents through repair operations; a root daemon or another privileged service consuming them provides a root escalation route. This is highly relevant to the audit's root daemon and `allowed-users = *`. `sandbox = true` is not the fix for the daemon protocol flaw. [Nix maintainer advisory](https://github.com/NixOS/nix/security/advisories/GHSA-jwvx-xq5j-gc56).

The same coordinated release fixes **CVE-2026-110449**, an evaluator list-size overflow. Its advisory says default GCC 15 builds distributed by nixpkgs do not exhibit the described out-of-bounds write optimization, although out-of-bounds reads remain possible; maintainers did not know an exploitation method. Do not equate this with confirmed evaluator RCE on this host. [Evaluator advisory](https://github.com/NixOS/nix/security/advisories/GHSA-25vp-6h23-hj3g). Other issues in the coordinated release concern macOS or scripted installers and should not automatically be attributed to NixOS. [Coordinated Nix/Lix advisory](https://discourse.nixos.org/t/security-advisory-for-nix-and-lix-october-2026/80547).

### Certificate authority compromise: system and embedded trust stores

Mozilla learned on **October 17** that eight eMudhra intermediate private keys were compromised. Such keys permit fraudulent certificates; exploitation against a client also requires a suitable interception/impersonation path. Mozilla distributed its OneCRL block that day to normally configured Firefox clients without requiring restart. On **October 20**, **NSS 3.131.1** removed the signing root to protect other trust-store consumers, and Firefox **158.0.1**, ESR **153.5.1/115.43.1** incorporated protection for clients that could not receive the dynamic block. [Mozilla incident response](https://blog.mozilla.org/security/2026/10/20/protecting-firefox-users-following-the-compromise-of-emudhra-intermediate-certificates/).

The audit's **nss-cacert 3.123**, NSS **3.125/3.112.5**, and still-present emSign roots are strong evidence of old trust material. System OpenSSL users, statically bundled roots, and application-specific stores require separate consideration. Firefox's version alone does not prove it lacks OneCRL protection. Firefox tracks the bundled block update as **CVE-2026-113470**; **CVE-2026-111943** is an ecosystem tracking identifier associated with Go, not a universal OpenSSL code defect. [Firefox advisory](https://www.mozilla.org/en-US/security/advisories/mfsa2026-111/), [Red Hat ecosystem explanation](https://access.redhat.com/security/vulnerabilities/RHSB-2026-012).

### Browsers and embedded web engines

| Installed inventory | Verified security release / concern | Confidence and limitation |
| --- | --- | --- |
| Chrome/Chromium **149.0.7827.114** | October 15: **155.0.8059.84**; October 20: **156.0.8078.47** on Linux | Substantial missing security updates. October 15 includes critical **CVE-2026-110922**; October 20 includes critical **CVE-2026-113341**, **113279**, **113072**, **113280**, **113271**, **113303**. Individual feature introduction/backports still matter. |
| Firefox **152.0** | **158.0.1**, October 20 | Update includes **CVE-2026-113399** SVG boundary issue, **113400** audio uninitialized memory, **113401** PDF DoS, and certificate block update. Earlier October 13 Firefox 158 also fixes networking sandbox issues, including **CVE-2026-109705/109707/109708**. |
| WebKitGTK **2.52.4** | July 10 fixes in **2.52.5**, further August/September fixes; observed stable **2.54.1** | Older current risk, not a new last-week disclosure. **CVE-2026-43701** concerns processing restricted content outside the sandbox; **CVE-2026-43705** concerns memory corruption. |
| Electron **40.10.3 / 41.7.2** and QtWebEngine **6.11.0** | Bundled engines require application updates | Do not substitute the system Chrome version for the Chromium embedded in each application, or assume a new major release by itself proves all embedded dependencies fixed. Exact backport coverage was not audited here. |

Sources: [Chrome October 15](https://chromereleases.googleblog.com/2026/10/stable-channel-update-for-desktop_01886704284.html), [Chrome October 20](https://chromereleases.googleblog.com/2026/10/stable-channel-update-for-desktop_02018666648.html), [Firefox October 20](https://www.mozilla.org/en-US/security/advisories/mfsa2026-111/), [Firefox October 13](https://www.mozilla.org/en-US/security/advisories/mfsa2026-106/), [WebKit July advisory](https://webkitgtk.org/security/WSA-2026-0004.html), [WebKit August advisory](https://webkitgtk.org/security/WSA-2026-0005.html), [WebKit September advisory](https://webkitgtk.org/security/WSA-2026-0006.html), [Electron release mapping](https://releases.electronjs.org/releases/stable), [Qt's separate WebEngine release policy](https://www.qt.io/blog/qt-webengine-will-release-separate).

### X11 compatibility libraries remain relevant under Wayland

The October 16 X.Org advisory contains **17 CVEs** across five libraries. Every corresponding version in the local inventory precedes its fix:

| Library | Installed | Fixed | CVEs |
| --- | --- | --- | --- |
| libX11 | 1.8.13 | **1.8.14** | CVE-2026-88806, 94283, 94284, 94285 |
| libXi | 1.8.2 | **1.8.4** | CVE-2026-93541 through 93545; 94281, 94282; 109089, 109090 |
| libXpm | 3.5.19 | **3.5.20** | CVE-2026-94287 |
| libXrender | 0.9.12 | **0.9.13** | CVE-2026-88807 |
| libXtst | 1.2.5 | **1.2.6** | CVE-2026-94286, 109088 |

Most require crafted replies from an X/XIM server; others involve particular library input. Being installed does not mean all have a reachable attacker-controlled input. [X.Org October 16 advisory](https://lists.x.org/archives/xorg-announce/2026-October/003752.html), [official security index](https://www.x.org/Development/Security/).

The separately running **Xwayland 24.1.12** predates **24.1.14**, released for the October 7 advisory. For example, **CVE-2026-88812** permits an authenticated X client to trigger a double-free, potentially causing code execution or a crash. This is relevant even when the desktop compositor itself uses Wayland. [X.Org October 7 advisory](https://lists.x.org/archives/xorg-announce/2026-October/003747.html).

### Other directly relevant release notices

- **Node.js, October 21:** the vendor fixes high-severity **CVE-2026-111497** (Brotli decoder out-of-bounds write/RCE), **CVE-2026-105482**, **105483**, and **106069**, plus medium- and low-severity issues, in **22.23.4 / 24.22.1 / 26.12.1**. The locally identified 22.22.3, 24.15.0, 26.3.0 and bundled 24.19.0/24.21.0 precede these releases. Application use of vulnerable APIs determines reachability. [Node security release](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases).
- **Qt, October 20:** **CVE-2026-101201** affects Qt 5.0–6.8.8 and 6.9.0–6.11.2. Crafted JSON can trigger an out-of-bounds read and crash; fixed in **6.8.9 / 6.11.3 or later**. Relevant to installed Qt 6.11.0 components when they expose the affected parsing API, rather than a demonstrated host takeover. [Qt advisory](https://www.qt.io/blog/security-advisory-cve-2026-101201).
- **NVIDIA, September 30:** **CVE-2026-47604** affects Linux R595 versions before **595.91.07**, matching installed **595.80**. Missing authorization allows a local user to access another process's GPU channel state, potentially disclosing information. This specific finding should not be expanded to every CVE in NVIDIA's large bulletin without matching the product/platform. [NVIDIA bulletin](https://raw.githubusercontent.com/NVIDIA/product-security/main/2026/5861/5861.md), [NVIDIA CVE data](https://raw.githubusercontent.com/NVIDIA/product-security/main/2026/5861/CVE-2026-47604.json).
- **PHP2Shell, October 20–21:** **CVE-2026-109618/109619** concern request-processing memory corruption. mod_php deployments are at higher practical risk than typical PHP-FPM; untrusted HTTP processing is required. The parent audit reported no PHP in the active system closure, so there is no local package match from that evidence. Arbitrary container/VM contents require separate inspection. [Vendor assessment](https://access.redhat.com/security/vulnerabilities/RHSB-2026-013), [PHP advisory 109618](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w), [PHP advisory 109619](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp).

## Coverage and interpretation limits

This report covers the complete recent KEV additions in the retrieved CISA snapshot plus focused primary-source investigation of the machine's kernel, Nix, certificate stores, browsers, web engines, X11 libraries, Node, Qt, GPU driver, and prominent PHP disclosure. It does not claim an exhaustive enumeration of every CVE, proof of concept, extension, dependency, firmware issue, container layer, or remotely managed service. Additional OpenSSL/curl/SSH/container analysis belongs in the companion machine audit.

Sources were current through October 22 where vendors had published updates; the available KEV snapshot stopped at October 21. A vulnerability's publication date can differ from its first fixed release, public exploit release, or KEV addition. That distinction explains why an older vulnerable system can be at greater immediate risk from previously disclosed, actively exploited bugs than from the newest headline.

No exploitation, compromise, or absence of compromise was established. A clean vulnerability inventory would not establish absence of intrusion either. For NixOS, patching the source checkout without building and activating a fixed generation does not change the running kernel, daemon, trust stores, or existing application processes; any later implementation should explicitly verify the active generation and restarted applications.
