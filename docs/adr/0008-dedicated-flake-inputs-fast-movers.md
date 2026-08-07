# 8. Dedicated flake inputs for fast-moving tools

Status: Proposed

Files: flake.nix

For tools that update far more often than nixpkgs picks up new versions
(e.g. `claude-code`), pulling from a dedicated upstream flake input instead
of the nixpkgs attribute would let that one package update on its own
cadence rather than waiting on a nixpkgs bump. Not adopted yet: no specific
tool's update lag has been painful enough to justify the extra input and
per-tool overlay it would need. Revisit if that changes.
