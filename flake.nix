{
  description = "Dross";

  outputs = { self, nixpkgs, ... } @ inputs:
  {
    overlays = {
      default = final: prev: {
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

      haskell-nix = { pkgs, config, ... }: {
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
      };
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
