{ ... }:
{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore"; # lid closed on external monitors
  };

  # Ryzen 5000 laptops only support s2idle (no S3); make it explicit.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];
}
