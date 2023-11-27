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
            packages.dross.components.exes.dross.configureFlags =
              lib.optionals stdenv.hostPlatform.isMusl [
                "--disable-executable-dynamic"
                "--disable-shared"
                "--ghc-option=-optl=-pthread"
                "--ghc-option=-optl=-static"
                "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib"
                "--ghc-option=-optl=-L${pkgs.pkgsStatic.zlib}/lib"
              ];
          }
        ];
      }
  )
]
