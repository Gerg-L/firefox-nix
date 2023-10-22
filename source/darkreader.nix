{
  buildNpmPackage,
  fetchFromGitHub,
  jq,
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
    deno
  ];

  npmBuildFlags = [
    "--"
    "--firefox"
  ];

  patchPhase = ''
    runHook prePatch
    sed -i 's/181a1b/${background}/g; s/e8e6e3/${foreground}/g' src/defaults.ts

    NEW_MANIFEST=$(jq '. + {"applications": { "gecko": { "id": env.extid }}}' "src/manifest-firefox.json")
    echo "$NEW_MANIFEST" > "src/manifest-firefox.json"

    runHook postPatch
  '';

  preBuild = ''
    npm run deno:bootstrap
  '';

  installPhase = ''
    runHook preInstall

    install -D build/release/darkreader-firefox.xpi "$out/$extid.xpi"

    runHook postInstall
  '';
}
