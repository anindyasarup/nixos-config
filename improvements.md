# Improvements backlog

Ideas gathered from reading other people's Nix configs
(`dustinlyons/nixos-config`, `jmutai/nixos-configs-mac`, `kclejeune/system`)
plus stuff that came up along the way. This is a parking lot, not a roadmap:
nothing here is committed to. Sources are noted in case a one-liner isn't
enough and the original is worth a second look.

## Once this repo is pushed to GitHub

These two share the same blocker.

- A GitHub Action that runs `just update` on a schedule and opens a PR with
  whatever `flake.lock` change results (only when the zed-editor cache check
  in the `justfile` recipe actually passes), safer than the stock
  `update-flake-lock` action, which bumps to tip with no cache check at all.
  Written (`.github/workflows/bump-flake.yaml`), but not actually running:
  GitHub only reads `schedule` triggers off the default branch (`main`),
  which is still just the orphan initial commit, so the schedule never
  registered. Deliberately not fixed yet, since fixing it means either
  changing the default branch or diverging `main`'s workflows early, both
  premature before the v1 history-scrub settles what `main` even is.
- CI build verification: build `darwinConfigurations.default.system` on every
  PR, with a mock `vars.nix` provisioned as an explicit workflow step and
  passed via `--override-input vars ...` (workflow already written in
  `.github/workflows/build-verification.yaml`, but trigger-less
  (`workflow_dispatch` only) for now since a `push`-on-`wip` trigger was
  burning macos-14 runner minutes on every push; wire up the PR trigger
  once this repo has a remote).

## Toward a stable, public release

- **Scrub git history before the v1 release.** Decided: commit habits on
  this repo weren't great early on, so rather than auditing history for
  personal identifiers, just drop it entirely once v1 is ready, one clean
  commit instead of trying to prove the old ones are safe. Workflow: `git
checkout --orphan tmp`, `git add -A` (captures the full working tree,
  including anything still staged at the time), one fresh commit, delete
  the old `main`, rename `tmp` to `main`, so the branch name doesn't change.
  Purely local today, no remote is configured yet (`git remote -v` is
  empty), so there's nothing shared to invalidate. Deliberately deferred
  until the v1 work itself is done, not now.
- **Simplify `README.md`.** It's grown long as sections got added piecemeal;
  worth a pass once v1 is closer to check what a first-time reader actually
  needs versus what's better left to the `.nix` files and `CLAUDE.md`
  themselves.
