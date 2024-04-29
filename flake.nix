{
  description = "nvim-treesitter nightly builds with all grammars";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShellNoCC { packages = with pkgs; [ nvfetcher ]; };

        # shell used for updating the nvfetcher TOML from the latest neovim-treesitter
        generate-nvfetcher = pkgs.mkShellNoCC {
          packages = with pkgs; [
            nvfetcher
            (pkgs.callPackage ./neovim.nix { })
          ];
        };
      });

      overlays.default = final: prev: {
        vimPlugins = prev.vimPlugins // {
          nvim-treesitter = self.packages.${prev.hostPlatform.system}.default;
        };
      };

      packages = eachSystem (pkgs: {
        default = pkgs.callPackage ./default.nix { };
      });

      formatter = eachSystem (pkgs: pkgs.nixfmt-rfc-style);
    };
}
