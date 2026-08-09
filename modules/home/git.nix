{
  config,
  lib,
  vars,
  pkgs,
  ...
}:

let
  hookName = "pre-commit";
  hooksSubdir = "git/hooks";

  globalChecks = [
    {
      package = pkgs.gitleaks;
      args = [
        "git"
        "--pre-commit"
        "--staged"
      ];
    }
  ];

  runChecks = lib.concatMapStringsSep "\n" (
    check: "${lib.getExe check.package} ${lib.escapeShellArgs check.args}"
  ) globalChecks;

  preCommit = pkgs.writeShellScript "git-hook-${hookName}" ''
    set -eu

    ${runChecks}

    common_dir=$(${lib.getExe config.programs.git.package} rev-parse --git-common-dir)
    for candidate in "$common_dir/hooks/${hookName}" ".husky/_/${hookName}"; do
      if [ -x "$candidate" ]; then
        exec "$candidate" "$@"
      fi
    done
  '';
in
{
  xdg.configFile."${hooksSubdir}/${hookName}".source = preCommit;

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      core.hooksPath = "${config.xdg.configHome}/${hooksSubdir}";
      url."git@github.com:".pushInsteadOf = "https://github.com/";

      commit.verbose = true;
      pull.rebase = true;
      fetch.prune = true;

      alias = {
        oops = "reset --soft HEAD~1";
        fix = "commit --amend --no-edit";
      };
    };

    includes = [
      {
        condition = "gitdir:~/Development/personal/";
        contents = {
          user = {
            name = vars.git.personal.name;
            email = vars.git.personal.email;
          };
          url."git@github.com-personal:".insteadOf = "git@github.com:";
        };
      }
      {
        condition = "gitdir:~/Development/work/";
        contents = {
          user = {
            name = vars.git.work.name;
            email = vars.git.work.email;
          };
          url."git@github.com-work:".insteadOf = "git@github.com:";
        };
      }
    ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com-personal" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519_personal";
      IdentitiesOnly = "yes";
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
      HostKeyAlias = "github.com";
    };
    settings."github.com-work" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519_work";
      IdentitiesOnly = "yes";
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
      HostKeyAlias = "github.com";
    };
  };
}
