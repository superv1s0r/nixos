# nixos-config

NixOS (unstable, flakes) and home-manager for `miller-lnv`: a Lenovo V15 G3 ABA (Ryzen 7 5825U) running river on Wayland.
To install, see [INSTALL.md](INSTALL.md).

## Layout

```
flake.nix                 inputs, nixosConfigurations.lnv, templates
hosts/lnv/                host settings + hardware-configuration.nix
modules/nixos/            system modules: boot, hardware, btrfs, desktop, power, dev, nix
home/                     home-manager (miller.nix imports shell, dev, river, idle, monitors, apps)
templates/{csharp,python} devShell templates
```

## Daily commands

```sh
sudo nixos-rebuild switch --flake ~/nixos-config#lnv   # apply (alias: rebuild)
nix flake update --flake ~/nixos-config && rebuild     # update everything
sudo nix-collect-garbage -d                            # gc now (also runs weekly)
sudo nixos-rebuild switch --rollback                   # roll back (or pick an older entry at boot)
snapper -c home list                                   # /home snapshots
sudo snapper -c home undochange <N>..0 <path>          # restore a file from snapshot N

nix flake init -t ~/nixos-config#csharp                # new C# project (then `direnv allow`)
nix flake init -t ~/nixos-config#python                # new Python project
```
