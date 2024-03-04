{ lib, pkgs, neovimUtils, wrapNeovimUnstable, ... }:

let
  binpath = lib.makeBinPath (with pkgs; [
    lua-language-server
    stylua

    nodePackages.prettier
    nodePackages.pyright

    # I can't install this with the rest of the python packages b/c this needs to be in path
    python3Packages.jupytext
  ]);
  neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
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
        })) (neovimConfig // {
          wrapperArgs = lib.escapeShellArgs neovimConfig.wrapperArgs
           + " --prefix PATH : ${binpath}";
        });
    })
  ];

  environment.systemPackages = with pkgs; [
    neovim-custom
  ];
}
