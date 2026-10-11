{ pkgs, ... }:
{
  # Lets unpatched binaries (Mason LSPs, dotnet tools, pip wheels) run.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      icu # .NET globalization
      curl
      libxml2
      glib
      krb5
    ];
  };

  # Flip to true if needed; then add "docker" to miller's extraGroups.
  virtualisation.docker.enable = false;
}
