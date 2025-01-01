{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  boot.kernelModules = [ "amdgpu" "kvm-amd" "i2c_hid" "k10temp" ];
  boot.extraModulePackages = [ pkgs.linuxPackages.acpi_call ];

# Networking settings
  networking.hostName = "atomman";
  networking.useDHCP = lib.mkDefault true;

# GPU Configuration for AMD Ryzen 7 (with integrated graphics)
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.kernelParams = [
  ];

# Enable Bluetooth and Audio
  hardware.bluetooth.enable = true;

# Sound (PipeWire)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
}

