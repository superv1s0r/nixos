{ pkgs, ... }:
let
  # 10 is the current LTS. VERIFY: sdk_8_0 may be dropped from nixpkgs after .NET 8 EOL (Nov 2026).
  dotnet = with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 sdk_10_0 ];
in
{
  home.packages = with pkgs; [
    dotnet
    jetbrains.rider
    python3
    uv
    # Mason / treesitter build deps
    gcc
    gnumake
    nodejs
    ripgrep
    fd
    unzip
    tree-sitter # :TSInstall on nvim-treesitter main
  ];

  # Rider and `dotnet` tools locate the SDK via DOTNET_ROOT.
  home.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";
  home.sessionPath = [ "$HOME/.dotnet/tools" ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "miller";
      user.email = "you@example.com"; # TODO: set your git email
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
