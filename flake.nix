{
  description = "miller's NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations.lnv = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/lnv/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak"; # don't fail on pre-existing dotfiles
          home-manager.users.miller = import ./home/miller.nix;
        }
      ];
    };

    # nix flake init -t ~/nixos-config#csharp  (or #python)
    templates = {
      csharp = {
        path = ./templates/csharp;
        description = "C# / .NET 8+9 devShell";
      };
      python = {
        path = ./templates/python;
        description = "Python + uv devShell";
      };
    };
  };
}
