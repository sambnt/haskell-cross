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
            # packages.dross.components.exes.dross.libs = [ pkgs.vulkan-validation-layers ];
          }
          {
            packages.dross.components.exes.dross.configureFlags =
              lib.optionals stdenv.hostPlatform.isMusl [
                "--disable-executable-dynamic"
                "--disable-shared"
                "--ghc-option=-optl=-pthread"
                "--ghc-option=-optl=-static"
                "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib"
                "--ghc-option=-optl=-L${pkgs.pkgsStatic.zlib}/lib"
              ];
            # packages.bindings-GLFW.components.library.ghcOptions = [ "-fasdlfjsd" ];
          }
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
            # packages.dross.components.exes.dross.release = true;
            # packages.dross.hsPkgs.bindings-GLFW.patches = [ ./lowercase-gdi32.patch ];
            # packages.bindings-GLFW.patches = [ ./lowercase-gdi32.patch ];
            # packages.bindings-GLFW.postUnpack = "echo 'hi'";
            # packages.dross.modules = [ {
            #   packages.bindings-GLFW.patches = [ ./lowercase-gdi32.patch ];
            # } ];
            # packages.bindings-GLFW.rhcOptions = ["-Werror"];
          }
        ];
      }
  )
]
