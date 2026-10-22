{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "michelangelus";
  version = "1.10";

  src = pkgs.fetchurl {
    url = "https://download.microsoft.com/download/e8912dd7-c7e6-4ca1-a36b-c121d3fb238f/Michelangelus%20Fonts.zip";
    hash = "sha256-7vJbfPAMJPY6Wa6hWWcZaOdJCyM8WNwAws3P26BJ3IQ=";
  };

  nativeBuildInputs = [ pkgs.unzip ];
  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 Michelangelus-*.ttf -t "$out/share/fonts/truetype/michelangelus"
    install -Dm444 "Michelangelus Fonts EULA.rtf" \
      "$out/share/licenses/michelangelus/EULA.rtf"
    runHook postInstall
  '';

  meta = {
    description = "Michelangelus serif typeface in four styles by Studiogusto";
    homepage = "https://michelangelus.studiogusto.com/";
    license = pkgs.lib.licenses.unfree;
    platforms = pkgs.lib.platforms.all;
  };
}
