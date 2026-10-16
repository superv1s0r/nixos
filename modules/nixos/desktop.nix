{ pkgs, ... }:
let
  # Stop the session target on logout so kanshi/swayidle/waybar don't linger.
  river-session = pkgs.writeShellScript "river-session" ''
    river
    systemctl --user stop river-session.target
  '';
in
{
  # river 0.3.x was renamed to river-classic; the binary is still `river`.
  programs.river-classic.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${river-session}";
  };

  security.pam.services.swaylock = { }; # lets swaylock verify the password
  security.polkit.enable = true; # agent runs as a user service (home/apps.nix)
  services.blueman.enable = true; # bluetooth tray/GUI

  xdg.portal = {
    enable = true;
    wlr.enable = true; # screen sharing
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # file pickers
    config.common.default = [ "wlr" "gtk" ];
  };

  security.rtkit.enable = true; # realtime scheduling for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Electron/Chromium native Wayland

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];
}
