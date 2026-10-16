{ pkgs, ... }:
{
  # Daemon + GUI. Mullvad's DNS leak protection works best with systemd-resolved.
  services.mullvad-vpn = {
    enable = true;
    gui.enable = true;
  };
  services.resolved.enable = true;

  # Sets up dumpcap capabilities so captures work without root (needs the wireshark group).
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # Qt GUI (default is the CLI-only package)
  };
}
