# Commenting out b/c it seems like this is getting run somehow? like what?
# {
#   description = "Portable neovim install, configured with lua, plugins via lazy";
#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#     flake-utils.url = "github:numtide/flake-utils";
#     dots = {
#       url = "github:benlubas/.dotfiles";
#       flake = false;
#     };
#   };
#
#   outputs =
#     { self, nixpkgs, flake-utils, ... }@inputs:
#     flake-utils.lib.eachDefaultSystem (
#       system:
#       let
#         pkgs = nixpkgs.legacyPackages.${system};
#         # there is no way that I can find to evaluate "$HOME" in a pure flake.
#         # so this can't work by default on macOS for example
#         binpath = pkgs.lib.makeBinPath (with pkgs; [
#           # Language Servers
#           lua-language-server
#           nodePackages.pyright
#
#           # Formatters
#           nodePackages.prettier
#           stylua
#
#           # Command Line Tools
#           fd
#           fzf
#           python3Packages.jupytext
#           ripgrep
#         ] ++ ["${inputs.dots}"]); # expose .dotfiles/bin to the path (for mx and tx telescope pickers)
#         neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
#           extraLuaPackages = p: [ p.magick ];
#           extraPython3Packages = p: with p; [
#             pynvim
#             jupyter-client
#             cairosvg
#             ipython
#             nbformat
#           ];
#           extraPackages = p: with p; [
#             imageMagick
#           ];
#           withNodeJs = true;
#           withRuby = true;
#           withPython3 = true;
#           # Source my lua config
#           wrapRc = true;
#           customRC = "execute 'luafile' stdpath('config') . '/init.lua'";
#         };
#
#         neovim-custom =
#           pkgs.wrapNeovimUnstable
#             (pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: {
#               buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
#             }))
#             (neovimConfig // {
#               # wrapperArgs = pkgs.lib.escapeShellArgs neovimConfig.wrapperArgs
#               wrapperArgs = pkgs.lib.escapeShellArgs neovimConfig.wrapperArgs + " " + ''
#                 --suffix LUA_CPATH ";" "${
#                   pkgs.lib.concatMapStringsSep ";" pkgs.lua51Packages.getLuaCPath
#                     (with pkgs.luajitPackages; [ magick ])
#                 }"'' + " " + ''
#                 --suffix LUA_PATH ";" "${
#                 pkgs.lib.concatMapStringsSep ";" pkgs.lua51Packages.getLuaPath
#                   (with pkgs.luajitPackages; [ magick ])
#                 }"''
#                 + " --prefix PATH : ${binpath}"; # Make the stuff in binpath available to neovim
#             });
#       in
#       {
#         packages = rec {
#           finalNvim = pkgs.writeShellApplication {
#             name = "nvim";
#             text = /*bash*/''
#               # if this path does not exists
#               # if [ ! -d "$HOME/github/.dotfiles/nvim" ]; then
#               #   export XDG_CONFIG_HOME="${inputs.dots}"
#               #   export XDG_DATA_HOME="${self}"
#               #   export XDG_STATE_HOME="${self}"
#               # fi
#               ${pkgs.lib.getExe neovim-custom} "$@"
#             '';
#           };
#           default = finalNvim;
#         };
#       }
#     );
# }
