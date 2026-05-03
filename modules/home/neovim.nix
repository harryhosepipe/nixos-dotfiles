{
  config,
  inputs,
  pkgs,
  ...
}: let
  utils = inputs.nixCats.utils;
  buildVimPlugin = pkgs.vimUtils.buildVimPlugin;
  nvimFloat = buildVimPlugin {
    pname = "nvim-float";
    version = "unstable";
    src = inputs."nvim-float";
  };
  nvimColorpicker = buildVimPlugin {
    pname = "nvim-colorpicker";
    version = "unstable";
    src = inputs.nvim-colorpicker;
    dependencies = [nvimFloat];
  };
in {
  imports = [
    inputs.nixCats.homeModule
  ];

  nixCats = {
    enable = true;

    # This overlay gives nixCats access to the normal plugin set from nixpkgs.
    addOverlays = [
      (utils.standardPluginOverlay inputs)
    ];

    # Keep one clear Neovim package for this home setup.
    packageNames = ["mainNvim"];

    # The Lua config lives in the repo like a normal Neovim folder.
    luaPath = ../../config/nvim;

    categoryDefinitions.replace = {pkgs, ...}: {
      lspsAndRuntimeDeps.general = with pkgs; [
        fd
        ripgrep
        wl-clipboard
        git
        nil
        alejandra
        lua-language-server
        vscode-langservers-extracted
        typescript-language-server
        typescript
        zls
        rust-analyzer
        clang-tools
        c3-lsp
        serve-d
        haskell-language-server
        fourmolu
        gopls
        templ
        phpactor
        php84Packages.php-cs-fixer
      ];

      startupPlugins.general = with pkgs.vimPlugins; [
        plenary-nvim
        nvim-treesitter
        (nvim-treesitter.withPlugins (
          grammars:
            with grammars; [
              bash
              c
              c3
              css
              d
              dockerfile
              gitignore
              go
              haskell
              html
              javascript
              json
              lua
              markdown
              markdown_inline
              nix
              php
              python
              query
              rust
              templ
              toml
              tsx
              typescript
              vim
              vimdoc
              yaml
              zig
            ]
        ))
        nvim-treesitter-textobjects
        nvim-treesitter-context
        nvim-cmp
        cmp-nvim-lsp
        cmp-path
        cmp-buffer
        telescope-nvim
        harpoon2
        nui-nvim
        nvimFloat
        nvimColorpicker
        neo-tree-nvim
        tokyonight-nvim
        which-key-nvim
        lualine-nvim
        nvim-highlight-colors
        orgmode
        vim-fugitive
        undotree
        vim-oscyank
        flash-nvim
      ];
    };

    packageDefinitions.replace = {
      mainNvim = {...}: {
        settings = {
          # Read the live ~/.config/nvim folder so Lua edits show up right away.
          wrapRc = false;
          configDirName = "nvim";
          unwrappedCfgPath = "${config.home.homeDirectory}/.config/nvim";
          aliases = [
            "nvim"
            "vim"
            "vi"
          ];
        };

        categories = {
          general = true;
        };
      };
    };
  };
}
