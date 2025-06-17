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
      #"nosmt=force" # disable simultaneous multithreading(HT/smt)
      #
      "amd_pstate=guided" # Let TLP control pstate
      # Remove these - conflicts with TLP:
      # "processor.max_cstate=5"
      # "pcie_aspm=force" 
      # "amd_pstate_epp=performance"
      # "processor.ignore_ppc=1"
    ];
  };

  hardware.enableRedistributableFirmware = true;

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
  "/home/alice/Downloads" = {
    device = "/dev/disk/by-uuid/779e5b85-ffce-4a76-b86d-04d8a364bae7";
    fsType = "ext4";
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
      clickMethod = "clickfinger";
    };
  };

  # SYSTEM SERVICES
  # ---------------
  
  # Enhanced TLP configuration for better thermal management
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings - performance when plugged in
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 95;   # Full performance on AC
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;

      # Platform profile settings
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "quiet";

      # AMD GPU power management
      RADEON_DPM_PERF_LEVEL_ON_AC = "high";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
      RADEON_POWER_PROFILE_ON_AC = "high";
      RADEON_POWER_PROFILE_ON_BAT = "low";

      # PCIe power savings
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";

      # Restore device state on startup to ensure settings persist
      RESTORE_DEVICE_STATE_ON_STARTUP = true;
    };
  };

  services.power-profiles-daemon.enable = false;
 
# Battery alert service and timer
  systemd.user.services.battery-alert = {
    description = "Battery Critical Warning";
    wantedBy = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/scripts/battery-alert.sh";
      Environment = "DISPLAY=:0";
    };

    path = with pkgs; [
      xorg.xrandr
        libnotify
        gnugrep
        gnused
        coreutils
    ];
  };

  systemd.user.timers.battery-alert = {
    description = "Battery Check Timer";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "30s";
      AccuracySec = "1s";
    };
  };
  
  # Enable thermald for thermal monitoring and management
  services.thermald.enable = true;

  # Audio with PipeWire
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Peripheral device support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        EnableIsoSockets = true;
      };
    };
  };
  services.udev.packages = with pkgs; [
    headsetcontrol
  ];

  # video/acc
  hardware.opengl = {
    enable = true;
    driSupport = true;
    extraPackages = with pkgs; [
      mesa.drivers
        libvdpau-va-gl
    ];
  };

  # NETWORKING
  # ----------
  
  networking = {
    hostName = "lenovo";
    useDHCP = lib.mkDefault true;
    wireless.enable = true;
    dhcpcd.extraConfig = "noipv6";
  };

  # First, make sure these packages are installed
  environment.systemPackages = with pkgs; [
    xorg.xinput
    evtest
    openssh
    lm_sensors  # For temperature monitoring
    powertop    # For power usage analysis
    bc          # Used in temperature monitoring script
    libnotify   # For desktop notifications
  ];

  # Create a systemd service to fix the touchpad after resume
  systemd.services.fix-touchpad = {
    description = "Fix touchpad after resume";
    after = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
    wantedBy = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
    environment = {
      DISPLAY = ":0";
      XAUTHORITY = "/home/alice/.Xauthority";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "alice";
      ExecStart = "${pkgs.bash}/bin/bash -c '\
        TOUCHPAD_ID=$(${pkgs.xorg.xinput}/bin/xinput list | ${pkgs.gnugrep}/bin/grep -i touchpad | ${pkgs.gnused}/bin/sed \"s/.*id=\\([0-9]*\\).*/\\1/\") && \
        ${pkgs.xorg.xinput}/bin/xinput disable $TOUCHPAD_ID && \
        sleep 1 && \
        ${pkgs.xorg.xinput}/bin/xinput enable $TOUCHPAD_ID && \
        ${pkgs.udev}/bin/udevadm trigger --subsystem-match=input \
      '";
    };
  };
  
  # Create a systemd service to monitor temperatures and notify if too high
  systemd.services.temp-monitor = {
    description = "Monitor system temperatures";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -c '\
        while true; do \
          CPU_TEMP=$(${pkgs.lm_sensors}/bin/sensors | grep \"Tctl\" | awk \"{print \\$2}\" | tr -d \"+°C\"); \
          if (( $(echo \"$CPU_TEMP > 80\" | ${pkgs.bc}/bin/bc -l) )); then \
            ${pkgs.libnotify}/bin/notify-send -u critical \"High CPU Temperature\" \"CPU temperature is $CPU_TEMP°C!\"; \
          fi; \
          sleep 60; \
        done \
      '";
      Restart = "always";
      RestartSec = "10s";
      User = "alice";
    };
    wantedBy = ["multi-user.target"];
  };

  # SECURITY
  # --------
  
  # sudo configuration - SECURITY ISSUE: passwordless sudo is a security risk
  security.sudo = {
    enable = true;
    extraConfig = ''
      alice ALL=(ALL) NOPASSWD: ALL
      user ALL=(ALL) NOPASSWD: ALL
    '';
  };
}
