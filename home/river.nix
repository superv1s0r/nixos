{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ brightnessctl playerctl ];

  # greetd starts river without a login shell, so this target stands in for
  # what a full DE does: it pulls in graphical-session.target, which starts
  # kanshi, swayidle, waybar and the polkit agent, and stops them on logout.
  systemd.user.targets.river-session.Unit = {
    Description = "river compositor session";
    BindsTo = [ "graphical-session.target" ];
    Wants = [ "graphical-session-pre.target" ];
    After = [ "graphical-session-pre.target" ];
  };

  # river runs ~/.config/river/init (an executable script) at startup.
  xdg.configFile."river/init" = {
    executable = true;
    text = ''
      #!/bin/sh
      # Not a login shell: load home.sessionVariables (DOTNET_ROOT for Rider, EDITOR)
      # so apps launched from fuzzel inherit them.
      . ${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh

      mod=Super

      riverctl map normal $mod Return spawn alacritty
      riverctl map normal $mod D spawn fuzzel
      riverctl map normal $mod Q close
      riverctl map normal $mod+Shift E exit
      riverctl map normal $mod+Shift L spawn "loginctl lock-session"
      riverctl map normal $mod J focus-view next
      riverctl map normal $mod K focus-view previous
      riverctl map normal $mod+Shift J swap next
      riverctl map normal $mod+Shift K swap previous
      riverctl map normal $mod+Shift Return zoom
      riverctl map normal $mod H send-layout-cmd rivertile "main-ratio -0.05"
      riverctl map normal $mod L send-layout-cmd rivertile "main-ratio +0.05"
      riverctl map normal $mod F toggle-fullscreen
      riverctl map normal $mod+Shift Space toggle-float # Super+Space switches keyboard layout
      riverctl map normal $mod Period focus-output next
      riverctl map normal $mod+Shift Period send-to-output next
      riverctl map-pointer normal $mod BTN_LEFT move-view
      riverctl map-pointer normal $mod BTN_RIGHT resize-view

      for i in $(seq 1 9); do
        tags=$((1 << (i - 1)))
        riverctl map normal $mod $i set-focused-tags $tags
        riverctl map normal $mod+Shift $i set-view-tags $tags
        riverctl map normal $mod+Control $i toggle-focused-tags $tags
      done
      all=$(((1 << 32) - 1))
      riverctl map normal $mod 0 set-focused-tags $all

      # -l: also work while locked
      for m in normal locked; do
        riverctl map -l $m None XF86MonBrightnessUp spawn "brightnessctl set +5%"
        riverctl map -l $m None XF86MonBrightnessDown spawn "brightnessctl set 5%-"
        riverctl map -l $m None XF86AudioRaiseVolume spawn "wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+"
        riverctl map -l $m None XF86AudioLowerVolume spawn "wpctl set-volume @DEFAULT_SINK@ 5%-"
        riverctl map $m None XF86AudioMute spawn "wpctl set-mute @DEFAULT_SINK@ toggle"
        riverctl map $m None XF86AudioMicMute spawn "wpctl set-mute @DEFAULT_SOURCE@ toggle"
        riverctl map $m None XF86AudioPlay spawn "playerctl play-pause"
        riverctl map $m None XF86AudioNext spawn "playerctl next"
        riverctl map $m None XF86AudioPrev spawn "playerctl previous"
      done
      riverctl map normal None Print spawn 'grim -g "$(slurp)" - | wl-copy'
      riverctl map normal Shift Print spawn 'grim - | wl-copy'

      riverctl set-repeat 50 300
      riverctl keyboard-layout -options grp:win_space_toggle us,ru,es # Super+Space cycles, as on GNOME
      riverctl focus-follows-cursor normal
      for pad in $(riverctl list-inputs | grep -i touchpad); do
        riverctl input "$pad" tap enabled
        riverctl input "$pad" natural-scroll enabled
        riverctl input "$pad" disable-while-typing enabled
      done

      # Portals and user services need the Wayland env before the session target starts them.
      export XDG_CURRENT_DESKTOP=river
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP
      systemctl --user start river-session.target

      riverctl default-layout rivertile
      exec rivertile -view-padding 4 -outer-padding 4
    '';
  };
}
