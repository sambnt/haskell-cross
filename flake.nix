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
              (self: super: {
                # bindings-GLFW uses the "Gdi32" package in it's extra-libraries
                # clause for MinGW. haskell.nix expects that library to be called
                # "gdi32" (lowercase).
                # See
                # https://input-output-hk.github.io/haskell.nix/tutorials/pkg-map.html#mapping-non-haskell-dependencies-to-nixpkgs
                # for more information and other ways of doing this.
                Gdi32 = null;
                # The vulkan haskell package refers to the vulkan library on
                # windows as "vulkan-1". It's true, the vulkan DLL produced by
                # vulkan-loader is "vulkan-1.dll", but nixpkgs can't use that
                # information, we need to direct it to vulkan-loader in order to
                # get the vulkan-1.dll.
                vulkan-1 = self.vulkan-loader;
              })
              (self: super: {
                # Fix build of GLFW cross-compiled to Windows
                glfw = self.callPackage ./glfw.nix {
                  inherit (self.darwin.apple_sdk.frameworks) Carbon Cocoa Kernel OpenGL;
                };
                # Fix build of vulkan-loader cross-compiled to Windows
                vulkan-loader = self.callPackage ./vulkan-loader.nix {
                  inherit (self.darwin) moltenvk;
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
          # Don't do this, we're missing patches from haskell.nix if we go raw nixpkgs route.
          # x = pkgs.pkgsCross.mingwW64.haskellPackages.bindings-GLFW.overrideAttrs (old: { buildInputs = []; librarySystemDepends = []; });
        } // lib.optionalAttrs stdenv.buildPlatform.isDarwin {
          # Only Mac can cross-compile for darwin.
          inherit projectDarwinIntelCross projectDarwinARMCross;
        }
      );
}
