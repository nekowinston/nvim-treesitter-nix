#!/usr/bin/env nix
#!nix develop .#ci --command bash
set -euxo pipefail

nvfetcher -f '^nvim-treesitter$'
echo 'Updating nvfetcher.toml...'
nvim -l ./generate-nvfetcher.lua
echo 'Fetching new plugin versions...'
nvfetcher
