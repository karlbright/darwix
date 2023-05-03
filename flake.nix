{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/22.11";

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs { system = "aarch64-darwin"; };
  in rec {
    lib = darwix;
    
    darwix = import ./. { inherit pkgs; };

    examples = let
      darwix = self.outputs.darwix;
      module = { defaults.screenshots.format = "psd"; };
    in {
      configure = darwix.configure module;
      build = darwix.build module;
    };
  };
}
