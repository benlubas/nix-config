# from https://github.com/NixOS/nixpkgs/issues/415438#issuecomment-3186621192
{ inputs, ... }:
final: prev:
{
  vimPlugins = prev.vimPlugins.extend (
    final': prev': {
      nvim-treesitter = prev'.nvim-treesitter.overrideAttrs (old: rec {
        src = inputs.nvim-treesitter;
        name = "${old.pname}-${src.rev}";
        postPatch = "";
        # ensure runtime queries get linked to RTP (:TSInstall does this too)
        buildPhase = "
          mkdir -p $out/queries
          cp -a $src/runtime/queries/* $out/queries
        ";
        nvimSkipModules = [ "nvim-treesitter._meta.parsers" ];
      });
    }
  );
}
