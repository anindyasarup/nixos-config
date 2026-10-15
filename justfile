vars_override := "--override-input vars path:" + env_var("HOME") + "/.config/nix-config/vars.nix"

rebuild profile:
    sudo darwin-rebuild switch --flake .#{{ profile }} {{ vars_override }}

update:
    nix flake update

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
