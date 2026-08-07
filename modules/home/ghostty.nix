{
  pkgs,
  ...
}:

{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      auto-update = "off";

      command = "${pkgs.bashInteractive}/bin/bash -l";

      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 22;
      font-thicken = true;
      font-thicken-strength = 255;

      clipboard-read = "allow";

      macos-option-as-alt = true;

      window-subtitle = "working-directory";
      macos-non-native-fullscreen = false;

      notify-on-command-finish = "unfocused";
      notify-on-command-finish-action = "notify";

      theme = "Atom One Dark";
    };
  };
}
