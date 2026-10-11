{ ... }:
{
  imports = [
    ./shell.nix
    ./dev.nix
    ./river.nix
    ./idle.nix
    ./monitors.nix
    ./apps.nix
  ];

  home.username = "miller";
  home.homeDirectory = "/home/miller";
  home.stateVersion = "26.05"; # same as system.stateVersion; never change after install
}
