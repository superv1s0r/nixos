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
    ../../modules/nixos/apps.nix
  ];

  networking.hostName = "miller-lnv";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";
  # Same as on Ubuntu: 24h clock, dd/mm/yyyy, metric.
  i18n.extraLocaleSettings = {
    LC_TIME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
  };

  programs.zsh.enable = true; # needed system-wide for a zsh login shell
  users.users.miller = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "wireshark" ];
  };

  environment.systemPackages = with pkgs; [ git vim wget curl btrfs-progs ];

  # Release you install from; never change after install.
  system.stateVersion = "26.05";
}
