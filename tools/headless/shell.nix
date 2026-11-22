# Tools to run xcraft in a headless Wayland compositor (sway), drive it and
# record it -- used to make docs/gameplay.gif. No X server involved.
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    sway grim wtype imagemagick
    wayland wayland-scanner wlr-protocols pkg-config
  ];
}
