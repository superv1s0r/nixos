{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    wlr-randr
    pavucontrol
    networkmanagerapplet
  ];

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

  # Started from the river init script, not systemd, so it gets the Wayland env.
  programs.waybar = {
    enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      height = 26;
      modules-left = [ "river/tags" "river/mode" ];
      modules-center = [ "river/window" ];
      modules-right = [ "tray" "pulseaudio" "network" "backlight" "battery" "power-profiles-daemon" "clock" ];
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
        on-click = "pavucontrol";
      };
      backlight.format = "󰃠 {percent}%";
      "river/window".max-length = 60;
    };
    style = ''
      * { font-family: "FiraCode Nerd Font"; font-size: 12px; }
      window#waybar { background: #1e1e2e; color: #cdd6f4; }
      #tags button { padding: 0 6px; color: #6c7086; }
      #tags button.occupied { color: #cdd6f4; }
      #tags button.focused { color: #1e1e2e; background: #89b4fa; }
      #tags button.urgent { background: #f38ba8; }
      #clock, #battery, #network, #pulseaudio, #backlight, #tray, #power-profiles-daemon { padding: 0 8px; }
      #battery.warning { color: #f9e2af; }
      #battery.critical { color: #f38ba8; }
    '';
  };
}
