# 1. Supply real identity via a flake input, overridden per invocation

Status: Accepted

Files: flake.nix, vars-required.nix, .envrc, justfile,
.github/workflows/build-verification.yaml, .github/workflows/bump-flake.yaml

Real identity (username, home path, git name/email) is supplied through the
`vars` flake input, overridden at every real entry point with
`--override-input vars path:<vars.nix>`, instead of reading `$HOME`
impurely (would force `--impure` everywhere) or committing a copy-the-
template placeholder (risks a real vars.nix landing in git). Left
un-overridden, `vars` resolves to the tracked `vars-required.nix` stub,
which throws instead of silently building against a placeholder. This
keeps every command pure while never committing real identity data.
