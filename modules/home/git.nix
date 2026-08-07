{
  vars,
  pkgs,
  ...
}:

{
  programs.git = {
    enable = true;
    hooks.pre-commit = pkgs.writeShellScript "gitleaks-pre-commit" ''
      ${pkgs.gitleaks}/bin/gitleaks git --pre-commit --staged
    '';
    settings = {
      init.defaultBranch = "main";
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
