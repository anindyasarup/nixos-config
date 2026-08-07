# 4. Secret scanning as a global git hook, not per-repo

Status: Accepted

Files: modules/home/git.nix

`programs.git.hooks.pre-commit` runs gitleaks via `core.hooksPath`, which
applies to every repo on the machine. Unlike a repo-specific tool choice
(nixfmt/statix), secret scanning is something every commit, everywhere,
should get, so it's scoped globally rather than per-project. It scans only
the staged diff, so it stays fast regardless of repo size.
