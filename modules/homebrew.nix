_:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    casks = [
      "focusrite-control"
      "claude"
      "whatsapp"
      "brave-browser"
    ];
  };
}
