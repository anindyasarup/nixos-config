_:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "check";
    casks = [
      "focusrite-control"
      "claude"
      "whatsapp"
    ];
  };
}
