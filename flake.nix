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
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in
      (utils.lib.eachSystem supportedSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            inherit (haskellNix) config;
            overlays = [
              haskellNix.overlay
              self.overlays.default
            ];
          };

          project                   = import ./project.nix pkgs.haskell-nix;
          projectWindowsCross       = import ./project.nix pkgs.pkgsCross.mingwW64.haskell-nix;
          projectWindowsStaticCross = import ./project.nix pkgs.pkgsCross.mingwW64.pkgsStatic.haskell-nix;
          projectMuslCross          = import ./project.nix pkgs.pkgsCross.musl64.haskell-nix;
          projectDarwinIntelCross   = import ./project.nix pkgs.pkgsCross.x86_64-darwin.haskell-nix;
          projectDarwinARMCross     = import ./project.nix pkgs.pkgsCross.aarch64-darwin.haskell-nix;
        in {
          inherit nixpkgs project projectWindowsCross projectWindowsStaticCross projectMuslCross;

          legacyPackages = pkgs;

          packages = {
            linux = pkgs.mkLinuxPackage project.hsPkgs.dross.components.exes.dross "dross";
          };
        } // nixpkgs.lib.optionalAttrs (system == "aarch64-darwin") {
          # Only Mac can cross-compile for darwin.
          inherit projectDarwinIntelCross;
        } // nixpkgs.lib.optionalAttrs (system == "x86_64-darwin") {
          inherit projectDarwinARMCross;
        }
      )) // {
        overlays.default = final: prev: {
          # bindings-GLFW uses the "Gdi32" package in it's extra-libraries
          # clause for MinGW. haskell.nix expects that library to be called
          # "gdi32" (lowercase).
          # See
          # https://input-output-hk.github.io/haskell.nix/tutorials/pkg-map.html#mapping-non-haskell-dependencies-to-nixpkgs
          # for more information and other ways of doing this.
          Gdi32 = null;

          # The vulkan haskell package refers to the vulkan library on
          # Windows as "vulkan-1". It's true, the vulkan DLL produced by
          # vulkan-loader is "vulkan-1.dll", but nixpkgs can't use that
          # information, we need to direct it to vulkan-loader in order to
          # get the vulkan-1.dll.
          vulkan-1 = final.vulkan-loader;

          # Fix build of GLFW cross-compiled to Windows
          glfw = final.callPackage ./glfw.nix {
            inherit (final.darwin.apple_sdk.frameworks) Carbon Cocoa Kernel OpenGL;
          };

          # Fix build of vulkan-loader cross-compiled to Windows
          vulkan-loader = final.callPackage ./vulkan-loader.nix {
            inherit (final.darwin) moltenvk;
          };

          # Fix build of vulkan-validation-layers cross-compiled to Windows
          vulkan-validation-layers = final.callPackage ./vulkan-validation-layers.nix {};

          mkLinuxPackage = final.callPackage ./linux-package.nix {};
        };
      };
}
