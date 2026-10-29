{ pkgs, ... }:
let
  # confirm "Shut down" systemctl poweroff: runs the command only if "Yes" is picked.
  confirm = pkgs.writeShellScript "confirm" ''
    label=$1; shift
    choice=$(printf 'No\nYes\n' | ${pkgs.fuzzel}/bin/fuzzel --dmenu --lines 2 --width 20 --prompt "$label? ")
    [ "$choice" = Yes ] && exec "$@"
  '';
in
{
  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    wlr-randr
    pavucontrol
    networkmanagerapplet
    keepassxc

    fastfetch
    telegram-desktop
    spotify
    vlc
    reaper
    feather # Monero wallet
    postman
    burpsuite
    jetbrains.pycharm # unified PyCharm (Community was merged into it)
  ];

  # Without a cursor theme some apps show a tiny or missing cursor.
  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
  };
  gtk = {
    enable = true;
    colorScheme = "dark";
  };

  # No DE means no polkit agent; without one, GUI password prompts silently fail.
  systemd.user.services.polkit-gnome-agent = {
    Unit = {
      Description = "polkit authentication agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.firefox.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {
      font.normal.family = "FiraCode Nerd Font";
      font.size = 11;
      window.padding = { x = 6; y = 6; };
    };
  };

  programs.fuzzel = {
    enable = true;
    settings.main = {
      font = "FiraCode Nerd Font:size=11";
      terminal = "alacritty";
    };
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 6;
      font = "FiraCode Nerd Font 10";
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true; # started by river-session.target
    settings.main = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 6;
      margin-top = 4;
      margin-left = 6;
      margin-right = 6;
      modules-left = [ "river/tags" ];
      modules-center = [ "river/window" ];
      modules-right = [ "tray" "custom/kb" "pulseaudio" "pulseaudio/slider" "network" "backlight" "battery" "power-profiles-daemon" "clock" "group/power" ];
      clock.format = "{:%a %d %b  %H:%M}";
      battery = {
        format = "{icon} {capacity}%";
        format-icons = [ "" "" "" "" "" ];
        states = { warning = 25; critical = 10; };
      };
      network = {
        format-wifi = " {essid}";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        on-click = "nm-connection-editor";
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons.default = [ "" "" "" ];
        scroll-step = 5;
        on-click = "wpctl set-mute @DEFAULT_SINK@ toggle";
        on-click-right = "pavucontrol"; # floats, see river.nix
      };
      "pulseaudio/slider" = { min = 0; max = 100; };
      # Written by kb-layout (river.nix), which sends RTMIN+8 on every switch.
      # Power icon; hovering slides out lock/logout/sleep/reboot/shutdown.
      "group/power" = {
        orientation = "inherit";
        drawer = { transition-duration = 300; transition-left-to-right = false; children-class = "power-child"; };
        modules = [ "custom/power" "custom/lock" "custom/logout" "custom/suspend" "custom/reboot" ];
      };
      "custom/power" = { format = "⏻"; tooltip-format = "Shut down"; on-click = "${confirm} 'Shut down' systemctl poweroff"; };
      "custom/reboot" = { format = "󰜉"; tooltip-format = "Restart"; on-click = "${confirm} Restart systemctl reboot"; };
      "custom/suspend" = { format = "󰤄"; tooltip-format = "Sleep"; on-click = "systemctl suspend"; };
      "custom/logout" = { format = "󰍃"; tooltip-format = "Log out"; on-click = "riverctl exit"; };
      "custom/lock" = { format = "󰌾"; tooltip-format = "Lock"; on-click = "loginctl lock-session"; };
      "custom/kb" = {
        exec = "tr a-z A-Z < $XDG_RUNTIME_DIR/kb-layout";
        interval = "once";
        signal = 8;
        format = "󰌌 {}";
        tooltip = false;
      };
      backlight.format = "󰃠 {percent}%";
      "river/window".max-length = 60;
    };
    style = ''
      * { font-family: "FiraCode Nerd Font"; font-size: 12px; border: none; min-height: 0; }
      window#waybar { background: transparent; color: #cdd6f4; }
      tooltip { background: #1e1e2e; border: 1px solid #45475a; border-radius: 8px; }

      /* Each group sits on its own rounded pill. */
      #tags, #window, #tray, #custom-kb, #pulseaudio, #pulseaudio-slider,
      #network, #backlight, #battery, #power-profiles-daemon, #clock {
        background: #1e1e2e; border-radius: 10px; padding: 0 10px;
      }
      window#waybar.empty #window { background: transparent; }

      #tags { padding: 0 2px; }
      #tags button { padding: 0 6px; margin: 3px 1px; color: #6c7086; border-radius: 7px; }
      #tags button.occupied { color: #cdd6f4; }
      #tags button.focused { color: #1e1e2e; background: #89b4fa; }
      #tags button.urgent { color: #1e1e2e; background: #f38ba8; }

      #custom-kb { color: #f9e2af; font-weight: bold; }
      #pulseaudio { color: #89b4fa; border-radius: 10px 0 0 10px; padding-right: 4px; }
      #pulseaudio.muted { color: #6c7086; }
      #pulseaudio-slider { border-radius: 0 10px 10px 0; padding-left: 0; margin-left: -6px; }
      #pulseaudio-slider slider { min-height: 10px; min-width: 10px; background: #cdd6f4; border-radius: 5px; box-shadow: none; }
      #pulseaudio-slider trough { min-width: 90px; min-height: 4px; background: #45475a; border-radius: 4px; }
      #pulseaudio-slider highlight { min-height: 4px; background: #89b4fa; border-radius: 4px; }
      #network { color: #a6e3a1; }
      #backlight { color: #f9e2af; }
      #battery { color: #a6e3a1; }
      #battery.warning { color: #f9e2af; }
      #battery.critical { color: #f38ba8; }
      #clock { color: #cba6f7; }

      #power { background: #1e1e2e; border-radius: 10px; padding: 0 4px; }
      #custom-power, #custom-reboot, #custom-suspend, #custom-logout, #custom-lock { padding: 0 8px; font-size: 14px; }
      #custom-power { color: #f38ba8; }
      #custom-reboot { color: #fab387; }
      #custom-suspend { color: #89b4fa; }
      #custom-logout { color: #cba6f7; }
      #custom-lock { color: #a6e3a1; }
      .power-child:hover { background: #313244; border-radius: 7px; }
    '';
  };
}
