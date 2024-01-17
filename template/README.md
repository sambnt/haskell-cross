# Cross-compiled Haskell Project Template

This application will open a window for a brief second, and print information about the Vulkan instance created.

Build project for your platform:

```
nix build .#foobar
```

Cross-compile for Windows:

```
nix build .#foobar-win64
```

For distribution to other machines:

```
nix build .#hydraJobs.dist-linux64
nix build .#hydraJobs.dist-win64
```

Enter development shell:

```
nix develop
cabal run exe:foobar
```
