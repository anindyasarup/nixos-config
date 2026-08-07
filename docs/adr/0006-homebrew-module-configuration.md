# 6. Homebrew module: check-only cleanup, no shell integration

Status: Accepted

Files: modules/homebrew.nix

`homebrew.onActivation.cleanup` is set to "check", not "uninstall"/"zap":
it makes the cask whitelist the actual source of truth (any `brew`-
installed package outside it fails activation with a diff), forcing a
manual decision, rather than silently deleting unlisted casks during a
routine `just rebuild`. `enableZshIntegration`/`enableBashIntegration` are
left off since every whitelisted entry is a GUI cask; none need `brew
shellenv` on PATH. Add one if a CLI formula is ever whitelisted.
