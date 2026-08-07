# 5. Redirect direnv's build cache out of every project directory

Status: Accepted

Files: modules/home/shell.nix

direnv's default `direnv_layout_dir` is `$PWD/.direnv`, which means every
nix-direnv project needs its own `.direnv/` gitignore entry. The `stdlib`
override redirects it to `$XDG_CACHE_HOME/direnv/layouts/<hash of $PWD>`
instead, so no project needs to gitignore anything for direnv's sake. See
https://github.com/direnv/direnv/wiki/customizing-cache-location.
