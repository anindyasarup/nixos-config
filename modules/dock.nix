{ vars, ... }:

{
  system.defaults.dock = {
    autohide = true;
    tilesize = 67;
    magnification = true;
    largesize = 73;
    show-recents = false;
    wvous-br-corner = 14;

    persistent-apps = [
      { app = "/Applications/Safari.app"; }
      { app = "${vars.homeDirectory}/Applications/Home Manager Apps/Ghostty.app"; }
    ];
  };
}
