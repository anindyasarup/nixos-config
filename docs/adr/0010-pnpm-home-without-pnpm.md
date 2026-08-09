# 10. `PNPM_HOME` stays set globally even though `pnpm` isn't installed globally

Status: Accepted

Files: `modules/home/shell.nix`

`pnpm` was dropped from `home.packages` for the same reason `just` and `uv`
never went in: it's project-scoped tooling, so it belongs in whichever
project's devShell actually needs it, not on every directory's `PATH`.

`PNPM_HOME` and its `sessionPath` entry (`~/Library/pnpm`) deliberately
stayed behind, which looks like dead config for a package that no longer
exists. It isn't. `PNPM_HOME` is read by whatever `pnpm` is on `PATH` at the
time, not by this config: it names the directory pnpm uses for globally
installed binaries. Setting it once at the session level means every
project-scoped pnpm resolves to the same location, instead of each devShell
inheriting whatever default pnpm picks in that context. The `sessionPath`
entry is what makes anything installed there runnable afterward.

Defining it globally is also the only place it can go. Session variables are
a login-shell concern, and a per-project devShell can't retroactively set one
for a shell that already started; duplicating the export across every
JavaScript project's devShell would be the alternative, and they would all
have to agree on the same value for a shared global store to work at all.

The cost of keeping it is one unused environment variable on machines that
never run pnpm, which is nothing. The cost of removing it is a per-project
store split that only shows up as confusing behaviour much later.
