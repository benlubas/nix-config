{ lib, pkgs, neovimUtils, wrapNeovimUnstable, ... }:

let
  config = pkgs.neovimUtils.makeNeovimConfig {
    extraLuaPackages = p: [ p.magick ];
    extraPython3Packages = p: with p; [
      pynvim
      jupyter-client
      cairosvg
      # pnglatex # I think this doesn't work, I wonder if I have to package a latex distro with my neovim. that would suck
      ipython
      nbformat
    ];
    extraPackages = p: with p; [
      imageMagick
      # lua-language-server # this doesn't work
    ];
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    # https://github.com/NixOS/nixpkgs/issues/211998
    customRC = "luafile ~/.config/nvim/init.lua";
  };
in {
  nixpkgs.overlays = [
    (_: super: {
      neovim-custom = pkgs.wrapNeovimUnstable
        (super.neovim-unwrapped.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ super.tree-sitter ];
        })) config;
    })
  ];

  environment.systemPackages = with pkgs; [
    neovim-custom

    # I'm installing language servers here, they will be installed globally, b/c idk how to just
    # install them so that neovim can see them
    lua-language-server
    nodePackages.prettier
    nodePackages.pyright
    stylua

    iruby
    python3Packages.ilua

    # I can't install this with the rest of the python packages b/c this needs to be in path
    python3Packages.jupytext
  ];
}
