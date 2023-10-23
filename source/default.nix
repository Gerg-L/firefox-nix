{
  pkgs ? import <nixpkgs> { },
}:
{
  darkreader = pkgs.callPackage ./darkreader.nix { };
  ublock-origin = pkgs.callPackage ./ublock-origin.nix { };
}
