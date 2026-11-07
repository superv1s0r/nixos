# Install (from the NixOS minimal ISO)

Back up `~/` first. This assumes the NVMe is `/dev/nvme0n1` (check with `lsblk`). **The disk will be wiped.**

There are two ways to install:

- **Case 1: no encryption.** Follow steps 1-4 below.
- **Case 2: full disk encryption (LUKS).** Follow [Case 2](#case-2-full-disk-encryption-luks), which replaces step 1 and adds a check before step 3.

## 1. Partition, btrfs subvolumes, mount

```sh
sudo -i
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root btrfs 1GiB 100%
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkfs.btrfs -L nixos /dev/nvme0n1p2

# @ = /, @home = /home (snapshotted), @nix = /nix (never snapshotted), @log = /var/log
mount /dev/nvme0n1p2 /mnt
for s in @ @home @nix @log; do btrfs subvolume create /mnt/$s; done
umount /mnt

o=compress=zstd,noatime
mount -o subvol=@,$o     /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{home,nix,var/log,boot}
mount -o subvol=@home,$o /dev/nvme0n1p2 /mnt/home
mount -o subvol=@nix,$o  /dev/nvme0n1p2 /mnt/nix
mount -o subvol=@log,$o  /dev/nvme0n1p2 /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot
btrfs subvolume create /mnt/home/.snapshots   # snapper needs this to exist
```

## 2. Get the config

```sh
nix-shell -p git
git clone https://github.com/superv1s0r/nixos.git /mnt/etc/nixos
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hosts/lnv/hardware-configuration.nix
```

Check the new `hosts/lnv/hardware-configuration.nix`: every btrfs mount should have
`options = [ "subvol=@..." "compress=zstd" "noatime" ];`. Add `compress`/`noatime` if they are missing.
Compare it with the placeholder in git (`git diff`).

## 3. Install

```sh
cd /mnt/etc/nixos
git add -A          # flakes ignore untracked files, including the new hardware config
nix --extra-experimental-features 'nix-command flakes' flake lock   # creates flake.lock
nixos-install --flake .#lnv
nixos-enter --root /mnt -c 'passwd miller'
reboot
```

## 4. After first boot

Log in through ReGreet (graphical greeter). It starts river.

```sh
sudo mv /etc/nixos ~/nixos-config && sudo chown -R miller:users ~/nixos-config
cd ~/nixos-config && git add flake.lock hosts/lnv/hardware-configuration.nix && git commit -m "lnv: hardware config + lock"
wlr-randr      # read the real output names, then fix home/monitors.nix
```

Daily commands are in [README.md](README.md).

## Case 2: full disk encryption (LUKS)

Everything except `/boot` is encrypted, and you enter a passphrase at every boot. **Lose the passphrase and the data is gone.** Keep it somewhere off this laptop. The prompt uses the US layout, so pick a passphrase you can type on it.

### 1. Partition, encrypt, btrfs subvolumes, mount

Use this instead of step 1 above.

```sh
sudo -i
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root 1GiB 100%
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1

cryptsetup luksFormat --type luks2 /dev/nvme0n1p2   # type YES, then set the passphrase
cryptsetup open /dev/nvme0n1p2 cryptroot
mkfs.btrfs -L nixos /dev/mapper/cryptroot

# @ = /, @home = /home (snapshotted), @nix = /nix (never snapshotted), @log = /var/log
mount /dev/mapper/cryptroot /mnt
for s in @ @home @nix @log; do btrfs subvolume create /mnt/$s; done
umount /mnt

o=compress=zstd,noatime
mount -o subvol=@,$o     /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,var/log,boot}
mount -o subvol=@home,$o /dev/mapper/cryptroot /mnt/home
mount -o subvol=@nix,$o  /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@log,$o  /dev/mapper/cryptroot /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot
btrfs subvolume create /mnt/home/.snapshots   # snapper needs this to exist
```

### 2. Get the config

Follow step 2 above, then confirm the generated config found the encrypted disk:

```sh
grep luks /mnt/etc/nixos/hosts/lnv/hardware-configuration.nix
```

You should see `boot.initrd.luks.devices."cryptroot"`. If it's missing, don't install: the system wouldn't be able to unlock its disk at boot.

### 3. Install and first boot

Follow steps 3 and 4 above. Enter the passphrase at boot, then log in as usual.

### 4. Back up the LUKS header

If the header gets damaged, the data can't be recovered even with the passphrase. After first boot:

```sh
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header.img
sudo chown miller:users luks-header.img
```

Move `luks-header.img` off the laptop, then delete the local copy.

## Troubleshooting

### amdgpu freezes / black screen

After a freeze and a hard reboot, check the previous boot's kernel log:

```sh
journalctl -k -b -1 | grep -i amdgpu
cat /proc/cmdline   # confirm amdgpu.sg_display=0 and amdgpu.dcdebugmask=0x10 are set
```

Common culprits are PSR, scatter/gather display, and old firmware. Both kernel parameters live in
`modules/nixos/boot.nix`. If freezes started after an update, boot an older generation from the
systemd-boot menu. You can also try `pkgs.linuxPackages` (LTS) instead of `_latest`.

### Suspend

```sh
cat /sys/power/mem_sleep     # expect "[s2idle]"; this Ryzen has no S3 ("deep")
journalctl -b -1 | grep -iE 'suspend|resume|PM:'
```

If the laptop wakes up straight away, check `cat /proc/acpi/wakeup` and look for a USB device or dock
that wakes it. With external monitors and the lid closed, logind ignores the lid (`HandleLidSwitchDocked`).
