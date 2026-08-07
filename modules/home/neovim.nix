{
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    plugins = [
      {
        plugin = pkgs.vimPlugins.onedark-nvim;
        type = "lua";
        config = ''
          require('onedark').setup({ style = 'dark' })
          require('onedark').load()
        '';
      }
      {
        plugin = pkgs.vimPlugins.indent-blankline-nvim;
        type = "lua";
        config = ''
          require("ibl").setup()
        '';
      }
    ];

    initLua = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.cursorline = true
      vim.opt.colorcolumn = "80"

      vim.opt.clipboard = "unnamedplus"

      vim.opt.ignorecase = true
      vim.opt.smartcase = true

      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
    '';
  };
}
