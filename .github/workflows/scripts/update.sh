#!/usr/bin/env nix
#!nix develop .# --command bash
nvfetcher -f '^nvim-treesitter$'
echo 'Updating nvfetcher.toml...'
nvim -l ./generate-nvfetcher.lua
echo 'Fetching new plugin versions...'
nvfetcher
