_:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "check";
    casks = [
      "mullvad-vpn"
    ];
  };
}
