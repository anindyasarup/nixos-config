# 3. Terminal: Ghostty via the vendor's notarized binary

Status: Accepted

Files: modules/home/ghostty.nix

`programs.ghostty.package` is set to `ghostty-bin` (the vendor's notarized
universal binary, fetched via `fetchurl`), not nixpkgs' `ghostty` source
build, which doesn't build on aarch64-darwin. `auto-update` is set to
"off" since updates come from nixpkgs bumps instead. This replaced
`warp-terminal`, whose nixpkgs build rewrites
`Contents/Resources/bin/oz` and thereby breaks Warp's notarization seal,
producing macOS's "app is damaged" error.
