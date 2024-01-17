############################################################################
# Builds Haskell packages with Haskell.nix
############################################################################
haskell-cross: haskell-nix:

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
          haskell-cross.overlays.haskell-nix
        ];
      }
  )
]
