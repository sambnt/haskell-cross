{
  description = "Dross";

  inputs = {
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
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
            overlays = [
              haskellNix.overlay
              # bindings-GLFW uses the "Gdi32" package in it's extra-libraries
              # clause for MinGW. haskell.nix expects that library to be called
              # "gdi32" (lowercase).
              # See
              # https://input-output-hk.github.io/haskell.nix/tutorials/pkg-map.html#mapping-non-haskell-dependencies-to-nixpkgs
              # for more information and other ways of doing this.
              (self: super: { Gdi32 = null; })
              # Fix build of GLFW on Windows
              (self: super: {
                glfw = self.callPackage ./glfw.nix {
                  inherit (self.darwin.apple_sdk.frameworks) Carbon Cocoa Kernel OpenGL;
                };
              })
            ];
          };

          inherit (pkgs) lib stdenv;

          project                 = import ./project.nix pkgs.haskell-nix;
          projectWindowsCross     = import ./project.nix pkgs.pkgsCross.mingwW64.haskell-nix;
          projectMuslCross        = import ./project.nix pkgs.pkgsCross.musl64.haskell-nix;
          projectDarwinIntelCross = import ./project.nix pkgs.pkgsCross.x86_64-darwin.haskell-nix;
          projectDarwinARMCross   = import ./project.nix pkgs.pkgsCross.aarch64-darwin.haskell-nix;
        in
        {
          inherit haskellNix pkgs project projectWindowsCross projectMuslCross;
        } // lib.optionalAttrs stdenv.buildPlatform.isDarwin {
          # Only Mac can cross-compile for darwin.
          inherit projectDarwinIntelCross projectDarwinARMCross;
        }
      );
}
