{ pkgs }:
let
  lib = pkgs.lib;
  cargoLockFile = ../nix/strata/Cargo.lock;
  # These tools run inside the read-only preview sandbox.
  previewTools = with pkgs; [
    ffmpeg
    ffmpegthumbnailer
    imagemagick
    libraw
    squashfsTools
  ];
in
pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "strata";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "lgse";
    repo = "strata";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dFNsFCnkeZs0VwmYRyu+6Jh8XxJzv+agUlP70Fdxa5Q=";
  };

  # Keep the lockfile local so evaluation never has to build a fetcher.
  # kstring 2.0.2 supports our Rust 1.95; upstream's 2.0.4 requires Rust 1.96.
  cargoLock.lockFile = cargoLockFile;

  # The source and vendor lockfiles must agree before the Cargo setup hook runs.
  postPatch = ''
    cp ${cargoLockFile} Cargo.lock
  '';

  nativeBuildInputs = with pkgs; [
    pkg-config
    glib
    wrapGAppsHook4
  ];

  buildInputs = with pkgs; [
    fontconfig
    gtk4
    gtksourceview5
    poppler
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
  ];

  # Upstream embeds these paths at compile time. Runtime variables alone cannot
  # fix the release binary's /usr sandbox on NixOS.
  STRATA_SANDBOX_ROOT = "/nix/store";
  STRATA_SANDBOX_PATH = lib.makeBinPath previewTools;
  STRATA_SANDBOX_PRLIMIT = "${lib.getBin pkgs.util-linux}/bin/prlimit";
  STRATA_SANDBOX_GDK_PIXBUF_MODULE_FILE = "${pkgs.gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
  STRATA_BUILD_COMMIT = "6662d8d4bd4cb3cdec3f10f918f3b4c92b18cdcc";
  STRATA_RELEASE_TAG = "v${finalAttrs.version}";
  STRATA_BUILD_KIND = "stable";

  # The upstream GTK tests require a desktop session.
  doCheck = false;

  postInstall = ''
    install -Dm444 data/io.github.lgse.Strata.desktop \
      $out/share/applications/io.github.lgse.Strata.desktop
    substituteInPlace $out/share/applications/io.github.lgse.Strata.desktop \
      --replace-fail 'Exec=strata %U' "Exec=$out/bin/strata %U"
    install -Dm444 data/icons/scalable/apps/io.github.lgse.Strata.svg \
      $out/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg

    # Keep FileManager1 activation opt-in, as upstream packages do.
    install -Dm444 data/io.github.lgse.Strata.FileManager1.service \
      $out/share/strata/io.github.lgse.Strata.FileManager1.service
    substituteInPlace $out/share/strata/io.github.lgse.Strata.FileManager1.service \
      --replace-fail 'Exec=/usr/bin/strata ' "Exec=$out/bin/strata "
    install -Dm444 LICENSE $out/share/licenses/strata/LICENSE
    install -Dm444 THIRD_PARTY_LICENSES.md $out/share/licenses/strata/THIRD_PARTY_LICENSES.md
    install -Dm444 data/licenses/UnRAR.txt $out/share/licenses/strata/UnRAR.txt
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --set GDK_BACKEND wayland
      --prefix PATH : ${lib.makeBinPath (previewTools ++ [ pkgs.xdg-utils ])}
    )
  '';

  meta = {
    description = "Keyboard-first GTK4 file manager with Miller columns and sandboxed previews";
    homepage = "https://stratafiles.io/";
    # The default rar feature bundles UnRAR's restricted extraction library.
    license = [ lib.licenses.mit lib.licenses.unfreeRedistributable ];
    mainProgram = "strata";
    platforms = lib.platforms.linux;
  };
})
