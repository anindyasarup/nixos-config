vars_override := "--override-input vars path:" + env_var("HOME") + "/.config/nix-config/vars.nix"

rebuild profile:
    sudo darwin-rebuild switch --flake .#{{ profile }} {{ vars_override }}

update:
    #!/usr/bin/env bash
    set -euo pipefail
    cp flake.lock flake.lock.bak
    nix flake update
    if nix build .#darwinConfigurations.personal.pkgs.zed-editor {{ vars_override }} --dry-run 2>&1 | grep -q "will be built"; then
        echo "zed-editor needs a local build at the new tip; leaving flake.lock as it was."
        mv flake.lock.bak flake.lock
        exit 1
    fi
    rm flake.lock.bak
    echo "flake.lock bumped to tip; zed-editor is cached and ready to pull."

preview profile:
    nix build .#darwinConfigurations.{{ profile }}.system {{ vars_override }} --dry-run

undo-update:
    git checkout HEAD -- flake.lock

check:
    nix flake check {{ vars_override }}

generations:
    sudo darwin-rebuild --list-generations

rollback:
    sudo darwin-rebuild --rollback

cleanup keep="4":
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +{{keep}}
    sudo nix-collect-garbage

fmt:
    nix fmt {{ vars_override }} -- .

lint:
    statix fix .
    statix check .
