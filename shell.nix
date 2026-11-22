{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "xcraft-sdl";
  packages = with pkgs; [
    gnumake
    pkg-config
    SDL2
  ];
}
