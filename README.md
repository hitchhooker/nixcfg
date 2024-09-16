# nixcfg

## install
dl [image](https://nixos.org/download/) dd if=/dl/nix.iso of=/dev/sdx bs=4M status=progress 

hook the stick in, partition your installation f.g.
```sh
Disk /dev/nvme0n1: 512GB
Partition Table: gpt
Number  Start   End     Size    File system     Name     Flags
 1      1049kB  538MB   537MB   fat32           ESP      boot, esp
 2      538MB   2149MB  1611MB  ext4            primary
 3      2149MB  495GB   493GB                   primary
 4      495GB   512GB   17.2GB  linux-swap(v1)  primary  swap
```
mount p3 /mnt, p2 /mnt/boot, p1 /mnt/boot/efi
nixos-generate-config --root /mnt
git clone repo  -> adapt accordingly for you hardware
nixos-install
