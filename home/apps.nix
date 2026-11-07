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
    libnotify # notify-send
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

  # Notifications + quick-settings panel, opened from the bell in waybar.
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      control-center-width = 380;
      control-center-margin-top = 6;
      control-center-margin-right = 6;
      control-center-margin-bottom = 6;
      notification-window-width = 360;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0;
      hide-on-clear = true;
      widgets = [ "title" "buttons-grid" "volume" "backlight" "mpris" "dnd" "notifications" ];
      widget-config = {
        title = { text = "Quick settings"; clear-all-button = true; button-text = "Clear"; };
        dnd.text = "Do not disturb";
        volume = { label = "󰕾"; show-per-app = false; };
        backlight = { label = "󰃠"; device = "amdgpu_bl1"; }; # hidden in the VM (no backlight)
        mpris = { image-size = 64; image-radius = 8; };
        buttons-grid.actions = [
          {
            label = "󰖩";
            type = "toggle";
            command = "sh -c '[ \"$SWAYNC_TOGGLE_STATE\" = true ] && nmcli radio wifi on || nmcli radio wifi off'";
            update-command = "sh -c '[ \"$(nmcli radio wifi)\" = enabled ] && echo true || echo false'";
          }
          { label = "󰂯"; command = "blueman-manager"; }
          { label = "󰒓"; command = "nm-connection-editor"; }
          { label = "󰕾"; command = "pavucontrol"; }
          { label = "󰌾"; command = "sh -c 'swaync-client -cp; loginctl lock-session'"; }
          { label = "󰍃"; command = "riverctl exit"; }
          { label = "󰜉"; command = "sh -c 'swaync-client -cp; ${confirm} Restart systemctl reboot'"; }
          { label = "⏻"; command = "sh -c 'swaync-client -cp; ${confirm} \"Shut down\" systemctl poweroff'"; }
        ];
      };
    };
    style = ''
      * { font-family: "FiraCode Nerd Font"; font-size: 13px; }

      .control-center {
        background: #1e1e2e; color: #cdd6f4;
        border: 1px solid #45475a; border-radius: 14px; padding: 10px;
      }
      .control-center .widget-title > label { font-size: 15px; font-weight: bold; }
      .widget-title > button, .widget-dnd > switch {
        background: #313244; color: #cdd6f4; border: none; border-radius: 8px;
      }
      .widget-dnd > switch:checked { background: #89b4fa; }

      .widget-buttons-grid { padding: 6px 0; }
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: #313244; color: #cdd6f4; border: none; border-radius: 10px;
        min-width: 56px; min-height: 40px; font-size: 18px;
      }
      .widget-buttons-grid > flowbox > flowboxchild > button:hover { background: #45475a; }
      .widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked { background: #89b4fa; color: #1e1e2e; }

      .widget-volume, .widget-backlight {
        background: #313244; border-radius: 10px; padding: 6px 12px; margin: 4px 0;
      }
      .widget-volume > box > label, .widget-backlight > label { font-size: 16px; color: #89b4fa; }
      scale trough { background: #45475a; border-radius: 6px; min-height: 6px; }
      scale highlight { background: #89b4fa; border-radius: 6px; }
      scale slider { background: #cdd6f4; border-radius: 50%; min-width: 14px; min-height: 14px; }

      .widget-mpris-player { background: #313244; border-radius: 10px; padding: 8px; margin: 4px 0; }

      .notification-row { outline: none; }
      .notification, .control-center .notification {
        background: #313244; color: #cdd6f4;
        border: 1px solid #45475a; border-radius: 12px; padding: 4px;
      }
      .notification.critical { border-color: #f38ba8; }
      .floating-notifications .notification { background: #1e1e2e; }
      .close-button { background: #45475a; color: #cdd6f4; border-radius: 50%; }
      .close-button:hover { background: #f38ba8; color: #1e1e2e; }
    '';
  };
}
