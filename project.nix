haskell-nix:

haskell-nix.cabalProject' [
  ({ pkgs, lib, config, buildProject, ...}:
    let
      inherit (haskell-nix) haskellLib;

      inherit (pkgs) stdenv;
    in
      {
        src = haskell-nix.cleanSourceHaskell {
          name = "dross-src";
          src = ./.;
        };

        compiler-nix-name = "ghc948";

        shell = {
          name = "dross-shell";
          packages = ps: builtins.attrValues (haskellLib.selectProjectPackages ps);
        };

        modules = [
          {
            packages.bindings-GLFW.components.library.libs =
              pkgs.lib.mkForce (
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin  (with pkgs.darwin.apple_sdk.frameworks; [ AGL Cocoa OpenGL IOKit Kernel CoreVideo pkgs.darwin.CF ]) ++
                # pkgs.lib.optionals (!pkgs.stdenv.isDarwin) (with pkgs.xorg; [ libXext libXi libXrandr libXxf86vm libXcursor libXinerama pkgs.libGL ])
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs.xorg; [ libXext libXi libXrandr libXxf86vm libXcursor libXinerama pkgs.libGL libX11 ])
              );
            packages.GLFW-b.components.library.libs =
              pkgs.lib.mkForce (
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin  (with pkgs.darwin.apple_sdk.frameworks; [ AGL Cocoa OpenGL IOKit Kernel CoreVideo pkgs.darwin.CF ]) ++
                # pkgs.lib.optionals (!pkgs.stdenv.isDarwin) (with pkgs.xorg; [ libXext libXi libXrandr libXxf86vm libXcursor libXinerama pkgs.libGL ])
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs.xorg; [ libXext libXi libXrandr libXxf86vm libXcursor libXinerama pkgs.libGL libX11 ])
              );
          }
        ];
      }
  )
]
