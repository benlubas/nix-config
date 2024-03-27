{ lib, pkgs, neovim-nightly-src, ... }:

let
  binpath = lib.makeBinPath (with pkgs; [
    lua-language-server
    stylua
    lua # required for luarocks.nvim to work
    nil # nix-ls
    nixfmt

    nodePackages.prettier
    nodePackages.pyright

    # I can't install this with the rest of the python packages b/c this needs to be in path
    python3Packages.jupytext
  ]);
  neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
    extraLuaPackages = p: [ p.magick ];
    extraPython3Packages = p:
      with p; [
        pynvim
        jupyter-client
        cairosvg
        ipython
        nbformat
      ];
    extraPackages = p: with p; [ imageMagick ];
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    # https://github.com/NixOS/nixpkgs/issues/211998
    customRC = "luafile ~/.config/nvim/init.lua";
  };
  fullConfig = (neovimConfig // {
    wrapperArgs = lib.escapeShellArgs neovimConfig.wrapperArgs
      + " --prefix PATH : ${binpath}";
  });
in {
  nixpkgs.overlays = [
    (_: super: {
      neovim-nightly = pkgs.wrapNeovimUnstable
        (super.neovim-unwrapped.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ super.tree-sitter ];
          src = neovim-nightly-src;
        })) fullConfig;
      neovim-stable = pkgs.wrapNeovimUnstable
        (super.neovim-unwrapped.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ super.tree-sitter ];
        })) fullConfig;
    })
  ];

  environment.systemPackages = with pkgs; [
    neovim-nightly
    (writeScriptBin "nvim_stable" ''${neovim-stable}/bin/nvim "$@"'')
  ];
}
