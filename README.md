# nixos-config

One declarative description of an Apple Silicon Mac: system settings, the
packages installed on it, and the development environment. Built on
nix-darwin and home-manager, running on Determinate Nix.

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

`just` and the other repo tools live in the flake's devShell, so they appear
on PATH through direnv once you're inside this directory.

## Profiles

The flake builds two configurations from one helper. `personal` is the base.
`work` is that base plus `modules/work.nix`, which appends work-only
packages (Slack, Postman, colima, docker) and pins a different set of dock
apps.

The profile argument is required on `just rebuild` and `just preview`, with
no default, so neither can quietly build the wrong machine. The profile is
a build-time choice and never appears in `vars.nix`, which lets both
machines share one identity file.

## Identity lives outside the repo

Username, home path, and git names and emails go in
`~/.config/nix-config/vars.nix`. `flake.nix` reads that file as an input
named `vars`, supplied at every entry point with:

```
--override-input vars path:~/.config/nix-config/vars.nix
```

`.envrc`, the justfile, and CI all pass it, so you rarely type it yourself.
Without the override, `vars` falls back to the tracked `vars-required.nix`,
which throws. No placeholder gets substituted, evaluation stays pure, and
there's no `--impure` anywhere. The configurations are named by role, so no
hostname leaks in either. Reasoning in
[`docs/adr/0001`](docs/adr/0001-vars-flake-input-override.md).

## Layout

```
flake.nix           inputs, the personal/work outputs, devShell, formatter
justfile            the commands above
vars-required.nix   stub the `vars` input falls back to; throws if not overridden
modules/
  mk-darwin.nix         the helper both profiles are built from
  darwin.nix            system-level settings
  system-defaults.nix   Finder, key repeat, screenshots, privacy toggles
  dock.nix              dock layout and behaviour
  homebrew.nix          the few casks nix can't install
  nix-gc.nix            weekly garbage collection via launchd
  work.nix              work-only extras, layered on top of personal
  home/                 home-manager: packages, git, shell, editors, terminal
docs/adr/           design decisions, with the reasoning
```

## Bootstrap a fresh machine

Built and run on macOS 26. This is my own machine's config, published so it
can be read; it assumes you'll edit it before running it anywhere else.

**1. Get the repo onto the machine without `git`.** A stock Mac's
`/usr/bin/git` is an Xcode CLT stub that triggers an interactive install.
Use GitHub's "Download ZIP", or:

```sh
curl -L https://github.com/anindyasarup/nixos-config/archive/refs/heads/main.tar.gz | tar xz
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
  certificateFiles = [ "/usr/local/etc/certificates/<corp-ca>.pem" ];
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

`certificateFiles` trusts extra CA certificates (a corporate MITM proxy, for
instance) system-wide. The `.pem` files themselves go in
`/usr/local/etc/certificates/`, unmanaged by nix-darwin and outside the
repo. Leave the list empty if you have no such certs.

**4. First activation.** `darwin-rebuild` isn't on PATH yet, so run it via
`nix run`. Swap `personal` for `work` on a work machine.

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#personal \
  --override-input vars path:$HOME/.config/nix-config/vars.nix
```

**5. Open a new terminal and allow direnv.**

```sh
direnv allow
```

From here `just rebuild` takes over, git comes from Nix, and the devShell's
pre-commit hooks are installed.

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

Spotlight's `⌘Space` is disabled declaratively
(`modules/system-defaults.nix`), but Nix can't touch Raycast's own
keybindings. Launch Raycast once, then set `⌘Space` in Raycast > Settings >
General > Raycast Hotkey.

## Finding packages

- Browse <https://search.nixos.org/packages> (channel: `unstable`). A
  package works on this Mac if its platforms include `aarch64-darwin`.
- Try it with `nix shell nixpkgs#<name>`: a temporary shell with the package
  on PATH, gone when you exit.
- Check build health at
  `https://hydra.nixos.org/job/nixpkgs/unstable/<package>.aarch64-darwin`.
  Green means prebuilt in the binary cache. The jobset runs ahead of this
  flake's pin, and was named `trunk` until mid-2026.

## Updating

`just update` bumps `flake.lock` to nixpkgs tip, then checks whether
`zed-editor` (the only package here big enough for a local compile to hurt)
is cached at that tip. If it isn't, `flake.lock` is restored exactly as it
was and the recipe exits non-zero. Nothing downloads until the next
`just rebuild`.

`just preview <profile>` is the authoritative check for everything else. It
splits the whole closure into "will be fetched" (prebuilt) and "will be
built" (local compile). If something is still under "will be built" after a
successful update, Hydra hasn't cached it yet; hold it back with
`just undo-update` and try again in a day.

A nightly workflow runs the same `just update` and opens a PR when the lock
moves. Every PR to `main` builds both profiles on a macOS runner against a
mock `vars.nix`, so a broken configuration fails in CI rather than during a
rebuild.

## Secrets

Never in `.nix` files: the Nix store is world-readable. API keys go in the
macOS Keychain, or in per-project gitignored `.envrc` files via direnv. The
devShell installs a pre-commit hook that scans staged changes for leaked
secrets alongside the lint and format checks.

## Homebrew

Used narrowly, through nix-darwin's declarative `homebrew.*` module rather
than ad hoc `brew install`. Two situations justify a cask: the install needs
a vendor-signed installer or system extension that nix structurally can't
perform, or nixpkgs can't keep the app usable on `aarch64-darwin`.

WhatsApp is the second case. nixpkgs pins an exact build fetched straight
from WhatsApp's own CDN, which purges old versions faster than the flake
gets bumped, breaking both the build and login on stale clients, so it comes
from the `whatsapp` cask instead. Brave is there for the same reason. The
current list lives in `modules/homebrew.nix`.
