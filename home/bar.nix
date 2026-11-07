{ lib, pkgs, ... }:
let
  eww = "${pkgs.eww}/bin/eww";

  # Runs Shut down/Restart only after picking "Yes".
  confirm = pkgs.writeShellScript "confirm" ''
    label=$1; shift
    choice=$(printf 'No\nYes\n' | ${pkgs.fuzzel}/bin/fuzzel --dmenu --lines 2 --width 20 --prompt "$label? ")
    [ "$choice" = Yes ] && exec "$@"
  '';

  # menu NAME: opens that dropdown, or closes it if it's already open.
  # The transparent "closer" window underneath closes it on an outside click.
  menu = pkgs.writeShellScript "eww-menu" ''
    export PATH=${lib.makeBinPath (with pkgs; [ networkmanager wireplumber brightnessctl jq gawk gnugrep coreutils ])}:$PATH
    ${eww} ping >/dev/null 2>&1 || { ${eww} daemon; sleep 0.3; }
    open=$(${eww} active-windows 2>/dev/null)
    ${eww} close-all
    case "$open" in *"$1"*) exit 0 ;; esac
    [ "$1" = wifi ] && nmcli dev wifi rescan >/dev/null 2>&1 &
    ${eww} open closer
    ${eww} open "$1"
  '';

  # Lists networks as JSON. Connecting uses the BSSID: an SSID is untrusted text
  # that could otherwise inject shell commands through the button's onclick.
  wifi-list = pkgs.writeShellScript "wifi-list" ''
    nmcli -t -f IN-USE,SIGNAL,BSSID,SSID dev wifi list --rescan no 2>/dev/null | jq -R -s -c '
      [split("\n")[] | select(length > 0) | [splits("(?<!\\\\):")] | map(gsub("\\\\:"; ":"))
       | {active: (.[0] == "*"), signal: (.[1] | tonumber), bssid: .[2], ssid: .[3]}
       | select(.ssid != "")] | sort_by(-.signal) | unique_by(.ssid) | sort_by(-.signal) | .[:8]'
  '';

  yuck = ''
    (defpoll volume :interval "1s" :initial "0" `wpctl get-volume @DEFAULT_SINK@ | awk '{print int($2*100)}'`)
    (defpoll muted :interval "1s" :initial "false" `wpctl get-volume @DEFAULT_SINK@ | grep -q MUTED && echo true || echo false`)
    (defpoll brightness :interval "2s" :initial "-1" `brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d % | grep . || echo -1`)
    (defpoll wifi_on :interval "3s" :initial "false" `[ "$(nmcli radio wifi)" = enabled ] && echo true || echo false`)
    (defpoll networks :interval "5s" :initial "[]" `${wifi-list}`)

    (defwidget row [icon label onclick ?danger ?timeout]
      (button :class "row ''${danger == "true" ? "danger" : ""}" :onclick onclick :timeout {timeout ?: "2s"}
        (box :space-evenly false :spacing 12
          (label :class "icon" :text icon)
          (label :text label :limit-width 30))))

    (defwindow closer :stacking "overlay" :exclusive false :focusable false
        :geometry (geometry :width "100%" :height "100%" :anchor "top center")
      (eventbox :onclick "${eww} close-all" :onrightclick "${eww} close-all"))

    (defwindow calendar :stacking "overlay" :exclusive false :focusable false
        :geometry (geometry :y "6px" :anchor "top center")
      (box :class "panel" (calendar)))

    (defwindow system :stacking "overlay" :exclusive false :focusable false
        :geometry (geometry :x "8px" :y "6px" :width "300px" :anchor "top right")
      (box :class "panel" :orientation "v" :space-evenly false :spacing 10
        (label :class "title" :xalign 0 :text "System")
        (box :space-evenly false :spacing 10 (label :class "icon" :text "󰻠") (label :text "CPU ''${round(EWW_CPU.avg, 0)}%"))
        (progress :value {EWW_CPU.avg})
        (box :space-evenly false :spacing 10 (label :class "icon" :text "󰍛") (label :text "Memory ''${round(EWW_RAM.used_mem_perc, 0)}%"))
        (progress :value {EWW_RAM.used_mem_perc})
        (box :space-evenly false :spacing 10 (label :class "icon" :text "󰋊") (label :text "Disk ''${round(EWW_DISK["/"].used_perc, 0)}%"))
        (progress :value {EWW_DISK["/"].used_perc})
        (row :icon "󰄪" :label "Open btop" :onclick "${eww} close-all; alacritty -e btop &")))

    (defwindow wifi :stacking "overlay" :exclusive false :focusable false
        :geometry (geometry :x "8px" :y "6px" :width "320px" :anchor "top right")
      (box :class "panel" :orientation "v" :space-evenly false :spacing 4
        (box :space-evenly false
          (label :class "title" :hexpand true :xalign 0 :text "Wi-Fi")
          (button :class "pill ''${wifi_on ? "on" : ""}"
            :onclick "nmcli radio wifi ''${wifi_on ? "off" : "on"}" {wifi_on ? "On" : "Off"}))
        (box :orientation "v" :space-evenly false :visible wifi_on
          (for net in networks
            (row :icon {net.active ? "󰖩" : "󰤨"} :label "''${net.ssid}  ''${net.signal}%"
              :onclick "nmcli dev wifi connect ''${net.bssid}" :timeout "30s")))
        (row :icon "󰒓" :label "All network settings" :onclick "${eww} close-all; alacritty -e nmtui &")))

    (defwindow audio :stacking "overlay" :exclusive false :focusable false
        :geometry (geometry :x "8px" :y "6px" :width "300px" :anchor "top right")
      (box :class "panel" :orientation "v" :space-evenly false :spacing 10
        (label :class "title" :xalign 0 :text "Sound")
        (box :space-evenly false :spacing 8
          (button :class "icon-button" :onclick "wpctl set-mute @DEFAULT_SINK@ toggle" {muted ? "󰝟" : "󰕾"})
          (scale :hexpand true :min 0 :max 101 :value volume :onchange "wpctl set-volume @DEFAULT_SINK@ {}%")
          (label :text "''${volume}%"))
        (box :space-evenly false :spacing 8 :visible {brightness >= 0}
          (label :class "icon" :text "󰃠")
          (scale :hexpand true :min 1 :max 101 :value brightness :onchange "brightnessctl set {}%")
          (label :text "''${brightness}%"))
        (row :icon "󰒓" :label "Audio mixer" :onclick "${eww} close-all; pavucontrol &")))

    (defwindow power :stacking "overlay" :exclusive false :focusable false
        :geometry (geometry :x "8px" :y "6px" :width "220px" :anchor "top right")
      (box :class "panel" :orientation "v" :space-evenly false :spacing 2
        (row :icon "󰌾" :label "Lock" :onclick "${eww} close-all; loginctl lock-session")
        (row :icon "󰤄" :label "Sleep" :onclick "${eww} close-all; systemd-detect-virt -q || systemctl suspend")
        (row :icon "󰍃" :label "Log out" :onclick "${eww} close-all; riverctl exit")
        (row :icon "󰜉" :label "Restart" :timeout "60s" :onclick "${eww} close-all; ${confirm} Restart systemctl reboot")
        (row :icon "⏻" :label "Shut down" :danger "true" :timeout "60s" :onclick "${eww} close-all; ${confirm} 'Shut down' systemctl poweroff")))
  '';

  css = ''
    * { all: unset; font-family: "FiraCode Nerd Font"; font-size: 13px; color: #d7e0ee; }
    .panel { background: #111723; border: 1px solid #2a3446; border-radius: 14px; padding: 12px; }
    .title { font-size: 14px; font-weight: bold; padding: 2px 6px 6px; }
    .icon { font-size: 16px; color: #5aa7e6; }
    .row { padding: 8px 10px; border-radius: 9px; }
    .row:hover { background: #222c3d; }
    .danger .icon { color: #f38ba8; }
    .pill { padding: 3px 12px; border-radius: 10px; background: #222c3d; }
    .pill.on { background: #3b82c4; }
    .icon-button { font-size: 16px; color: #5aa7e6; padding: 2px 6px; }
    scale trough { background: #2a3446; border-radius: 6px; min-height: 6px; min-width: 150px; }
    scale highlight { background: #3b82c4; border-radius: 6px; }
    scale slider { background: #d7e0ee; border-radius: 50%; min-width: 14px; min-height: 14px; margin: -4px; }
    progressbar trough { background: #2a3446; border-radius: 6px; min-height: 6px; }
    progressbar progress { background: #3b82c4; border-radius: 6px; min-height: 6px; }
    calendar { padding: 4px; }
    calendar:selected { background: #3b82c4; color: #ffffff; border-radius: 6px; }
    calendar.header, calendar.button { font-weight: bold; }
    calendar:indeterminate { color: #5c6b82; }
  '';
in
{
  home.packages = with pkgs; [ btop ];

  programs.eww = {
    enable = true;
    yuckConfig = yuck;
    scssConfig = css; # plain CSS is valid SCSS
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true; # started by river-session.target
    settings.main = {
      layer = "top";
      position = "top";
      height = 38;
      margin-top = 6;
      margin-left = 8;
      margin-right = 8;
      spacing = 6;
      modules-left = [ "custom/logo" "river/tags" ];
      modules-center = [ "clock" ];
      modules-right = [ "tray" "custom/kb" "cpu" "memory" "disk" "pulseaudio" "network" "battery" "custom/notification" "custom/power" "custom/lock" ];

      "custom/logo" = { format = ""; tooltip = false; on-click = "fuzzel"; };
      clock = { format = "{:%a, %b %d   %H:%M}"; tooltip = false; on-click = "${menu} calendar"; };
      cpu = { format = "󰻠 {usage}%"; interval = 3; on-click = "${menu} system"; };
      memory = { format = "󰍛 {used:0.1f}G / {total:0.1f}G"; interval = 5; tooltip = false; on-click = "${menu} system"; };
      disk = { format = "󰋊 {percentage_used}%"; path = "/"; interval = 60; on-click = "${menu} system"; };
      battery = {
        format = "{icon} {capacity}%";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
        states = { warning = 25; critical = 10; };
      };
      network = {
        format-wifi = "󰖩 {essid}";
        format-ethernet = "󰈀 Wired";
        format-disconnected = "󰖪 Not connected";
        tooltip = false;
        on-click = "${menu} wifi";
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
        scroll-step = 5;
        tooltip = false;
        on-click = "${menu} audio";
      };
      # Written by kb-layout (river.nix), which sends RTMIN+8 on every switch.
      "custom/kb" = {
        exec = "tr a-z A-Z < $XDG_RUNTIME_DIR/kb-layout";
        interval = "once";
        signal = 8;
        format = "󰌌 {}";
        tooltip = false;
      };
      # Bell: click opens the swaync panel, right-click toggles do-not-disturb.
      "custom/notification" = {
        exec = "swaync-client -swb";
        return-type = "json";
        format = "{icon}";
        format-icons = {
          none = "󰂚";
          notification = "󰂚<span foreground='#f38ba8'><sup>●</sup></span>";
          dnd-none = "󰂛";
          dnd-notification = "󰂛<span foreground='#f38ba8'><sup>●</sup></span>";
          inhibited-none = "󰂚";
          inhibited-notification = "󰂚<span foreground='#f38ba8'><sup>●</sup></span>";
          dnd-inhibited-none = "󰂛";
          dnd-inhibited-notification = "󰂛<span foreground='#f38ba8'><sup>●</sup></span>";
        };
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
        tooltip = false;
      };
      "custom/power" = { format = "⏻"; tooltip = false; on-click = "${menu} power"; };
      "custom/lock" = { format = "󰌾"; tooltip = false; on-click = "loginctl lock-session"; };
    };
    style = ''
      * { font-family: "FiraCode Nerd Font"; font-size: 13px; border: none; min-height: 0; }
      window#waybar { background: rgba(14, 19, 29, 0.92); color: #d7e0ee; border-radius: 12px; }

      #custom-logo { color: #5aa7e6; font-size: 20px; padding: 0 12px 0 14px; }

      #tags { margin: 5px 0; }
      #tags button { min-width: 34px; margin: 0 2px; padding: 0; color: #d7e0ee; background: #1a2230; border-radius: 12px; }
      #tags button:not(.occupied):not(.focused) { color: #5c6b82; }
      #tags button.focused { color: #ffffff; background: #3b82c4; }
      #tags button.urgent { color: #111723; background: #f38ba8; }

      #clock { font-weight: bold; padding: 0 12px; }

      #tray, #custom-kb, #cpu, #memory, #disk, #pulseaudio, #network, #battery,
      #custom-notification, #custom-power, #custom-lock {
        background: #1a2230; border-radius: 12px; margin: 5px 0; padding: 0 12px;
      }
      #custom-lock { margin-right: 8px; }
      #custom-kb { color: #f9e2af; font-weight: bold; }
      #pulseaudio.muted { color: #5c6b82; }
      #battery.warning { color: #f9e2af; }
      #battery.critical { color: #f38ba8; }
      #cpu:hover, #memory:hover, #disk:hover, #pulseaudio:hover, #network:hover,
      #custom-notification:hover, #custom-power:hover, #custom-lock:hover { background: #2a3446; }
    '';
  };
}
