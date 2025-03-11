{ config, lib, pkgs, modulesPath, ... }:


#let
#wifiSecret = import /etc/secrets/wifi-networks.nix;
#in
{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

# Networking settings
  networking = {
    hostName = "lenovo";
    useDHCP = lib.mkDefault true;
    wireless = {
      enable = true;
      #networks = (import config.age.secrets.wifi-networks.path).wifiNetworks;
    };
  };

  # secret to be managed by agenix
  age.secrets.wifi-networks = {
    file = ./secrets/wifi-networks.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      alice ALL=(ALL) NOPASSWD: ALL
      '';
  };

# Bootloader and kernel settings
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  boot.initrd = {
    availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
    luks.devices.encrypted_partition.device = "/dev/disk/by-uuid/da1a7fdf-43a5-4f84-ac6f-7447243a2c31";
  };

# boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "amd_pstate" "amdgpu" "kvm-amd" "acpi_cpufreq" "i2c_hid" "k10temp" "thinkpad_acpi" "pmouse" ];
  boot.extraModulePackages = [ pkgs.linuxPackages.acpi_call ];

# TLP for power management (Lenovo laptops)
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      RESTORE_DEVICE_STATE_ON_STARTUP = true;
    };
  };

# fancontrol
  services.thinkfan = {
    enable = true;
    settings = {
      hwmon = [
      { device = "/sys/class/hwmon/hwmon9/pwm1"; }
      ];
      levels = [
      { temperature = 55; level = 0; }
      { temperature = 60; level = 1; }
      { temperature = 70; level = 2; }
      { temperature = 80; level = 7; }
      ];
    };
  };

# Filesystem configurations
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4c77ddb8-967c-496c-a7b3-566fcbd55255";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/9f02f2f4-fba3-436e-a033-895030140a5b";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/disk/by-uuid/C8FC-BA76";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

# Swap configuration
  swapDevices = [
  { device = "/dev/disk/by-uuid/6f3e1022-45d0-4378-bcf5-26e4bd42bfd4"; }
  ];

  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.kernelParams = [
    "radeon.si_support=0"
      "amdgpu.si_support=1"
      "radeon.cik_support=0"
      "amdgpu.cik_support=1"
      "amdgpu.dc=1"  # Enable display core support
      "nosmt=force"  # Disable SMT if needed
      "amd_pstate=passive"  # Power management for AMD
  ];


# Enable Bluetooth and Audio
  hardware.bluetooth.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
        amdvlk
        vaapiVdpau
        libvdpau-va-gl
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

# Sound (PipeWire)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

# Touchpad-specific settings
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      tapping = true;                # Enable tap-to-click
        disableWhileTyping = true;   # Disable touchpad while typing
        scrollMethod = "twofinger";  # Use two-finger scrolling
    };
  };
}
