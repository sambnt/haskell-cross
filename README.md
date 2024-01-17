# Haskell Cross-Compilation

A collection of tools to help compile and distribute Haskell programs for Windows, Mac, and Linux.

Specifically, a graphical application using GLFW and Vulkan.

To get started:

```
nix flake init --template github:/sambnt/haskell-cross
# Build for Linux
nix build .#hydraJobs.dist-linux64
# Build for Windows
nix build .#hydraJobs.dist-win64
# See template README.md for more
```

## Further Reading

https://matthewbauer.us/blog/beginners-guide-to-cross.html

https://input-output-hk.github.io/haskell.nix/tutorials/cross-compilation.html

https://nix.dev/tutorials/cross-compilation.html

https://functor.tokyo/blog/2021-10-20-nix-cross-static
