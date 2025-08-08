{
  lib,
  pkgs,
  neovim-nightly-overlay,
  inputs,
  ...
}:

let
  binpath = lib.makeBinPath (
    with pkgs;
    [
      lua-language-server
      typescript-language-server
      pyright
      nil # nix-ls
      gopls
      vscode-langservers-extracted # css, html, json, eslint

      stylua
      nodePackages.prettier
      nixfmt-rfc-style
      taplo # toml formatter

      lua5_1
      luajit # required for luarocks.nvim to work
      luarocks

      # I can't install this with the rest of the python packages b/c it's used from path
      python3Packages.jupytext
    ]
  );
  neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
    extraLuaPackages = p: [ p.magick ]; # I can't have luarocks.nvim install it b/c that version will not find imagemagick c binary
    extraPython3Packages =
      p: with p; [
        pynvim
        jupyter-client
        cairosvg
        ipython
        nbformat
      ];
    plugins = with pkgs.vimPlugins; [
      # the below is preferable to `nvim-treesitter.withAllGrammars` for performance reasons
      {
        plugin = pkgs.symlinkJoin {
          name = "nvim-treesitter";
          paths = [
            nvim-treesitter.withAllGrammars
            nvim-treesitter.withAllGrammars.dependencies
          ];
        };
        optional = false;
      }
    ];
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    luaRcContent = /*lua*/ ''
      vim.g.nix_packdir = "${pkgs.vimUtils.packDir pkgs.neovim-stable.passthru.packpathDirs}"
      vim.cmd.source(('~/.config/%s/init.lua'):format(vim.env.NVIM_APPNAME or 'nvim'))
    '';
  };
  fullConfig = (
    neovimConfig
    // {
      wrapperArgs = lib.escapeShellArgs neovimConfig.wrapperArgs + " --prefix PATH : ${binpath}";
    }
  );
in
{
  nixpkgs.overlays = [
    (_: super: {
      neovim-nightly =
        pkgs.wrapNeovimUnstable (neovim-nightly-overlay.packages.${pkgs.system}.default.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [super.tree-sitter];
        }))
        fullConfig;
      neovim-stable = pkgs.wrapNeovimUnstable super.neovim-unwrapped fullConfig;
    })
    (import ./treesitterMain.nix { inherit inputs; })
  ];

  environment.systemPackages = with pkgs; [
    neovim-stable
    # nightly fails to build right now
    (writeScriptBin "nightly" ''${neovim-nightly}/bin/nvim "$@"'')
  ];
}
