{ pkgs, ... }:
let
  lock = "${pkgs.swaylock}/bin/swaylock -f";
  wlr-randr = "${pkgs.wlr-randr}/bin/wlr-randr";
  # Turn off every enabled output; on resume kanshi re-applies the right profile.
  screensOff = pkgs.writeShellScript "screens-off" ''
    ${wlr-randr} --json | ${pkgs.jq}/bin/jq -r '.[] | select(.enabled) | .name' \
      | while read -r o; do ${wlr-randr} --output "$o" --off; done
  '';
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
    };
    timeouts = [
      { timeout = 300; command = lock; }
      { timeout = 600; command = "${screensOff}"; resumeCommand = "${pkgs.systemd}/bin/systemctl --user restart kanshi"; }
      { timeout = 1800; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    ];
  };
}
