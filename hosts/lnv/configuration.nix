{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/hardware.nix
    ../../modules/nixos/btrfs.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/power.nix
    ../../modules/nixos/dev.nix
    ../../modules/nixos/nix.nix
  ];

  networking.hostName = "miller-lnv";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.zsh.enable = true; # needed system-wide for a zsh login shell
  users.users.miller = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  };

  environment.systemPackages = with pkgs; [ git vim wget curl btrfs-progs ];

  # Release you install from; never change after install.
  system.stateVersion = "26.05";
}
