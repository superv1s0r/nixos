{ config, lib, pkgs, ... }:
let
  # Stop the session target on logout so kanshi/swayidle/waybar don't linger.
  river-session = pkgs.writeShellScript "river-session" ''
    river
    systemctl --user stop river-session.target
  '';

  # Login entry for ReGreet, which reads wayland-sessions/*.desktop.
  river-session-entry = (pkgs.writeTextDir "share/wayland-sessions/river-session.desktop" ''
    [Desktop Entry]
    Name=River
    Comment=river compositor (with session target)
    Exec=${river-session}
    Type=Application
  '').overrideAttrs { passthru.providedSessions = [ "river-session" ]; };
in
{
  # river 0.3.x was renamed to river-classic; the binary is still `river`.
  programs.river-classic.enable = true;

  # Graphical greeter on greetd (runs inside cage). Remembers the last user and session.
  services.displayManager.sessionPackages = [ river-session-entry ];
  services.displayManager.defaultSession = "river-session";
  # Same command programs.regreet sets, but first force 1920x1080 on the VM's
  # output (kanshi only runs after login). On the laptop wlr-randr just fails.
  services.greetd.settings.default_session.command = lib.mkForce (toString [
    "${pkgs.cage}/bin/cage -s -mlast -- ${pkgs.bash}/bin/sh -c"
    "'${pkgs.wlr-randr}/bin/wlr-randr --output Virtual-1 --mode 1920x1080 || true;"
    "exec ${lib.getExe config.programs.regreet.package}'"
  ]);
  programs.regreet = {
    enable = true;
    theme = { name = "Adwaita-dark"; package = pkgs.gnome-themes-extra; };
    font = { name = "FiraCode Nerd Font"; size = 12; package = pkgs.nerd-fonts.fira-code; };
    settings = {
      # Copy any image here (root-owned; the greeter can't read ~/Pictures).
      background = { path = "/etc/greetd/background"; fit = "Cover"; };
      GTK.application_prefer_dark_theme = true;
      appearance.greeting_msg = "Welcome back";
      widget.clock = { format = "%a %d %b  %H:%M"; resolution = "1s"; };
    };
    extraCss = ''
      window { background-color: #1e1e2e; }
      frame, .background > box > frame {
        background-color: rgba(30, 30, 46, 0.85);
        border: 1px solid #45475a;
        border-radius: 14px;
        padding: 18px;
      }
      button.suggested-action { background: #89b4fa; color: #1e1e2e; border-radius: 8px; }
      entry { border-radius: 8px; }
    '';
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
