# Cross-compiled Haskell Project Template

Build project for your platform:

```
nix build .#foobar
```

Cross-compile for Windows:

```
nix build .#foobar-win64
```

Enter development shell:

```
nix develop
cabal run exe:foobar
```
