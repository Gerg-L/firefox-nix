{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      #
      # Funni helper function
      #
      withSystem =
        f:
        lib.fold lib.recursiveUpdate { } (
          map f [
            "x86_64-linux"
            "x86_64-darwin"
            "aarch64-linux"
            "aarch64-darwin"
          ]
        );
    in
    withSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        lib = import ./lib nixpkgs.lib;

        formatter.${system} = pkgs.writeShellApplication {
          name = "lint";
          runtimeInputs = [
            pkgs.nixfmt
            pkgs.deadnix
            pkgs.statix
            pkgs.fd
          ];
          text = ''
            fd '.*\.nix' . -x statix fix -- {} \;
            fd '.*\.nix' . -X deadnix -e -- {} \; -X nixfmt {} \;
          '';
        };

        devShells.${system}.default = pkgs.mkShell { packages = [ pkgs.npins ]; };

        legacyPackages.${system} =
          let
            builder =
              nativeBuildInputs: buildCommand:
              lib.mapAttrs
                (
                  n: v:
                  pkgs.stdenvNoCC.mkDerivation {
                    pname = n;
                    inherit (v) version extid;
                    src = pkgs.fetchurl { inherit (v) url hash; };
                    meta = v.meta // {
                      platforms = lib.platforms.all;

                      license =
                        if !builtins.isAttrs v.meta.license then
                          builtins.getAttr (toString v.meta.license) {
                            "6" = lib.licenses.gpl3;
                            "12" = lib.licenses.lgpl3;
                            "13" = lib.licenses.gpl2;
                            "16" = lib.licenses.lgpl21;
                            "18" = lib.licenses.bsd2;
                            "22" = lib.licenses.mit;
                            "3338" = lib.licenses.mpl20;
                            "4160" = lib.licenses.asl20;
                            "4814" = lib.licenses.cc0;
                            "5296" = lib.licenses.bsd3;
                            "6978" = lib.licenses.cc-by-sa-30;
                            "6979" = lib.licenses.cc-by-30;
                            "6982" = lib.licenses.cc-by-nc-sa-30;
                            "7551" = lib.licenses.isc;
                            "7068" = lib.licenses.zlib;
                            "7770" = lib.licenses.agpl3;
                          }
                        else
                          v.meta.license;
                    };

                    inherit buildCommand nativeBuildInputs;
                  }
                )
                (lib.importJSON ./generated.json);
          in
          {
            fetch = pkgs.writeShellApplication {
              name = "fetchPlugins";
              runtimeInputs = [
                pkgs.curl
                pkgs.gnused
                pkgs.jq
              ];
              text = ./fetch.sh;
            };

            source = import ./source { inherit pkgs; };

            binary =
              builder
                [
                  pkgs.jq
                  pkgs.strip-nondeterminism
                  pkgs.unzip
                  pkgs.zip
                ]
                ''
                  mkdir -p "$out/$extid"
                  unzip -q "$src" -d "$out/$extid"
                  NEW_MANIFEST=$(jq '. + {"applications": { "gecko": { "id": env.extid }}, "browser_specific_settings":{"gecko":{"id": env.extid }}}' "$out/$extid/manifest.json")
                  echo "$NEW_MANIFEST" > "$out/$extid/manifest.json"
                  cd "$out/$extid"
                  zip -r -q -FS "$out/$extid.xpi" *
                  strip-nondeterminism "$out/$extid.xpi"
                  rm -r "$out/$extid"
                '';

            HMbinary = builder [ ] ''
              install -D "$src" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/$extid.xpi"
            '';
          };
      }
    );
}
