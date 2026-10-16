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
      { timeout = 1800; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    ];
  };
}
