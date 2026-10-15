# AGENTS.md

## What this is

Declarative config for a personal Apple Silicon Mac: nix-darwin +
home-manager, flake-based, on Determinate Nix. The whole machine rebuilds
from this repo. It replaces asdf, and Homebrew except for the narrow
exception below. GUI apps come from nixpkgs, or a cask when reason 2 below
applies.

## Homebrew: narrow exception

Homebrew exists only through nix-darwin's `homebrew.*` module
(`modules/homebrew.nix`). Never run `brew install` or `brew tap` outside
it. A cask needs one of two reasons:

1. The software needs a vendor-signed installer plus a macOS
   system/network/kernel extension approved through Apple's flow, which
   nix can't do (why nixpkgs marks `mullvad-vpn` `badPlatforms` on Darwin).
2. A GUI app nixpkgs can't keep usable on `aarch64-darwin`: absent, or
   packaged in a way that can't stay current (e.g. pinned to a version the
   vendor's CDN purges before the flake gets bumped).

Check nixpkgs first. "Awkward to package" or "easier via brew" doesn't
qualify for something nixpkgs ships and keeps working. Ask the user before
adding any tap, formula, or cask.

Current casks:

- `focusrite-control` (reason 1)
- `claude` (reason 2)
- `whatsapp` (reason 2): nixpkgs' `whatsapp-for-mac` pins a version
  WhatsApp's CDN purges quickly, breaking the build and login.
- `brave-browser` (reason 2): nixpkgs' `brave` repeatedly ships revisions
  whose pinned `.dmg`/`.zip` fails to unpack on `aarch64-darwin`, breaking
  `just rebuild` and the daily `automated/flake-update` CI for days.
- `zed` (reason 2): Hydra often lags on `zed-editor`, so staying current
  means compiling Zed's Rust locally. `modules/home/zed.nix` still owns
  the settings and sets `package = null`. It points Zed at nixd and nixfmt
  by store path, since `extraPackages` only works with a nix-built Zed.

The `brew` binary itself comes from the `nix-homebrew` flake input (wired
in `flake.nix`), so `just rebuild` alone installs everything.

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

`--override-input vars ...` is required everywhere; the `justfile` adds it
via `vars_override`. `just rebuild` needs sudo, so the user runs or
approves it.

## Privacy

The repo is publishable: no username, home path, hostname, or email in
tracked files.

- Identity lives in `~/.config/nix-config/vars.nix`, outside the repo, and
  enters as the `vars` flake input via `--override-input` (`.envrc`,
  `justfile`, CI). This keeps evaluation pure. Un-overridden, it resolves
  to the `vars-required.nix` stub, which throws. See
  `docs/adr/0001-vars-flake-input-override.md`.
- Modules get it as the `vars` arg. Use `vars.username`,
  `vars.homeDirectory`, etc., never literals.
- Darwin configurations are named by role (`personal`, `work`), never by
  hostname.
- Commit with the GitHub noreply address; pushes exposing a real email are
  rejected.

## Machine profiles

`personal` is the base; `work` adds `modules/work.nix`, built from the same
`mkDarwin` helper. `work` is strictly additive: it only appends to list
options (`homebrew.casks`, `home.packages` via `modules/home/work.nix`), so
`modules/home/packages.nix` and `modules/homebrew.nix` stay
machine-agnostic.

The profile is a build-time argument, not a `vars.nix` field, so both
machines share one `vars.nix` schema. Work git identity lives in
`vars.git.work` and is selected by directory. `just rebuild` and
`just preview` require the profile with no default.

## Non-obvious constraints

- `nix.enable = false` (`modules/darwin.nix`) is required: Determinate Nix
  owns the daemon and `/etc/nix/nix.conf`. Don't set any `nix.*` options.
- Python isn't managed by Nix. Only the `uv` binary comes from nixpkgs;
  don't add `python3`, `python3Packages.*`, or poetry2nix-style machinery.
- Flakes only see git-tracked files: `git add` new `.nix` files before
  building.
- Never bump `stateVersion` (`modules/home/default.nix`,
  `modules/darwin.nix`).
- `fonts.packages` (`modules/darwin.nix`) must list
  `nerd-fonts.jetbrains-mono`: Ghostty's `font-family` names it but doesn't
  bundle it.
- `security.pam.services.sudo_local`: `touchIdAuth` falls back to a password
  without a sensor; `reattach = false` lets Ghostty come to the foreground
  on a sudo prompt.
- `system.defaults.screencapture.location` (`modules/system-defaults.nix`)
  needs `createScreenshotsDir` in `modules/home/default.nix` to create the
  folder. Keep them paired.
- `just` and `uv` are project-scoped, so they live in `flake.nix`'s devShell
  (via direnv), not `home.packages`.
- `justfile` details: `vars_override` resolves `env_var("HOME")` at parse
  time, so it stays correct under `sudo`. `cleanup`'s `+N` keeps the N
  newest generations plus anything newer than current; its
  `nix-collect-garbage` line is what frees disk. `rollback` reverts an
  activation; `undo-update` reverts `flake.lock` before a rebuild.
- Bash 5 (`programs.bash.enable`) stays on `PATH` because macOS ships 3.2;
  zsh is the login shell. Ghostty runs `bashInteractive -l` so profile
  files load, and needs `macos-option-as-alt` for fzf's Alt+C and bash's
  Alt+. bindings.
- Theme is synced across `modules/home/ghostty.nix` ("Atom One Dark"),
  `modules/home/neovim.nix` (`onedark-nvim`), and `modules/home/zed.nix`
  (One Light/One Dark). Change all three together.
- Zed settings live only in `modules/home/zed.nix`. All four
  `mutableUser*` options are `false` because home-manager's default
  jq-merge never removes deleted keys. As a result, changes made in Zed's
  UI can't be saved. The formatter is nixpkgs' `nixfmt` to match
  `nix fmt`. There is deliberately no `.zed/settings.json`.
- `modules/home/git.nix` picks git identity and SSH key by directory
  (`~/Development/personal/`, `~/Development/work/`); repos elsewhere get
  neither. Each `includeIf` rewrites `git@github.com:` to its own `Host`
  alias (`github.com-personal` / `github.com-work`). Separate `Host` blocks,
  not `core.sshCommand`, are required so `IdentitiesOnly yes` offers
  exactly one key per alias. Both set `HostKeyAlias = "github.com"` to
  share one `known_hosts` entry.
- `bump-flake.yaml`'s `cron: "0 16 * * *"` is 2am Melbourne in AEST and
  3am during AEDT (roughly Oct-Apr). GitHub cron is UTC-only; accept the
  drift.
- `AppleSymbolicHotKeys."64".enabled = false` (`modules/system-defaults.nix`)
  frees `⌘Space` for Raycast. `defaults write` replaces the whole key, so
  any new `AppleSymbolicHotKeys` entries must sit in the same attrset as
  `64`.
