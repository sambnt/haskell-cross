# Haskell Cross-Compilation Example

Compile the project (native):

```
nix build .#project.x86_64-linux.hsPkgs.dross.components.exes.dross
./result/bin/dross
```

Cross-compile for Windows:

```
nix build .#projectWindowsCross.x86_64-linux.hsPkgs.dross.components.exes.dross
nix-shell -p wineWowPackages.base
wine ./result/bin/dross.exe
```

Cross-compile static binary (musl):

```
nix build .#projectMuslCross.x86_64-linux.hsPkgs.dross.components.exes.dross
./result/bin/dross
```

## Terms

- `buildPlatform`: Platform project is building on.
- `hostPlatform`: Platform project is building for (cross-compilation target).

## Further Reading

https://matthewbauer.us/blog/beginners-guide-to-cross.html

https://input-output-hk.github.io/haskell.nix/tutorials/cross-compilation.html

https://nix.dev/tutorials/cross-compilation.html

https://functor.tokyo/blog/2021-10-20-nix-cross-static
