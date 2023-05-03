{ pkgs, lib ? pkgs.lib }: { modules ? [], ... }@attrs: let
  inherit (pkgs) stdenvNoCC;
  inherit (lib) concatLines;
  configure = import ./configure.nix { inherit pkgs; };
  configuration = configure {
    modules = modules ++ [(removeAttrs attrs [ "pkgs" "lib" "modules" ])];
  };
  outputs = lib.collect lib.isString configuration.outputs;
in stdenvNoCC.mkDerivation {
  name = "darwix";
  preferLocalBuild = true;
  buildCommand = ''
    echo ${lib.strings.concatStringsSep "\n" outputs} > $out
  '';
}

