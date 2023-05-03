{ pkgs }: {
  configure = import ./configure.nix { inherit pkgs; };
  build = import ./build.nix { inherit pkgs; };
}