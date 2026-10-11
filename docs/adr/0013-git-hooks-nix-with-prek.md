# 13. Pre-commit hooks via git-hooks.nix, run by prek

Status: Accepted

Files: `flake.nix`, `.gitignore`

Replaces the lefthook setup, which generated `.lefthook.yaml` in `flake.nix`
and ran `lefthook install` from the devShell's `shellHook`.

## The change

The hooks are git-hooks.nix options passed to `git-hooks.lib.${system}.run`,
and the devShell takes `shellHook` and `enabledPackages` from the result.
statix, deadnix and nixfmt use git-hooks.nix's built-in hook definitions.
betterleaks has none, so it's a custom hook running
`betterleaks git --pre-commit --staged` with `pass_filenames = false`.
The `git-hooks` input follows this flake's nixpkgs, so the hook tools come
from the same nixpkgs as everything else.

`package = pkgs.prek` swaps the runner. prek is a single-binary
reimplementation of `pre-commit` that reads the same config, so the devShell
doesn't pull in a Python closure just to run hooks.

## Consequences

- `.pre-commit-config.yaml` is a symlink into the store, written by the
  `shellHook` and gitignored. Change hooks in `flake.nix`, not there.
- Installation sets `core.hooksPath` locally to `.git/hooks`. Nothing sets a
  global one since ADR 0012, so this changes nothing in practice.
- The nixfmt hook formats staged files in place and prek fails the commit
  when anything changed. lefthook used `treefmt --fail-on-change` from
  nixfmt-tree. That was nixfmt-tree's only use in the devShell, so it was
  dropped there; `nix fmt` still uses the `formatter` output.
- nixfmt runs alone at `priority = 0`; betterleaks, statix and deadnix share
  `priority = 1` and run in parallel. prek has no global parallel switch
  like lefthook's `parallel: true`, and putting nixfmt in the same group
  would let a check read a file while nixfmt is rewriting it.
- lefthook skipped merge commits; prek runs the hooks on them, against the
  conflicted files.
- The hooks aren't exposed as a flake `checks` output. That builds in a
  sandbox with no `.git`, where `betterleaks git --staged` can't run.
- `bump-flake.yaml` loads the devShell, so the hooks get installed on the
  runner, but its `git commit -n` skips them.
