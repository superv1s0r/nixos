{
  description = "C# project";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      dotnet = with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 sdk_10_0 ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ dotnet pkgs.csharpier pkgs.netcoredbg ];
        DOTNET_ROOT = "${dotnet}/share/dotnet";
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        shellHook = ''export PATH="$HOME/.dotnet/tools:$PATH"'';
      };
    };
}
