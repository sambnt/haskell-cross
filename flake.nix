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
          Gdi32 = final.gdi32;

          # The vulkan haskell package refers to the vulkan library on Windows
          # as "vulkan-1". But in Nixpkgs, that DLL is found in "vulkan-loader".
          # Therefore map vulkan-1 to vulkan-loader.
          vulkan-1 = final.vulkan-loader;

          # Fix build of GLFW cross-compiled to Windows
          glfw = final.callPackage ./glfw.nix {
            inherit (final.darwin.apple_sdk.frameworks) Carbon Cocoa Kernel OpenGL;
          };

          # Fix build of vulkan-loader cross-compiled to Windows
          vulkan-loader = prev.vulkan-loader.overrideAttrs (finalAttrs: prevAttrs: {
            buildInputs = [ final.vulkan-headers ]
                          ++ final.lib.optionals (final.stdenv.isLinux) [ final.xorg.libX11 final.xorg.libxcb final.xorg.libXrandr final.wayland ];
            cmakeFlags = prevAttrs.cmakeFlags
              ++ final.lib.optional ((final.stdenv.buildPlatform != final.stdenv.hostPlatform) && final.stdenv.hostPlatform.isWindows) "-DUSE_MASM=OFF";
          });

          # Fix build of vulkan-validation-layers cross-compiled to Windows
          vulkan-validation-layers = final.callPackage ./vulkan-validation-layers.nix {};

          mkLinuxPackage = final.callPackage ./linux-package.nix {};
          zipDerivation = final.callPackage ./zip-derivation.nix {};
        };

        templates = {
          cross = {
            path = ./template;
            description = "An haskell.nix template for cross-compiled Haskell.";
          };
        };

        defaultTemplate = self.templates.cross;
      };
}
