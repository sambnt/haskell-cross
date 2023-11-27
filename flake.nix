{
  description = "Dross";

  inputs = {
    nixpkgs.follows = "haskellNix/nixpkgs-2305";
    haskellNix = {
      url = "github:input-output-hk/haskell.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, haskellNix, ... } @ inputs:
    let
      # The platforms you can build from (buildPlatform).
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in
      utils.lib.eachSystem supportedSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            inherit (haskellNix) config;
            overlays = [ haskellNix.overlay ];
          };

          inherit (pkgs) lib stdenv;

          project                 = import ./project.nix pkgs.haskell-nix;
          projectWindowsCross     = import ./project.nix pkgs.pkgsCross.mingwW64.haskell-nix;
          projectMuslCross        = import ./project.nix pkgs.pkgsCross.musl64.haskell-nix;
          projectDarwinIntelCross = import ./project.nix pkgs.pkgsCross.x86_64-darwin.haskell-nix;
          projectDarwinARMCross   = import ./project.nix pkgs.pkgsCross.aarch64-darwin.haskell-nix;
        in
        {
          inherit pkgs project projectWindowsCross projectMuslCross;
        } // lib.optionalAttrs stdenv.buildPlatform.isDarwin {
          # Only Mac can cross-compile for darwin.
          inherit projectDarwinIntelCross projectDarwinARMCross;
        }
      );
}
