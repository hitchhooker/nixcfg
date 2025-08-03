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
      # CPU configuration
      "amd_pstate=passive"  # Better power management for Ryzen
      "processor.max_cstate=3"  # Limit deep C-states that can cause heat spikes
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

  # Enhanced TLP configuration for better thermal management
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings - limit performance to reduce heat
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Reduce max CPU performance when plugged in
      CPU_MIN_PERF_ON_AC = 20;
      CPU_MAX_PERF_ON_AC = 70;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;
      
      # Disable CPU boost to prevent overheating
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

      # Restore device state on startup to ensure settings persist
      RESTORE_DEVICE_STATE_ON_STARTUP = true;
    };
  };

  services.power-profiles-daemon.enable = false;

  # CPU temperature throttling service
  systemd.services.cpu-temp-throttle = {
    description = "CPU Temperature Throttling";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/scripts/cpu-temp-throttle.sh";
      Restart = "always";
      RestartSec = "5s";
    };
    
    path = with pkgs; [
      bc
      cpupower
      coreutils
      gnugrep
      gnused
      lm_sensors
    ];
  };

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
    cpupower    # For CPU frequency control
    s-tui       # For stress testing and monitoring
  ];

  services.acpid = {
    enable = true;
    lidEventCommands = ''
      ${pkgs.kmod}/bin/modprobe -r i2c_hid_acpi
      ${pkgs.kmod}/bin/modprobe i2c_hid_acpi
    '';
  };

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

  # Create temperature throttling script
  system.activationScripts.cpuTempThrottle = ''
    mkdir -p /etc/nixos/scripts
    cat > /etc/nixos/scripts/cpu-temp-throttle.sh << 'SCRIPT_EOF'
#!/bin/bash

# Temperature thresholds (in Celsius)
TEMP_HIGH=75
TEMP_CRITICAL=85
TEMP_LOW=65

# Get current CPU temperature
get_temp() {
    # Try different sensors
    temp=$(sensors | grep -E "(Tctl|Package id 0|Core 0)" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
    if [ -z "$temp" ]; then
        # Fallback to thermal zone
        temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1)
        temp=$((temp / 1000))
    fi
    echo $temp
}

# Main loop
while true; do
    current_temp=$(get_temp)
    
    if [ -z "$current_temp" ]; then
        echo "Failed to read temperature"
        sleep 5
        continue
    fi
    
    echo "Current CPU temp: $\{current_temp}°C"
    
    if [ $current_temp -ge $TEMP_CRITICAL ]; then
        echo "CRITICAL: Temp >= $\{TEMP_CRITICAL}°C, setting minimum frequency"
        cpupower frequency-set -u 1.4GHz
    elif [ $current_temp -ge $TEMP_HIGH ]; then
        echo "HIGH: Temp >= $\{TEMP_HIGH}°C, limiting to 2.0GHz"
        cpupower frequency-set -u 2.0GHz
    elif [ $current_temp -le $TEMP_LOW ]; then
        echo "NORMAL: Temp <= $\{TEMP_LOW}°C, allowing up to 2.8GHz"
        cpupower frequency-set -u 2.8GHz
    fi
    
    sleep 3
done
SCRIPT_EOF
    chmod +x /etc/nixos/scripts/cpu-temp-throttle.sh
  '';

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
