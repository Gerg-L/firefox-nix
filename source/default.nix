{
  pkgs ? import <nixpkgs> { },
}:
{
  darkreader = pkgs.callPackage ./darkreader.nix { };
}
