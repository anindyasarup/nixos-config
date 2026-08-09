# nixos-config

Declarative config for an Apple Silicon Mac: system settings, packages, and
development tooling, via nix-darwin + home-manager on Determinate Nix.
Replaces Homebrew and asdf. Nothing personal is tracked here (no usernames,
home paths, hostnames, or emails), so the repo is safe to publish.

## Commands

| Command                              | What it does                                     |
| ------------------------------------ | ------------------------------------------------ |
| `just rebuild <profile>`             | Apply the config. This is the one that matters.  |
| `just preview <profile>`             | Dry run: what would be fetched vs. built locally |
| `just update` / `just undo-update`   | Bump `flake.lock`, or put it back                |
| `just check`                         | Evaluate the flake without applying it           |
| `just generations` / `just rollback` | List past builds, or return to the previous one  |
| `just cleanup [keep]`                | Delete old generations and collect garbage       |
| `just fmt` / `just lint`             | nixfmt, statix                                   |

The profile is `personal` or `work`, and is required: there's no default to
rebuild the wrong machine with. `work` is `personal` plus a few extras.

## Layout

```
flake.nix           inputs, the personal/work outputs, devShell, formatter
justfile            the commands above
vars-required.nix   stub the `vars` input falls back to; throws if not overridden
modules/
  darwin.nix            system-level settings
  system-defaults.nix   dock, Finder, key repeat, screenshots
  homebrew.nix          the few casks nix can't install
  work.nix              work-only extras, layered on top of personal
  home/                 home-manager: packages, git, shell, editors, terminal
docs/adr/           design decisions, with the reasoning
```

## Bootstrap a fresh machine

Built and run on macOS 26. It's a personal config first, written to be
readable as a reference second, not a general-purpose installer.

**1. Get the repo onto the machine without `git`.** A stock Mac's
`/usr/bin/git` is an Xcode CLT stub that triggers an interactive install.
Use GitHub's "Download ZIP", or:

```sh
curl -L <repo-url>/archive/refs/heads/main.tar.gz | tar xz
```

**2. Install Nix.** Precompiled, no compile step. Open a new terminal
afterward to pick up the shell-rc edits.

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

**3. Write your identity file.** Required before step 4. `username` is
`whoami`; `homeDirectory` is `echo $HOME`.

```sh
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
```

**4. First activation.** `darwin-rebuild` isn't on PATH yet, so run it via
`nix run`. Swap `personal` for `work` on a work machine.

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#personal \
  --override-input vars path:$HOME/.config/nix-config/vars.nix
```

**5. Open a new terminal and allow direnv.** `just` and `uv` live in the
devShell, so they only appear on PATH inside this repo.

```sh
direnv allow
```

From here `just rebuild` takes over, and git comes from Nix rather than the
Command Line Tools stub.

## One-time setup this repo can't do

### SSH keys

`modules/home/git.nix` points ssh at `~/.ssh/id_ed25519_personal` and
`~/.ssh/id_ed25519_work` and wires them to Keychain, but doesn't generate
them. For each account:

```sh
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519_personal
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal
pbcopy < ~/.ssh/id_ed25519_personal.pub   # add at github.com/settings/keys
```

`ssh-add` is what puts the passphrase in Keychain for `UseKeychain` to find
later. Then check each alias greets you as the right account:

```sh
ssh -T git@github.com-personal
ssh -T git@github.com-work
```

Which identity a repo gets depends only on where it lives:

| Repo location             | Identity + key                  |
| ------------------------- | ------------------------------- |
| `~/Development/personal/` | personal email, `_personal` key |
| `~/Development/work/`     | work email, `_work` key         |
| anywhere else             | none at all                     |

Neither is a default, so a repo outside both trees gets no identity and no
key. That's deliberate: it fails loudly instead of quietly committing under
the wrong name. Clone with the usual `git@github.com:` URL; the config
rewrites it to the right alias.

### `gh` authentication

The SSH keys cover `git`, not the `gh` CLI, which uses its own token.
`gh auth switch` is global, so it can't follow the directory split. Store
each token in Keychain and let direnv export the right one:

```sh
gh auth login   # as the personal account
security add-generic-password -U -a "$USER" -s "gh-personal" -w "$(gh auth token)"
# repeat for the work account, under "gh-work"

echo 'export GH_TOKEN=$(security find-generic-password -s "gh-personal" -w)' \
  > ~/Development/personal/.envrc
echo 'export GH_TOKEN=$(security find-generic-password -s "gh-work" -w)' \
  > ~/Development/work/.envrc

direnv allow ~/Development/personal
direnv allow ~/Development/work
```

`gh` reads `GH_TOKEN` before its own config. These `.envrc` files sit above
the repos they apply to and are never tracked here. Verify with
`gh auth status` in each tree.

### Raycast's `⌘Space`

Nix installs the app bundle but can't run first-launch onboarding or touch
macOS keybindings. Launch Raycast once and let onboarding take `⌘Space` from
Spotlight. If it doesn't ask, uncheck Spotlight's shortcut in System
Settings > Keyboard > Keyboard Shortcuts > Spotlight, then set `⌘Space` in
Raycast > Settings > General > Raycast Hotkey.

## Finding packages

- Browse <https://search.nixos.org/packages> (channel: `unstable`). It works
  on this Mac if its platforms include `aarch64-darwin`.
- Try it with `nix shell nixpkgs#<name>`: a temporary shell with the package
  on PATH, gone when you exit.
- Check build health at
  `https://hydra.nixos.org/job/nixpkgs/unstable/<package>.aarch64-darwin`.
  Green means prebuilt in the binary cache. The jobset runs ahead of this
  flake's pin, and was named `trunk` until mid-2026.

## Updating

`just update` bumps `flake.lock` to nixpkgs tip, then checks whether
`zed-editor` (the only package here big enough for a local compile to hurt)
is cached at that tip. If not, `flake.lock` is restored exactly as it was and
the recipe exits non-zero. Nothing downloads until the next `just rebuild`.

`just preview <profile>` is the authoritative check for everything else: it
splits the whole closure into "will be fetched" (prebuilt) and "will be
built" (local compile). If something is still under "will be built" after a
successful update, Hydra hasn't cached it yet. Hold it back with
`just undo-update` and try again in a day.

## Secrets

Never in `.nix` files, since the Nix store is world-readable. API keys go in
the macOS Keychain, or in per-project gitignored `.envrc` files via direnv.

## Homebrew

Used narrowly, for apps nix can't install directly. `CLAUDE.md` has the rules
for what qualifies.

## Privacy design

Identity (username, home path, git name and email) lives in
`~/.config/nix-config/vars.nix`, **outside this repo**. `flake.nix` takes it
as a flake input named `vars`, pointed at that file with
`--override-input vars path:~/.config/nix-config/vars.nix`. `.envrc`, the
justfile, and CI all pass it already, so you shouldn't need to type it.

Left un-overridden, `vars` resolves to the tracked `vars-required.nix` stub,
which throws rather than silently using a placeholder. That keeps evaluation
pure, with no `--impure` anywhere. The configurations are named by role
(`personal`, `work`) so no hostname appears here either.
