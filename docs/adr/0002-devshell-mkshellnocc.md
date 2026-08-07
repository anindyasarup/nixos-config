# 2. Dev shell uses mkShellNoCC, not mkShell

Status: Accepted

Files: flake.nix

The flake's `devShells.default` (statix, just, uv) is built with
`pkgs.mkShellNoCC` rather than `pkgs.mkShell`. None of those three need a C
compiler, and plain `mkShell`'s default stdenv otherwise pulls in a full
clang/xcbuild toolchain nothing here uses.
