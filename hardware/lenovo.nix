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
      "amdgpu.tearfree=1"
      # GPU configuration
      "radeon.si_support=0"
      "amdgpu.si_support=1"
      "radeon.cik_support=0"
      "amdgpu.cik_support=1"
      "amdgpu.dc=1"
      # touchpad bug
      "psmouse.synaptics_intertouch=0"
      "psmouse.resetafter=0"
      # CPU thermal management
      "amd_pstate=passive"
      "processor.max_cstate=3"
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
    { device = "/dev/disk/by-uuid/409f0d77-34ae-476e-9ef0-f960a84bbac5"; }
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
      mesa
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

  # Enhanced TLP configuration for aggressive thermal management
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings - aggressive limits to prevent overheating
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Aggressive CPU performance limits
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 50;  # Very conservative
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 40;
      
      # Disable turbo boost completely
      CPU_BOOST_ON_AC = 0;
      CPU_BOOST_ON_BAT = 0;

      # Platform profile settings
      PLATFORM_PROFILE_ON_AC = "quiet";
      PLATFORM_PROFILE_ON_BAT = "quiet";

      # AMD GPU power management
      RADEON_DPM_PERF_LEVEL_ON_AC = "low";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
      RADEON_POWER_PROFILE_ON_AC = "low";
      RADEON_POWER_PROFILE_ON_BAT = "low";

      # PCIe power savings
      PCIE_ASPM_ON_AC = "powersupersave";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Restore device state on startup
      RESTORE_DEVICE_STATE_ON_STARTUP = 1;
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

  # CPU temperature monitoring and throttling
  systemd.services.cpu-thermal-monitor = {
    description = "CPU Thermal Monitor";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeScript "thermal-monitor" ''
        #!${pkgs.bash}/bin/bash
        
        while true; do
          # Get CPU temp
          temp=$(${pkgs.lm_sensors}/bin/sensors | grep -E "Tctl|temp1" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
          
          if [ -n "$temp" ] && [ "$temp" -gt 75 ]; then
            echo "High CPU temp: $temp°C - Limiting frequency"
            # Force lowest performance state
            echo "powersave" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
            echo "0" > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
          fi
          
          sleep 5
        done
      '';
      Restart = "always";
    };
  };

  # Enable thermald for thermal monitoring
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

  # NETWORKING
  # ----------

  networking = {
    hostName = "lenovo";
    useDHCP = lib.mkDefault true;
    wireless.enable = true;
    dhcpcd.extraConfig = "noipv6";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    xorg.xinput
    evtest
    openssh
    lm_sensors
    powertop
    bc
    libnotify
    linuxPackages.cpupower
    s-tui
  ];

  services.acpid = {
    enable = true;
    lidEventCommands = ''
      ${pkgs.kmod}/bin/modprobe -r i2c_hid_acpi
      ${pkgs.kmod}/bin/modprobe i2c_hid_acpi
    '';
  };

  # Fix touchpad after resume
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

  # SECURITY
  # --------

  # sudo configuration
  security.sudo = {
    enable = true;
    extraConfig = ''
      alice ALL=(ALL) NOPASSWD: ALL
      user ALL=(ALL) NOPASSWD: ALL
    '';
  };
}
