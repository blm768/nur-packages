{ pkgs, ... }:

{
  modules = import ./modules;

  display-switch = pkgs.callPackage ./pkgs/display-switch {};
}
