# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single declarative source of truth for a personal Apple Silicon Mac:
system settings, packages, and development tooling, all managed through
nix-darwin + home-manager (flake-based, Determinate Nix), so the whole
machine can be rebuilt from this repo alone. In practice that means it
replaces asdf entirely, and replaces Homebrew for everything except a
narrow, closed set of macOS software nix structurally cannot install (see
"Homebrew: narrow, closed exception" below before ever reaching for
`brew`). GUI apps come from nixpkgs; if one is broken/missing on
`aarch64-darwin` for an ordinary packaging reason (not packaged, fails to
build, not notarized), the fallback is a direct download from the vendor,
not Homebrew.

## Homebrew: narrow exception

Homebrew was fully removed (2026-07) and stays removed as the general
package manager. It comes back only through nix-darwin's declarative
`homebrew.*` module (`modules/homebrew.nix`), never an ad hoc `brew install`
or `brew tap` outside of what's declared there.

Two things justify a cask, and nothing else does:

1. **The install mechanism.** Software needing a vendor-signed installer
   plus a macOS system/network/kernel extension through Apple's
   extension-approval flow, which nix structurally can't do. Same reason
   nixpkgs marks `mullvad-vpn` `badPlatforms` for Darwin.
2. **A GUI app genuinely absent from nixpkgs on `aarch64-darwin`**, where
   the only other option is re-downloading a `.dmg` by hand for every
   update. `brew upgrade` keeping it current is worth more than the purity
   of a manual download here.

Reason 2 is a real relaxation of the original rule (which sent this case to
a vendor direct download), so keep it honest: check nixpkgs first and only
fall back to a cask when the package truly isn't there for
`aarch64-darwin`. "Awkward to package" or "easier via brew" still doesn't
clear the bar for something nixpkgs already ships.

Current casks (`modules/homebrew.nix`): `focusrite-control` (reason 1),
`claude` (reason 2), `mullvad-vpn` (reason 1). Don't add a tap, formula, or
cask because it seems convenient in the moment; if something new looks like
it needs Homebrew, check it against the two reasons above and ask the user
before adding. This file is the source of truth, not whatever seems
reasonable in the moment.

Homebrew itself (the `brew` binary) is bootstrapped declaratively too,
through the `nix-homebrew` flake input (wired in `flake.nix`). nix-darwin's
`homebrew.*` module only manages taps/casks/formulae on top of an existing
install. It doesn't install Homebrew itself, which is the gap
`nix-homebrew` fills. `just rebuild` alone installs both; there's no
separate manual `brew.sh` step.

## Commands

```sh
just rebuild personal   # apply = sudo darwin-rebuild switch --flake .#personal <vars override>
just rebuild work       # same, with the work profile's additions layered on
just update             # bump flake inputs (then `just rebuild` to apply)
just check              # evaluate without applying
```

Build without activating (no sudo; use this to verify changes):

```sh
nix build .#darwinConfigurations.personal.system --override-input vars path:$HOME/.config/nix-config/vars.nix --no-link
```

The `--override-input vars ...` flag is required everywhere, not optional
(see below); the `justfile` recipes already add it via their `vars_override`
variable. `just rebuild` needs sudo, so the user must run it (or approve it)
interactively.

## Architecture: the privacy design

The repo is intended to be publishable. No username, home path, hostname, or
email may ever appear in tracked files.

- Real identity lives in `~/.config/nix-config/vars.nix`, outside the repo.
  `flake.nix` takes it as a flake input (`vars`), supplied via
  `--override-input vars path:~/.config/nix-config/vars.nix` at every real
  entry point (`.envrc`, `justfile`, CI). This is what keeps evaluation
  pure, no `--impure` anywhere. Left un-overridden, the input resolves to
  the tracked `vars-required.nix` stub, which throws. Full reasoning:
  `docs/adr/0001-vars-flake-input-override.md`.
- Modules receive it as the `vars` arg (via `specialArgs` /
  `extraSpecialArgs`). Use `vars.username`, `vars.homeDirectory`, etc.
  Never literals.
- The darwin configurations are named by role (`personal`, `work`), never by
  hostname.
- Commits must be authored with the GitHub noreply address; the account has
  "block command line pushes that expose my email" enabled, so a real-email
  commit will be rejected at push time.

## Machine profiles

`flake.nix` exposes two outputs, both built from one `mkDarwin` helper:
`personal` (the shared base) and `work` (that base plus
`modules/work.nix`). The work profile is strictly additive:
`modules/work.nix` only appends to list options (`homebrew.casks`,
`home.packages` via `modules/home/work.nix`), which the module system merges
onto the base rather than replacing, so `modules/home/packages.nix` and
`modules/homebrew.nix` stay machine-agnostic and nothing work-specific leaks
into a personal rebuild.

Which machine you're on is a build-time choice, deliberately not a field in
`vars.nix`: the profile isn't identity, and keeping it out means both
machines share one `vars.nix` schema. Anything work-only that *is* identity
(git name/email) already lives in `vars.git.work` and is selected by
directory, not by profile.

`just rebuild` and `just preview` both take the profile as a **required**
argument with no default, so neither can silently rebuild the wrong
machine's configuration. `just update`'s internal zed-editor cache probe
hardcodes `personal`, which is fine: the probe only reads `.pkgs`, which is
the same package set for both profiles.

## Non-obvious constraints

- `nix.enable = false` in `modules/darwin.nix` is required: Determinate Nix owns the
  daemon and `/etc/nix/nix.conf`. Do not re-enable or set `nix.*` options.
- Python is deliberately NOT managed by Nix. `uv` (the binary) comes from
  nixpkgs; interpreters, venvs, and packages are uv's job. Don't add
  `python3`, `python3Packages.*`, or poetry2nix-style machinery.
- Flakes only see git-tracked files: `git add` any new `.nix` file before
  building, or the build fails with "path does not exist".
- `stateVersion` values (`modules/home/default.nix`, `modules/darwin.nix`)
  are frozen at first activation. Never bump them.
- The pre-2026-07 Homebrew setup (before it was fully removed) isn't
  preserved anywhere in this repo's history; see "Homebrew: narrow, closed
  exception" above for the current, much smaller, declarative
  reintroduction.
- `fonts.packages` (`modules/darwin.nix`) must list `nerd-fonts.jetbrains-mono`
  explicitly: Ghostty's `font-family` (`modules/home/ghostty.nix`) names that
  font but doesn't bundle it (confirmed via `ghostty +list-fonts` finding
  nothing without it).
- `security.pam.services.sudo_local` (`modules/darwin.nix`): `touchIdAuth`
  falls back to password automatically when Touch ID isn't available (SSH,
  scripts, no sensor); `reattach = false` lets Ghostty come to the
  foreground on a sudo prompt.
- `system.defaults.screencapture.location` (`modules/system-defaults.nix`)
  points at a folder macOS won't create itself; `modules/home/default.nix`'s
  `createScreenshotsDir` activation script `mkdir`'s it. The two must stay
  paired.
- `just`/`uv` are intentionally absent from `home.packages`
  (`modules/home/packages.nix`): both are project-scoped (this repo's own
  workflow, and per-project Python respectively), not things every
  directory needs, so they live in `flake.nix`'s devShell instead, picked
  up via direnv only inside repos that declare them.
- The `justfile` carries no comments, so three things it used to explain live
  here instead. `vars_override` resolves `env_var("HOME")` at parse time, as
  the invoking user, so it stays correct in the recipes where `sudo` follows
  (an in-recipe `$HOME` read under sudo would not). `cleanup`'s `+N` keeps
  the N newest generations plus anything newer than current (in case a
  rollback happened), and the `nix-collect-garbage` line is what actually
  reclaims disk; deleting the generation registration alone frees nothing.
  `rollback` reverts an activation, whereas `undo-update` reverts `flake.lock`
  before a rebuild has happened at all.
- Modern bash (5.x, via `programs.bash.enable`) stays on `PATH` alongside
  zsh (the login shell) because macOS ships bash 3.2 in `/bin/bash`.
  Ghostty's `command` (`modules/home/ghostty.nix`) launches `bashInteractive`
  as a login shell (`-l`) so profile files get sourced; `macos-option-as-alt`
  is required there for fzf's Alt+C / bash's Alt+. bindings
  (`modules/home/cli-tools.nix`, `modules/home/shell.nix`).
- Editor/terminal theming is kept in sync across `modules/home/ghostty.nix`
  ("Atom One Dark"), `modules/home/neovim.nix` (`onedark-nvim`), and
  `modules/home/zed.nix` (One Light/One Dark): check all three when
  changing the theme.
- Zed settings live in two layers: `modules/home/zed.nix`'s
  `programs.zed-editor.userSettings` (per-machine; `mutableUserSettings`
  jq-merges these onto whatever Zed's UI already wrote to settings.json on
  activation, rather than overwriting it) versus `.zed/settings.json`
  (per-project, e.g. this repo's own `darwinConfigurations.default` option
  completion). `extraPackages` includes `nixfmt` so Zed's format-on-save
  stays in sync with this repo's own `nix fmt` (`nixfmt-tree`).
- `modules/home/git.nix` picks the git identity and SSH key purely by
  directory, via two `programs.git.includes`' `gitdir:` conditions
  (`~/Development/personal/` / `~/Development/work/`); neither is a
  default, so repos outside both trees get no identity or key. Each
  `includeIf` also rewrites `git@github.com:` to its own SSH `Host` alias
  (`github.com-personal` / `github.com-work`), so the key switch is
  transparent, no special clone URL needed. Two separate `Host` blocks
  (not `core.sshCommand`) is required: SSH's `IdentitiesOnly yes` only
  disambiguates cleanly when each alias has exactly one identity configured,
  otherwise it can try both keys and authenticate as the wrong account.
  Both aliases set `HostKeyAlias = "github.com"` to share one `known_hosts`
  entry instead of prompting twice.
- `core.hooksPath` (`modules/home/git.nix`) replaces `.git/hooks` rather than
  adding to it, so the global gitleaks `pre-commit` has to `exec` the
  project's own hook or it silently kills it. Only `pre-commit` is covered,
  and a repo-local `core.hooksPath` (husky) still wins over the global one:
  `docs/adr/0011-chained-git-pre-commit-hook.md`.
- `bump-flake.yaml`'s `cron: "0 16 * * *"` targets 2am Melbourne time at
  UTC+10 (AEST). GitHub Actions schedules are fixed UTC with no timezone
  awareness, so during Melbourne's daylight saving (AEDT, UTC+11, roughly
  Oct-Apr) this actually fires at 3am local time; there's no fix for that
  short of maintaining two seasonal cron lines.
