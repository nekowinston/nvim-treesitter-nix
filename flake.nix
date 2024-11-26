{
  description = "nvim-treesitter nightly builds with all grammars";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem =
        fn:
        lib.genAttrs systems (
          system:
          fn (
            import nixpkgs {
              config = { };
              overlays = [ self.overlays.default ];
              inherit system;
            }
          )
        );
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            nvfetcher
            (wrapNeovimUnstable neovim-unwrapped (
              neovimUtils.makeNeovimConfig { plugins = with vimPlugins; [ nvim-treesitter.withAllGrammars ]; }
            ))
          ];
        };
        # ci devShell with built-in grammars only
        ci = pkgs.mkShellNoCC {
          packages = with pkgs; [
            nvfetcher
            (wrapNeovimUnstable neovim-unwrapped (
              neovimUtils.makeNeovimConfig { plugins = with vimPlugins; [ nvim-treesitter ]; }
            ))
          ];
        };
      });

      overlays.default = import ./overlay.nix;

      packages = eachSystem (pkgs: {
        nvim-treesitter = pkgs.vimPlugins.nvim-treesitter;
      });

      formatter = eachSystem (pkgs: pkgs.nixfmt-rfc-style);
    };
}
