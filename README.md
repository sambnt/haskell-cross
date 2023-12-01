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

## Files

- `flake.nix`:
- `flake.lock`: 
- `project.nix`: haskell.nix project expression

## Terms

- `buildPlatform`: Platform project is building on.
- `hostPlatform`: Platform project is building for (cross-compilation target).

## Fixing

### xorgproto

- xorg.xorgproto was failing when cross-compiling for Windows.
- Was able to reproduce minimally with `nix build .#pkgs.x86_64-linux.pkgsCross.mingwW64.xorg.xorgproto`.
- This indicated it might have little to do with my Haskell project, as the above invocation is purely vanilla nixpkgs.
- Build succeeded when I ran `nix build -f channel:nixos-unstable pkgsCross.mingwW64.xorg.xorgproto`, so it seems my version of nixpkgs might be the issue.
- Fixed with:
```
--- a/flake.nix
+++ b/flake.nix
@@ -2,7 +2,7 @@
   description = "Dross";
 
   inputs = {
-    nixpkgs.follows = "haskellNix/nixpkgs-2305";
+    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
     haskellNix = {
       url = "github:input-output-hk/haskell.nix";
       inputs.nixpkgs.follows = "nixpkgs";
```

### libX11

```
error: builder for '/nix/store/fqv942ad7nkslnwcfj6nzwnqv6jahxad-libX11-x86_64-w64-mingw32-1.8.6.drv' failed with exit code 2;
imDefIc.c: In function '_XimGetInputStyle':
imDefIc.c:1344:28: error: cast from pointer to integer of different size [-Werror=pointer-to-int-cast]
 1344 |             *input_style = (XIMStyle)p->value;
      |                            ^
```

- Using the the derivation path (`/nix/store/...libX11...`) I was able to surmise that the package could be found at `xorg.libX11`.
- Reproduced the failure minimally with `nix build .#pkgs.x86_64-linux.pkgsCross.mingwW64.xorg.libX11`.
- Tried to build using vanilla nixpkgs: `nix build -f channel:nixos-unstable pkgsCross.mingwW64.xorg.libX11`. This time I'm told:
```
Package ‘libX11-1.8.7’ in ... is not available on the requested hostPlatform:
         hostPlatform.config = "x86_64-w64-mingw32"
```
- Ok, so libX11 isn't available when compiling for Windows. What do we use instead?
- Found this: https://www.reddit.com/r/NixOS/comments/lqda7w/comment/gohdygb/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button. Maybe using wrong libX11? No, that comment isn't helpful in our case. We want something to target hostPlatform, not our buildPlatform.

- Posted an issue on haskell.nix: https://github.com/input-output-hk/haskell.nix/issues/2114
- After some thought. I shouldn't need X11 when I'm compiling for Windows. Windows doesn't use X11. What am I going to need to change to fix the compilation of GLFW?

- Let's start by trying to compile JUST Glfw

## Further Reading

https://matthewbauer.us/blog/beginners-guide-to-cross.html

https://input-output-hk.github.io/haskell.nix/tutorials/cross-compilation.html

https://nix.dev/tutorials/cross-compilation.html

https://functor.tokyo/blog/2021-10-20-nix-cross-static
