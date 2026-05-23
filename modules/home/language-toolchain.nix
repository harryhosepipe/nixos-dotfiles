{ ... }:
{
  imports = [
    ./language-servers.nix

    # Choose exactly one Neovim module:
    # - plain Neovim lets plugins live under ~/.local/share/nvim
    # - nixCats packages the Neovim runtime and plugins with Nix
    ./neovim.nix
    # ./neovim-nixcats.nix
  ];
}
