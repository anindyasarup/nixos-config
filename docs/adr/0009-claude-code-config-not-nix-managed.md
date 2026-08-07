# 9. Claude Code's own config stays out of Nix, tracked in a private repo instead

Status: Accepted

Files: (none, deliberately)

Claude Code's own config (`~/.claude/CLAUDE.md`, `settings.json`,
`hooks/*.sh`, `keybindings.json`) is not managed by this repo's
home-manager setup, even though home-manager ships an official
`programs.claude-code` module that could do it. `home.file` (and that
module) writes managed files as symlinks into `/nix/store`, but Claude
Code's directory-scan discovery for `commands/`, `agents/`, and `skills/`
silently skips symlinked entries
(<https://github.com/anthropics/claude-code/issues/764>, open since
2025-04): files just don't show up, no error. `CLAUDE.md` itself and
hooks referenced by an explicit `command` path in `settings.json` aren't
actually hit by that bug, but the risk of hitting it elsewhere in
`~/.claude` isn't worth carrying piecemeal Nix management for one part of
the directory while leaving the rest exposed to it.

Accepted workaround until upstream fixes it: track this config in its own
private repo instead, plain files/symlinks via a tool like `stow`, not Nix.
Revisit once #764 is closed.
