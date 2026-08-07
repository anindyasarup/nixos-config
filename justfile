# `just rebuild` is the one command that matters.

# Real identity lives outside the repo; every recipe below points the
# flake's `vars` input at it explicitly (see flake.nix and README's
# bootstrap steps), rather than an implicit, impure env-var lookup. Resolved
# here (as the invoking user) so it's still correct even where `sudo`
# follows, unlike an in-recipe $HOME read under sudo.
vars_override := "--override-input vars path:" + env_var("HOME") + "/.config/nix-config/vars.nix"

# Apply the configuration
rebuild:
    sudo darwin-rebuild switch --flake .#default {{ vars_override }}

# Bump nixpkgs to tip, but only keep the bump if zed-editor (the one package
# here big enough that a local compile actually matters) is already cached
# and ready to pull at the new tip; otherwise flake.lock is left exactly as
# it was, and it's worth just trying again another day. No per-package
# pinning: `--dry-run` never builds anything, it only evaluates and asks
# cache.nixos.org what it already has, so this check is cheap even though
# it looks like a full build.
update:
    #!/usr/bin/env bash
    set -euo pipefail
    cp flake.lock flake.lock.bak
    nix flake update
    if nix build .#darwinConfigurations.default.pkgs.zed-editor {{ vars_override }} --dry-run 2>&1 | grep -q "will be built"; then
        echo "zed-editor needs a local build at the new tip; leaving flake.lock as it was."
        mv flake.lock.bak flake.lock
        exit 1
    fi
    rm flake.lock.bak
    echo "flake.lock bumped to tip; zed-editor is cached and ready to pull."

# After `just update`: show what needs a local build vs what's cached and
# ready to pull. If something big (e.g. zed-editor) shows under "will be
# built", either accept the local build or run `just undo-update` and try
# again in a day.
preview:
    nix build .#darwinConfigurations.default.system {{ vars_override }} --dry-run

# Revert the last update (e.g. after keeping a bump you later regret): restores flake.lock
undo-update:
    git checkout HEAD -- flake.lock

# Evaluate everything without applying
check:
    nix flake check {{ vars_override }}

# List system generations (past activations, newest last)
generations:
    sudo darwin-rebuild --list-generations

# Roll back to the previous system generation (undoes the last `just rebuild`'s
# activation, as opposed to `undo-update`, which reverts the lock file before
# a rebuild even happens)
rollback:
    sudo darwin-rebuild --rollback

# Delete all but the last `keep` generations (default 4: current + 3 before
# it), then actually reclaim the disk space. `+N` also keeps anything newer
# than current, in case a rollback happened. Deleting the registration alone
# frees nothing until the collect-garbage step after it.
cleanup keep="4":
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +{{keep}}
    sudo nix-collect-garbage

# Format all .nix files (uses the flake's `formatter` output)
fmt:
    nix fmt {{ vars_override }} -- .

# Lint .nix files for antipatterns (dead code, unnecessary rec, etc.):
# auto-applies what statix can fix, then reports whatever's left. Relies on
# direnv (`.envrc`) putting statix on PATH, same as `update` relies on it for
# uv, deliberately not `nix develop -c`: this repo's justfiles shouldn't
# depend on Nix specifically to run, only on direnv already being allowed.
lint:
    statix fix .
    statix check .
