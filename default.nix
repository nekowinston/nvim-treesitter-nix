{
  callPackage,
  lib,
  runCommand,
  tree-sitter,
  vimUtils,

  # test packages
  wrapNeovimUnstable,
  neovimUtils,
  neovim-unwrapped,

  # overrides
  grammars ? null,
}:
let
  nv = callPackage ./_sources/generated.nix { };

  # get all grammars from the nvfetcher output
  allGrammars = builtins.map (name: lib.removePrefix "treesitter-grammar-" name) (
    builtins.filter (name: (builtins.substring 0 19 name) == "treesitter-grammar-") (
      builtins.attrNames nv
    )
  );

  treesitterGrammars = builtins.map (
    name:
    let
      nvgrammar = nv."treesitter-grammar-${name}";
    in
    tree-sitter.buildGrammar {
      inherit (nvgrammar) src version;
      language = name;
      generate = lib.hasAttr "generate" nvgrammar;
      location = nvgrammar.location or null;
    }
  ) (if grammars == null then allGrammars else grammars);

  linkCommands = builtins.map (
    grammar:
    let
      name = lib.removeSuffix "-grammar" grammar.pname;
    in
    ''
      ln -sf ${grammar}/parser ./parser/${name}.so
      if [[ -d ${grammar}/queries ]] && [[ ! -d ./queries/${name} ]]; then
        ln -sf ${grammar}/queries ./queries/${name}
      fi
    ''
  ) treesitterGrammars;

  neovim = wrapNeovimUnstable neovim-unwrapped (
    neovimUtils.makeNeovimConfig { plugins = [ nvim-treesitter ]; }
  );

  nvim-treesitter = vimUtils.buildVimPlugin {
    inherit (nv.nvim-treesitter) pname version src;
    postPatch = lib.concatStrings linkCommands;

    passthru.tests.check-queries =
      runCommand "check-queries"
        {
          nativeBuildInputs = [ neovim ];
          env.CI = true;
        }
        ''
          touch $out
          export HOME=$(mktemp -d)
          ln -s ${nvim-treesitter}/CONTRIBUTING.md .

          nvim --headless "+luafile ${nvim-treesitter}/scripts/check-queries.lua" | tee log

          if grep -q Warning log || grep -q Error log; then
            echo "Error: warnings were emitted by the check"
            exit 1
          fi
        '';
  };
in
nvim-treesitter
