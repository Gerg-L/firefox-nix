(import
  (
    let
      source = (import ./npins).flake-compat;
    in
    fetchTarball {
      inherit (source) url;
      sha256 = source.hash;
    }
  )
  { src = ./.; }
).defaultNix
