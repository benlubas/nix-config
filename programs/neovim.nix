{ lib, pkgs, neovim-nightly-src, ... }:

let
  binpath = lib.makeBinPath (with pkgs; [
    lua-language-server
    pyright
    nil # nix-ls

    stylua
    nodePackages.prettier
    nixfmt-rfc-style

    lua5_1
    luajit # required for luarocks.nvim to work
    luarocks

    # I can't install this with the rest of the python packages b/c it's used from path
    python3Packages.jupytext
  ]);
  neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
    extraLuaPackages = p: [ p.magick ]; # I can't have luarocks.nvim install it b/c that version will not find imagemagick c binary
    extraPython3Packages = p:
      with p; [
        pynvim
        jupyter-client
        cairosvg
        ipython
        nbformat
      ];
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    # https://github.com/NixOS/nixpkgs/issues/211998
    luaRcContent = "vim.cmd.source(('~/.config/%s/init.lua'):format(vim.env.NVIM_APPNAME or 'nvim'))";
  };
  fullConfig = (neovimConfig // {
    wrapperArgs = lib.escapeShellArgs neovimConfig.wrapperArgs
      + " --prefix PATH : ${binpath}";
  });
in {
  nixpkgs.overlays = [
    (_: super: {
      # neovim-nightly = pkgs.wrapNeovimUnstable
      #   (super.neovim-unwrapped.overrideAttrs (oldAttrs: {
      #     buildInputs = oldAttrs.buildInputs ++ [ super.tree-sitter ];
      #     src = neovim-nightly-src;
      #   })) fullConfig;
      neovim-stable = pkgs.wrapNeovimUnstable
        (super.neovim-unwrapped.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ super.tree-sitter ];
        })) fullConfig;
    })
  ];

  environment.systemPackages = with pkgs; [
    neovim-stable
    # nightly fails to build right now
    # (writeScriptBin "nvim_nightly" ''${neovim-nightly}/bin/nvim "$@"'')
  ];
}
