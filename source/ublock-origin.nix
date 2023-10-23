{
  buildNpmPackage,
  fetchFromGitHub,
  python3,
  jq,
  zip,
}:

buildNpmPackage {

  pname = "ublock-origin";
  version = "unstable";

  extid = "uBlock0@raymondhill.net";

  src = fetchFromGitHub {
    owner = "gorhill";
    repo = "uBlock";
    rev = "3c04ae41b3a5efe46e7f91a6dd23982b15e8c554";
    hash = "sha256-3aaWEPVLR/4rVfQ27zIQsjACEbTHZo8aJr70YqQtUK8=";
  };

  assets = fetchFromGitHub {
    owner = "uBlockOrigin";
    repo = "uAssets";
    rev = "5e07673b1d08b745854983be78af087d2bbc5061";
    hash = "sha256-BbAn4MXDNCSpcAn8VhAhh1GmfFtSNJdxNI2J0gJUCjU=";
  };

  prod = fetchFromGitHub {
    owner = "uBlockOrigin";
    repo = "uAssets";
    rev = "7a77e93804f7d8036629440b9db50c7efd5e89f2";
    hash = "sha256-rwfHNWr2SfCiDSOCnJtewYAS4HyTOZuctZ3ykj0RaQc=";
  };

  npmDepsHash = "sha256-z+rsgfz3+JOQjRu6ujudFKD9kV4K7GAXzUPeuX8LuoY=";

  nativeBuildInputs = [
    python3
    zip
    jq
  ];

  makeCacheWritable = true;

  postPatch = ''
    ln -s platform/npm/package-lock.json package-lock.json
  '';

  buildPhase = ''
     runHook preBuild

     patchShebangs tools/make-firefox.sh

     mkdir -p dist/build/uAssets
     ln -s "$prod" dist/build/uAssets/prod
     ln -s "$assets" dist/build/uAssets/main


    NEW_MANIFEST=$(jq '. + {"applications": { "gecko": { "id": env.extid }}}' "platform/firefox/manifest.json")
    echo "$NEW_MANIFEST" > "platform/firefox/manifest.json"

    echo "#!/bin/sh -c true" > tools/pull-assets.sh

    make firefox

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D dist/build/uBlock0.firefox.xpi "$out/$extid.xpi"

    runHook postInstall
  '';
}
