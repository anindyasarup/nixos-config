# 12. Remove the global git pre-commit hook and its chaining

Status: Accepted

Files: `modules/home/git.nix`

Supersedes ADR 0004 and ADR 0011.

## The change

The global `core.hooksPath` dispatcher (gitleaks scanning every staged
diff, then chaining to `.git/hooks/pre-commit` or `.husky/_/pre-commit` so
project-local hooks still ran) is removed entirely. `programs.git` no
longer sets `init.templateDir` or installs a hook script; git falls back to
its default per-repo `.git/hooks`, untouched by any global config.

## Why

Chaining onto a single `core.hooksPath` slot was a workaround for git only
resolving hooks from one place, and it kept accumulating edge cases: husky
repos silently losing gitleaks unless a local `core.hooksPath` override was
set by hand (and that override, in turn, breaking `simple-git-hooks`
repos with `EACCES` if ever applied there), worktrees needing
`--git-common-dir` instead of `--git-dir`, and only `pre-commit` being
covered at all. Each fix was correct in isolation but the mechanism itself,
one global hook standing in front of every project's own, was the wrong
shape to keep extending. Per-repo hook managers (husky, simple-git-hooks,
the `pre-commit` framework) are left to work exactly as their own tooling
expects, with nothing global intercepting them.
