{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  # HARDWARE CONFIGURATION
  # ----------------------

  # Boot and Kernel
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    
    initrd = {
      availableKernelModules = [ 
        "nvme" 
        "xhci_pci" 
        "usb_storage" 
        "sd_mod" 
        "rtsx_pci_sdmmc" 
      ];
      # Disk encryption
      luks.devices.encrypted_partition.device = "/dev/disk/by-uuid/da1a7fdf-43a5-4f84-ac6f-7447243a2c31";
    };
    
    # Kernel configuration
    #kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [ 
      "kvm-amd"      # Virtualization
      "amd_pstate"   # Power management
      "acpi_cpufreq" 
      "amdgpu"       # GPU support
      "k10temp"      # Temperature monitoring
      "thinkpad_acpi"
      "i2c_hid"      # Input devices
      "pmouse"
    ];
    extraModulePackages = [ pkgs.linuxPackages.acpi_call ];
    
    # AMD-specific kernel parameters
    kernelParams = [
      # GPU configuration
      "radeon.si_support=0"
      "amdgpu.si_support=1"
      "radeon.cik_support=0"
      "amdgpu.cik_support=1"
      "amdgpu.dc=1"
      # touchpad bug
      "psmouse.synaptics_intertouch=0"
      "psmouse.resetafter=0"
      # CPU configuration
      "nosmt=force" # disable simultaneous multithreading(HT/smt)
      "amd_pstate=passive" # power management
    ];
  };

  # File systems
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

  # Swap
  swapDevices = [
    { device = "/dev/disk/by-uuid/6f3e1022-45d0-4378-bcf5-26e4bd42bfd4"; }
  ];

  # GRAPHICS AND DISPLAY
  # --------------------
  
  # AMD GPU configuration
  services.xserver.videoDrivers = [ "amdgpu" ];
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
  
  # Input devices
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      tapping = true;
      disableWhileTyping = true;
      scrollMethod = "twofinger";
      clickMethod = "clickfinger";  # Try this setting
      accelSpeed = 0.5;  # Adjust as needed
    };
  };

  # SYSTEM SERVICES
  # ---------------
  
  # Power management (ThinkPad-specific)
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      RESTORE_DEVICE_STATE_ON_STARTUP = true;
    };
  };

  # Fan control (ThinkPad-specific)
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

  # Audio with PipeWire
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Peripheral device support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;         # Power up Bluetooth adapter on boot
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;    # Enable experimental features
        };
      };
  };
  services.udev.packages = with pkgs; [
    headsetcontrol
  ];


  # NETWORKING
  # ----------
  
  networking = {
    hostName = "lenovo";
    useDHCP = lib.mkDefault true;
    wireless.enable = true;
  };

  # SECURITY
  # --------
  
  # sudo configuration - SECURITY ISSUE: passwordless sudo is a security risk
  # Recommendation: Replace with more restrictive rules or proper authentication
  security.sudo = {
    enable = true;
    extraConfig = ''
      alice ALL=(ALL) NOPASSWD: ALL
      user ALL=(ALL) NOPASSWD: ALL
    '';
  };
}
