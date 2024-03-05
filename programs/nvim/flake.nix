{
  description = "Portable neovim install, configured with lua, plugins via lazy";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dots = {
      url = "github:benlubas/.dotfiles";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # there is no way that I can find to evaluate "$HOME" in a pure flake.
        # so this can't work by default on macOS for example
        localDotsPath = "/home/benlubas/github/.dotfiles";
        dotsPath = if builtins.pathExists localDotsPath then localDotsPath else "${inputs.dots}";
        binpath = nixpkgs.lib.makeBinPath (with pkgs; [
          # Language Servers
          lua-language-server
          nodePackages.pyright

          # Formatters
          nodePackages.prettier
          stylua

          # Command Line Tools
          fd
          fzf
          python3Packages.jupytext
          ripgrep
        ] ++ [dotsPath]);
        neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
          extraLuaPackages = p: [ p.magick ];
          extraPython3Packages = p: with p; [
            pynvim
            jupyter-client
            cairosvg
            ipython
            nbformat
          ];
          extraPackages = p: with p; [
            imageMagick
          ];
          withNodeJs = true;
          withRuby = true;
          withPython3 = true;
          # Source my lua config
          customRC = "luafile ${dotsPath}/nvim/init.lua";
        };

        neovim-custom =
          pkgs.wrapNeovimUnstable
            (pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: {
              buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
            }))
            (neovimConfig // {
              wrapperArgs = nixpkgs.lib.escapeShellArgs neovimConfig.wrapperArgs
                + " --prefix PATH : ${binpath}"; # Make the stuff in binpath available to neovim
            });
      in
      {
        packages = {
          default = neovim-custom;
        };
      }
    );
}
