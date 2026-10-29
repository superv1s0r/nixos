{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15; # keep /boot (1G) from filling
  boot.loader.efi.canTouchEfiVariables = true;

  # Load amdgpu in initrd: native resolution from early boot (greeter, LUKS prompt).
  hardware.amdgpu.initrd.enable = true;

  # Newest amdgpu fixes for Barcelo.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "amdgpu.sg_display=0"     # scatter/gather display causes flicker/black screens on Cezanne/Barcelo
    "amdgpu.dcdebugmask=0x10" # disable Panel Self Refresh, a common freeze cause
  ];
}
