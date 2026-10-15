# nixos-config

[![Build verification](https://github.com/anindyasarup/nixos-config/actions/workflows/build-verification.yaml/badge.svg)](https://github.com/anindyasarup/nixos-config/actions/workflows/build-verification.yaml)

This repository contains the configuration for my Mac devices: system
settings, the packages installed on them, and my development environment,
all built with nix-darwin and home-manager on top of Determinate Nix.

**WARNING: This isn't meant to be an all-in-one solution for everyone.**

## How I Work

I want to be able to take my configurations, in a declarative way, and
apply them to any machine. This solution helps eliminate any struggle with
being able to replicate my workflows across both my personal and work
machines. So everything on them gets declared here, down to the dock layout.

I currently apply this on two machines, a personal one and a work one.
The work machine gets the personal config plus a small layer on
top: Slack, colima, docker, and a different set of dock apps.

## Layout

If you're poking around, this is roughly where things are:

```
flake.nix           inputs, the personal/work outputs, devShell, formatter
justfile            the commands below
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

## Setup

**WARNING: Don't do this without reading the source.** This is _my_
machine's configuration, and running it blindly will change your Mac in
ways you probably don't want.

| Heads up        | Details                                                         |
| --------------- | --------------------------------------------------------------- |
| Platform        | Apple Silicon Macs only, tested on macOS 26.                    |
| Nix installer   | Assumes Determinate Nix. Others are untested.                   |
| Homebrew        | Fails if you have packages not in `modules/homebrew.nix`.       |
| Dock + settings | Your dock and some system settings get replaced with mine.      |
| Dotfiles        | Existing ones like `~/.zshrc` get moved aside to `*.backup`.    |
| Secrets         | Keep them out of `.nix` files. The Nix store is world-readable. |

First, get the repo onto the machine without using `git`. On a stock Mac,
`/usr/bin/git` is an Xcode Command Line Tools stub that pops up an
installer the moment you run it. Use GitHub's "Download ZIP" button, or:

```sh
curl -L https://github.com/anindyasarup/nixos-config/archive/refs/heads/main.tar.gz | tar xz
```

Install Nix with the Determinate Systems installer. Open a new terminal
afterwards so the shell picks up the changes it made.

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Next, write your identity file. The build refuses to evaluate without it.
`username` is whatever `whoami` prints, and `homeDirectory` is `$HOME`:

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

`certificateFiles` is for extra CA certificates you want trusted
system-wide, such as a corporate MITM proxy's. The `.pem` files themselves
go in `/usr/local/etc/certificates/`, outside the repo and unmanaged by
nix-darwin. If you don't have any, leave the list empty.

Now do the first activation. `darwin-rebuild` isn't on your PATH yet, so
run it through `nix run`. Swap `personal` for `work` on a work machine.

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#personal \
  --override-input vars path:$HOME/.config/nix-config/vars.nix
```

Open a new terminal, `cd` into the repo, and allow direnv:

```sh
direnv allow
```

That's it. Loading the devShell also installed the pre-commit hooks, and
git now comes from Nix. From here on, changes go in through `just rebuild`.

## Day to Day

I drive everything through `just`, which only exists inside this repo: it
lives in the flake's devShell, and direnv puts it on PATH when you `cd` in.

| Command                              | What it does                                     |
| ------------------------------------ | ------------------------------------------------ |
| `just rebuild <profile>`             | Apply the config. This is the one that matters.  |
| `just preview <profile>`             | Dry run: what would be fetched vs. built locally |
| `just update` / `just undo-update`   | Bump `flake.lock`, or put it back                |
| `just check`                         | Evaluate the flake without applying it           |
| `just generations` / `just rollback` | List past builds, or return to the previous one  |
| `just cleanup [keep]`                | Delete old generations and collect garbage       |
| `just fmt` / `just lint`             | nixfmt, statix                                   |

The profile argument on `just rebuild` and `just preview` is required, with
no default. I'd rather type `personal` every time than accidentally build
the work config on my personal machine, or the other way round.

### Updating

`just update` bumps `flake.lock` to the tip of nixpkgs. Nothing downloads
until the next `just rebuild`.

I check an update with `just preview <profile>`. It splits
the whole closure into "will be fetched" (prebuilt) and "will be built"
(compiled on my machine). If something is still under "will be built" after
an update, Hydra just hasn't caught up yet. I run `just undo-update` and try
again the next day.

I rarely run `just update` by hand. A nightly GitHub Actions workflow does
it and opens a PR whenever the lock moves. Every PR to `main` builds both
profiles on a macOS runner against a mock `vars.nix`, so a broken config
shows up in CI before it reaches my rebuild.

## Identity Lives Outside the Repo

My username, home path, and git names and emails live in
`~/.config/nix-config/vars.nix`. `flake.nix` takes that file as a flake
input called `vars`, and every entry point overrides it:

```bash
--override-input vars path:~/.config/nix-config/vars.nix
```

`.envrc`, the justfile, and CI all pass that flag, so I almost never type it
myself. Because identity arrives as a flake input instead of being read
from `$HOME`, evaluation stays pure and nothing needs `--impure`. If you
forget the override, `vars` falls back to the tracked `vars-required.nix`,
which throws an error so a build never quietly runs with placeholder
values. The two configurations are named by role (`personal`, `work`)
instead of by hostname, so the hostname doesn't leak either. The full
reasoning is in
[`docs/adr/0001`](docs/adr/0001-vars-flake-input-override.md).

Which machine I'm on is picked at build time by the profile argument, and
`vars.nix` has no field for it. The profile isn't identity, and leaving it
out means both machines share the same identity file format.

## Things Nix Can't Do For Me

A few bits of one-time setup have to happen by hand. I've written them down
so I don't have to rediscover them on the next machine.

### SSH Keys

`modules/home/git.nix` points ssh at `~/.ssh/id_ed25519_personal` and
`~/.ssh/id_ed25519_work` and hooks both up to the Keychain, but it doesn't
create the keys. For each account:

```sh
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519_personal
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal
pbcopy < ~/.ssh/id_ed25519_personal.pub   # add at github.com/settings/keys
```

`ssh-add` stores the passphrase in the Keychain, where `UseKeychain` finds
it later. Then check that each alias greets you as
the right account:

```sh
ssh -T git@github.com-personal
ssh -T git@github.com-work
```

The identity a repo gets depends only on where it lives:

| Repo location             | Identity + key                  |
| ------------------------- | ------------------------------- |
| `~/Development/personal/` | personal email, `_personal` key |
| `~/Development/work/`     | work email, `_work` key         |
| anywhere else             | none at all                     |

That last row is on purpose. A repo outside both trees fails loudly
instead of quietly committing under the wrong name. Clone with the normal
`git@github.com:` URL and the config rewrites it to the right alias for
you.

### `gh` Authentication

The SSH keys only cover `git`. The `gh` CLI uses its own token, and
`gh auth switch` is global, so it can't follow the directory split. Instead, I
store each token in the Keychain and let direnv export the right one:

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

`gh` reads `GH_TOKEN` before its own config. Those two `.envrc` files sit
above the repos they apply to and are never tracked here. Run
`gh auth status` in each tree to confirm.

### Raycast's `⌘Space`

Spotlight's `⌘Space` is turned off declaratively in
`modules/system-defaults.nix`, but Nix can't reach into Raycast's own
settings. Launch Raycast once and set `⌘Space` under Raycast > Settings >
General > Raycast Hotkey.
