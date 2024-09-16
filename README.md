# nixcfg

## Installation Guide

### 1. Download NixOS ISO
Download the [NixOS image](https://nixos.org/download/).

Create bootable USB:

```sh
dd if=/path/to/nix.iso of=/dev/sdX bs=4M status=progress
```

### 2. Boot & Partition Disk
After booting from USB, partition your installation disk. Example:

```sh
Disk /dev/nvme0n1: 512GB
Partition Table: gpt
Number  Start   End     Size    File system     Name     Flags
 1      1049kB  538MB   537MB   fat32           ESP      boot, esp
 2      538MB   2149MB  1611MB  ext4            primary
 3      2149MB  495GB   493GB                   primary
 4      495GB   512GB   17.2GB  linux-swap(v1)  primary  swap
```

### 3. Mount Partitions

```sh
mount /dev/nvme0n1p3 /mnt
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/efi
```

### 4. Generate Configuration

```sh
nixos-generate-config --root /mnt
```

### 5. Clone Repository & Install

Clone your configuration repo, adapt it to your hardware:

```sh
git clone <repo-url>
```

Finally, install NixOS:

```sh
nixos-install
```
