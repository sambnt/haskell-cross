############################################################################
# Builds Haskell packages with Haskell.nix
############################################################################
haskell-nix:

# This creates the Haskell package set.
haskell-nix.cabalProject' [
  ({ pkgs, lib, config, buildProject, ...}:
    let
      inherit (haskell-nix) haskellLib;

      inherit (pkgs) stdenv;

      src = haskell-nix.cleanSourceHaskell {
        name = "foobar-src";
        src = ./.;
      };

      # Must match "with-compiler" in cabal.project, with "-"s (dashes) and "." (periods) removed.
      compiler-nix-name = "ghc948";

      isCrossBuild = stdenv.hostPlatform != stdenv.buildPlatform;
    in
      {
        inherit src compiler-nix-name;

        shell = {
          name = "foobar-shell";
          packages = ps: builtins.attrValues (haskellLib.selectProjectPackages ps);

          nativeBuildInputs = with pkgs.buildPackages.buildPackages; [
            haskellPackages.ghcid
            nixWrapped
            cabalWrapped
            haskell-nix.cabal-install.${config.compiler-nix-name}
          ];
        };

        modules = [
          ({ pkgs, config, ... }: {
            # If you're not using GLFW, feel free to remove these.
            packages.bindings-GLFW.components.library.libs =
              pkgs.lib.mkForce (
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin  (with pkgs.darwin.apple_sdk.frameworks; [ AGL Cocoa OpenGL IOKit Kernel CoreVideo pkgs.darwin.CF ]) ++
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs.xorg; [ libXext libXi libXrandr libXxf86vm libXcursor libXinerama pkgs.libGL libX11 ])
              );
            packages.GLFW-b.components.library.libs =
              pkgs.lib.mkForce (
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin  (with pkgs.darwin.apple_sdk.frameworks; [ AGL Cocoa OpenGL IOKit Kernel CoreVideo pkgs.darwin.CF ]) ++
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs.xorg; [ libXext libXi libXrandr libXxf86vm libXcursor libXinerama pkgs.libGL libX11 ])
              );
          })
        ];
      }
  )
]
