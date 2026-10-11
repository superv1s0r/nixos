{ ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable = true; # amdgpu + Mesa (RADV)
    enable32Bit = true;
  };

  services.fwupd.enable = true; # Lenovo ships BIOS updates via LVFS
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true; # conflicts with TLP; don't enable both
  services.fstrim.enable = true;
  zramSwap.enable = true;
}
