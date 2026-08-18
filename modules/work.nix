{ vars, ... }:

{
  homebrew.casks = [
  ];

  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Microsoft Teams.app"; }
    { app = "/Applications/Microsoft Outlook.app"; }
    { app = "${vars.homeDirectory}/Applications/Home Manager Apps/Slack.app"; }
  ];

  home-manager.users.${vars.username}.imports = [ ./home/work.nix ];
}
