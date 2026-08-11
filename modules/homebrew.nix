_:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "check";
    casks = [
      "focusrite-control"
      "mullvad-vpn"
      "claude"
      "whatsapp"
    ];
  };
}
