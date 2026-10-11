{ ... }:
{
  # Output names/descriptions: run `wlr-randr` and adjust criteria if needed.
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "docked";
        profile.outputs = [
          { criteria = "eDP-1"; status = "disable"; }
          { criteria = "Microstep MD272XP*"; position = "0,0"; mode = "1920x1080@60Hz"; } # VERIFY: exact make string
          { criteria = "HP Inc. HP M27f*"; position = "1920,0"; mode = "1920x1080@75Hz"; } # VERIFY: exact make string
        ];
      }
      {
        profile.name = "laptop";
        profile.outputs = [
          { criteria = "eDP-1"; status = "enable"; }
        ];
      }
    ];
  };
}
