# 7. Scheduled nix-collect-garbage runs as a launchd daemon, not a user agent

Status: Accepted

Files: modules/nix-gc.nix

The weekly, unattended version of `just cleanup`'s two steps runs under
`launchd.daemons`, not `launchd.user.agents`: both commands need root
(`/nix/var/nix/profiles/system` is root-owned), and a user agent has no TTY
for sudo to prompt on. `launchd.daemons` already run as root, so the script
needs no sudo at all. Paths inside the script are absolute because launchd
daemons get a minimal PATH, not the interactive shell's; the two used are
Determinate's own stable profile symlinks, not a nixpkgs-provided `nix`
package.
