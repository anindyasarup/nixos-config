_:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "check";
    casks = [
      # needs a kernel/system extension nix can't install
      "focusrite-control"
      # not packaged for aarch64-darwin in nixpkgs
      "claude"
      "mullvad-vpn"
    ];
  };
}
