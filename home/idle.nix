{ pkgs, ... }:
let
  lock = "${pkgs.swaylock}/bin/swaylock -f";
  wlopm = "${pkgs.wlopm}/bin/wlopm";
in
{
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      show-failed-attempts = true;
      indicator-idle-visible = true; # show the ring before typing, so it's clear it's locked
      indicator-radius = 90;
      show-keyboard-layout = true; # a wrong layout (es/ru) is the usual reason a password fails
      font = "FiraCode Nerd Font";
      inside-color = "1e1e2e";
      ring-color = "45475a";
      key-hl-color = "89b4fa";
      line-color = "00000000";
      separator-color = "00000000";
      text-color = "cdd6f4";
      inside-ver-color = "1e1e2e";
      ring-ver-color = "89b4fa";
      inside-wrong-color = "1e1e2e";
      ring-wrong-color = "f38ba8";
      text-wrong-color = "f38ba8";
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lock;
      lock = lock;
      after-resume = "${wlopm} --on '*'";
    };
    timeouts = [
      { timeout = 300; command = lock; }
      # wlopm powers screens off (DPMS) without disabling them, so river keeps windows where they are.
      { timeout = 600; command = "${wlopm} --off '*'"; resumeCommand = "${wlopm} --on '*'"; }
      # Skipped in VMs: QEMU guests don't resume from suspend, they reboot and hang.
      { timeout = 1800; command = "${pkgs.systemd}/bin/systemd-detect-virt -q || ${pkgs.systemd}/bin/systemctl suspend"; }
    ];
  };
}
