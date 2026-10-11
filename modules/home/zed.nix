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
      "oxc"
      "zig"
      "typst"
      "csharp"
      "charmed-icons"
    ];
    userSettings = {
      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
          formatter = {
            external = {
              command = "nixfmt";
              arguments = [ ];
            };
          };
        };
        JSON = {
          indent_guides = {
            coloring = "indent_aware";
            background_coloring = "indent_aware";
          };
        };
      };
      terminal = {
        shell = {
          program = "${pkgs.bashInteractive}/bin/bash";
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
      icon_theme = "Base Charmed Icons";
      disable_ai = true;
      cli_default_open_behavior = "new_window";
      markdown_preview = {
        limit_content_width = true;
        max_width = 1100;
      };
      format_on_save = "on";
      relative_line_numbers = "enabled";
      mouse_wheel_zoom = true;
    };
    mutableUserSettings = false;
    mutableUserKeymaps = false;
    mutableUserTasks = false;
    mutableUserDebug = false;
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
