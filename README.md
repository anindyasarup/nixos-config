# nixos-config

A single declarative source of truth for this Mac: system settings,
packages, and development tooling (nix-darwin + home-manager, installed via
Determinate Nix). Replaces Homebrew and asdf entirely. Safe to publish: no
usernames, hostnames, paths, or emails live in this repo.

## The one command that matters

```sh
just rebuild        # = sudo darwin-rebuild switch --flake .#default <vars override>
```

## Layout

- `flake.nix`: inputs (nixpkgs unstable, nix-darwin, home-manager), vars
  resolution, `darwinConfigurations.default` output, plus a `devShells.default`
  and `formatter` for editing this repo itself
- `modules/darwin.nix`: core system-level settings
- `modules/system-defaults.nix`: `system.defaults.*` (dock, Finder, key
  repeat, screenshots, etc.)
- `modules/homebrew.nix`: the narrow, closed Homebrew exception (see
  `CLAUDE.md`)
- `modules/home/`: the home-manager layer, split by concern:
  `packages.nix` (CLI + GUI), `git.nix` (git/ssh), `shell.nix` (login shell,
  prompt, direnv), `cli-tools.nix` (fzf/bat/yazi/btop), `ghostty.nix`,
  `neovim.nix`, `zed.nix`, `default.nix` (manifest)
- `.zed/settings.json`: project-local Zed settings (currently just nixd's
  `options` config, pointed at this flake's own
  `darwinConfigurations.default.options` for hover/autocomplete on
  nix-darwin options); layered on top of the global
  `programs.zed-editor.userSettings` in `modules/home/zed.nix`
- `vars-required.nix`: tracked stub (just a `throw`) that the `vars` flake
  input falls back to when it isn't overridden; real identity lives at
  `~/.config/nix-config/vars.nix`, never in this repo
- `justfile`: `rebuild`, `update`, `check`, `preview`, `undo-update`,
  `generations`, `rollback`, `cleanup`, `fmt`, `lint`
- `docs/adr/`: design decisions worth a longer writeup than a `CLAUDE.md`
  bullet, e.g. why `vars` is a flake input instead of an env var

## Bootstrap on a fresh machine

Built and run on macOS 26. This is a personal, single-machine config, written
to also be readable as a reference, not a general-purpose installer for
arbitrary hardware.

```sh
# 1. Get this repo onto the machine without running `git`: a stock Mac's
# /usr/bin/git is an Xcode CLT stub that needs an interactive install.
# Use GitHub's "Download ZIP", or:
#   curl -L <repo-url>/archive/refs/heads/main.tar.gz | tar xz
# then cd into it.

# 2. Install Nix (precompiled binary, no compile step).
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
# Open a new terminal afterward to pick up the shell-rc edits.

# 3. Identity, required before step 4 (see "Privacy design" below).
# username: `whoami`. homeDirectory: `echo $HOME` (normally /Users/<username>).
mkdir -p ~/.config/nix-config
cat > ~/.config/nix-config/vars.nix <<'EOF'
{
  username = "youruser";
  homeDirectory = "/Users/youruser";
  system = "aarch64-darwin";
  git = {
    personal = {
      name = "Your Name";
      email = "you@example.com";
    };
    work = {
      name = "Your Name";
      email = "you@work-example.com";
    };
  };
}
EOF
$EDITOR ~/.config/nix-config/vars.nix

# 4. First activation (darwin-rebuild isn't on PATH yet, run it via `nix run`).
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#default \
  --override-input vars path:$HOME/.config/nix-config/vars.nix

# 5. Open a new terminal, cd back into this repo, and allow direnv. `just`
# and `uv` are devShell-scoped, so they only appear on PATH here, once
# direnv is allowed.
direnv allow
```

After that, `just rebuild` takes over. It also gives you a Nix-provided `git`
(home-manager's `programs.git`, see `modules/home/git.nix`), replacing the
Command Line Tools stub for good.

Not handled by this repo, do once yourself:

- **SSH keys**, for `git push`/private clones: `modules/home/git.nix` only
  points ssh at `~/.ssh/id_ed25519_personal` and `~/.ssh/id_ed25519_work`
  plus Keychain, it doesn't generate either. `ssh-keygen -t ed25519 -C
  "you@example.com" -f ~/.ssh/id_ed25519_personal` (repeat with `_work` and
  your work email), add each public key to its respective GitHub account,
  then `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal` (and the
  same for `_work`) once so both passphrases land in Keychain for
  `UseKeychain` to find. Repos cloned under `~/Development/personal/` or
  `~/Development/work/` automatically get the matching identity and key;
  neither is a default, so repos outside both directories get no identity
  or key from this config.
- **Raycast's `⌘Space` hotkey**: Nix only installs the app bundle, it can't
  run first-launch onboarding or touch macOS's own keybindings. Launch
  Raycast once (Launchpad, or `open -a Raycast`) and let onboarding take
  over `⌘Space` from Spotlight; if it doesn't ask, uncheck Spotlight's
  shortcut yourself in System Settings > Keyboard > Keyboard Shortcuts >
  Spotlight, then set `⌘Space` in Raycast > Settings > General > Raycast
  Hotkey.

## Finding packages

- Browse: <https://search.nixos.org/packages> (channel: `unstable`).
  A package works on this Mac if its platforms include `aarch64-darwin`
- Prove: `nix shell nixpkgs#<name>`: temporary shell with the package on
  PATH; exit and it's gone
- Understand: the package's build definition lives in
  <https://github.com/NixOS/nixpkgs>
- Build health: `https://hydra.nixos.org/job/nixpkgs/unstable/<package>.aarch64-darwin`:
  CI history (green = prebuilt in the binary cache, red = currently broken;
  note the jobset runs ahead of this flake's pin; it was named `trunk` until
  mid-2026 and old links redirect)

## Did an update change a package?

`just update` bumps `flake.lock` to nixpkgs tip, then checks one thing:
whether `zed-editor` (the one package here big enough that a local compile
actually matters) is cached and ready to pull there. If it is, the bump
stays; if it would instead need a local build, `flake.lock` is put back
exactly as it was and the recipe exits non-zero, no local compile ever
happens as a side effect of running it. Nothing downloads until the next
`just rebuild` either way.

For anything beyond zed-editor, `just preview` remains the authoritative,
whole-closure check: it lists what "will be fetched" (prebuilt, cheap)
versus what "will be built" (local compile). If `just update` succeeded but
`just preview` still shows something else under "will be built", that's a
different package Hydra hasn't cached yet; hold it back with `just
undo-update` and try again in a day.

## Secrets

Never in `.nix` files (the Nix store is world-readable). API keys go in the
macOS Keychain or per-project gitignored `.envrc` files via direnv.

## Homebrew

Used narrowly for apps nix can't install directly. See `CLAUDE.md` for
what's allowed and why.

## Privacy design

Identity (username, home path, git name/email) lives in
`~/.config/nix-config/vars.nix`, **outside this repo**. `flake.nix` takes it
as a flake input (`vars`), pointed at that file via `--override-input vars
path:~/.config/nix-config/vars.nix` (`.envrc`, the `justfile`, and CI all do
this already, so you shouldn't need to pass it by hand). Left un-overridden,
it resolves to the tracked `vars-required.nix` stub, which throws instead of
silently using a placeholder. This keeps every command pure: no `--impure`
anywhere. The machine config is named `default`, so no hostname appears here
either.
