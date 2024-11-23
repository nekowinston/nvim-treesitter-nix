final: prev:
let
  inherit (prev) lib;
  inherit (prev.neovimUtils) grammarToPlugin;

  nv = prev.callPackage ./_sources/generated.nix { };
  nvGrammars = lib.filterAttrs (_: v: v ? isGrammar && v.isGrammar == "true") nv;

  grammars = lib.mapAttrs' (
    _: meta:
    let
      language = lib.removePrefix "treesitter-grammar-" meta.pname;
      version = "0.0.0+rev=${builtins.substring 0 7 meta.version}";
    in
    lib.nameValuePair language (
      prev.tree-sitter.buildGrammar {
        inherit language version;
        inherit (meta) src;
        location = meta.location or null;
        generate = meta ? generate;
      }
    )
  ) nvGrammars;
  allGrammars = lib.attrValues grammars;

  builtGrammars =
    grammars
    // lib.concatMapAttrs (
      k: v:
      let
        replaced = lib.replaceStrings [ "_" ] [ "-" ] k;
      in
      {
        "treesitter-grammar-${k}" = v;
      }
      // lib.optionalAttrs (k != replaced) {
        ${replaced} = v;
        "treesitter-grammar-${replaced}" = v;
      }
    ) grammars;

  parsers = lib.mapAttrs (_: grammarToPlugin) grammars;
in
{
  vimPlugins = prev.vimPlugins // {
    nvim-treesitter = prev.vimPlugins.nvim-treesitter.overrideAttrs (
      finalAttrs: prevAttrs: {
        inherit (nv.nvim-treesitter) src version;
        passthru = prevAttrs.passthru // {
          inherit builtGrammars allGrammars grammarToPlugin;

          # Usage:
          # pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [ p.c p.java ... ])
          # or for all grammars:
          # pkgs.vimPlugins.nvim-treesitter.withAllGrammars
          withPlugins = f: finalAttrs.overrideAttrs { passthru.dependencies = f builtGrammars; };
          withAllGrammars = finalAttrs.overrideAttrs { passthru.dependencies = lib.attrValues parsers; };
        };
      }
    );
    nvim-treesitter-parsers = prev.vimPlugins.nvim-treesitter-parsers // parsers;
  };
  tree-sitter-grammars = prev.tree-sitter-grammars // grammars;
}
