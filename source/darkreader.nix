{
  buildNpmPackage,
  fetchFromGitHub,
  jq,
  strip-nondeterminism,
  unzip,
  zip,
  deno,
  background ? "1e1e2e",
  foreground ? "cdd6f4",
}:

let
  version = "4.9.67";
in
buildNpmPackage {

  pname = "darkreader";
  inherit version;
  extid = "addon@darkreader.org";

  src = fetchFromGitHub {
    owner = "darkreader";
    repo = "darkreader";
    rev = "v${version}";
    hash = "sha256-lz7wkUo4OB/Gu/q45RVpj9Vmk4u65D0opvjgOeEjjpw=";
  };

  npmDepsHash = "sha256-DgijQj3p4yiAUlwUC1cXkF8afHdm2ZOd/PNXVt6WZW8=";

  nativeBuildInputs = [
    jq
    strip-nondeterminism
    unzip
    zip
    deno
  ];

  patchPhase = ''
    runHook prePatch
    sed -i 's/181a1b/${background}/g; s/e8e6e3/${foreground}/g' src/defaults.ts
    runHook postPatch
  '';

  npmBuildFlags = [
    "--"
    "--firefox"
  ];

  preBuild = ''
    npm run deno:bootstrap
  '';

  installPhase = ''
    runHook preInstall

    UUID="$extid"
    mkdir -p "$out/$UUID"
    unzip -q "build/release/darkreader-firefox.xpi" -d "$out/$UUID"
    NEW_MANIFEST=$(jq '. + {"applications": { "gecko": { "id": env.extid }}, "browser_specific_settings":{"gecko":{"id": env.extid }}}' "$out/$UUID/manifest.json")
    echo "$NEW_MANIFEST" > "$out/$UUID/manifest.json"
    cd "$out/$UUID"
    zip -r -q -FS "$out/$UUID.xpi" *
    strip-nondeterminism "$out/$UUID.xpi"
    rm -r "$out/$UUID"

    runHook postInstall
  '';
}
