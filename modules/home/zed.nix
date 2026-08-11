{
  pkgs,
  ...
}:

{
  programs.zed-editor = {
    enable = true;
    extraPackages = [
      pkgs.nixd
      pkgs.nixfmt
    ];
    extensions = [
      "nix"
      "toml"
      "rumdl"
    ];
    userSettings = {
      terminal = {
        shell = {
          with_arguments = {
            program = "${pkgs.bashInteractive}/bin/bash";
            args = [ "-l" ];
          };
        };
      };
      autosave = {
        after_delay = {
          milliseconds = 500;
        };
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
        anthropic_retention = false;
      };
      base_keymap = "JetBrains";
      ui_font_size = 21;
      buffer_font_size = 20;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      markdown_preview = {
        limit_content_width = true;
        max_width = 1100;
      };
      format_on_save = "on";
      relative_line_numbers = "enabled";
    };
    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "ctrl-`" = "workspace::NewCenterTerminal";
        };
      }
    ];
  };
}
