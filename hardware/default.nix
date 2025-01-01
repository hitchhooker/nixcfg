{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest; # latest kernel
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

# Networking settings
  networking.useDHCP = lib.mkDefault true;

# GPU Configuration for AMD Ryzen 7 (with integrated graphics)
  services.xserver.videoDrivers = [ ];
  boot.kernelParams = [ ];

# Enable Bluetooth and Audio
  hardware.bluetooth.enable = true;

# Sound (PipeWire)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
}

