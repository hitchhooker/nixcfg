{ config, lib, pkgs, ... }:

let
  hostSpecificHardwareConfig = ./hardware/lenovo.nix;
  useHostConfig = if builtins.pathExists hostSpecificHardwareConfig 
                  then hostSpecificHardwareConfig 
                  else ./hardware/default.nix;
  stable = import <nixos> { config = config.nixpkgs.config; };
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  # imports
  imports = [ ./shell.nix <home-manager/nixos> useHostConfig <agenix/modules/age.nix>
  ];

  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
      '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "slack"
    "libsciter"
  ];

  networking = {
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
    resolvconf = {
      enable = true;
      extraOptions = [
        "edns0"            # enable DNS extensions
        "trust-ad"         # accept authenticated data flag for DNSSEC
        "rotate"           # rotate through nameservers for load balancing
        "timeout:2"        # faster timeout for DNS queries
        "attempts:3"       # number of retries
      ];
    };
    networkmanager.dns = "none";  # prevent NetworkManager from managing DNS
    dhcpcd.extraConfig = ''
      nohook resolv.conf # disable local DNS
      noipv4ll  # disable IPv4 Link-Local
    '';
    firewall = {
      allowedTCPPorts = [ 22 80 443 22000 5222 5223 5269 5280 ];
      allowedUDPPorts = [ 21027 51280 ];
    };
  };

  # fonts
  fonts = {
    packages = with pkgs; [
#      nerd-fonts
      nerd-fonts.iosevka
      nerd-fonts.fira-code
      iosevka
#     icons 
      font-awesome
    ];
  };

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  time.timeZone = "Asia/Bangkok";

  system.copySystemConfiguration = true;
  system.stateVersion = "24.11";

  environment.variables = {
    GTK_THEME = "Adwaita:dark";              # forces GTK apps to use a dark theme
    QT_QPA_PLATFORMTHEME = "gtk2";           # ensures Qt apps follow GTK themes
    BROWSER_DARK_MODE = "1";                 # darkm
    FORCE_DARK_MODE = "1";                   # dakrm
    XDG_CURRENT_DESKTOP = "BSPWM";           # helps some apps detect the desktop environment
    #MOZ_ENABLE_WAYLAND = "1";                # optional for Wayland setups
    SHELL = pkgs.zsh;
  };

  # User configuration
  users.mutableUsers = true;

  users.users.alice = {
    isNormalUser = true;
    home = "/home/alice";
    #hashedPassword = lib.mkIf (builtins.pathExists config.age.secrets.alice-hash.path)
    #  (lib.strings.removeSuffix "\n" (builtins.readFile config.age.secrets.alice-hash.path));
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" ];

    # User-specific packages
    packages = with pkgs; 
    (with unstable; [
     alacritty bspwm bun bottom
     discord dunst dmidecode julia
     flameshot gh polybar rofi
     signal-desktop sxhkd syncthing
     telegram-desktop tree zsh yarn
     transmission_4-qt firefox iamb
     keepassxc beeper slack iamb ncspot
     tailscale jq websocat busybox
     thunderbird turbovnc whatsie
    ] ++
    (with stable; [
     google-cloud-sdk i3lock-fancy-rapid
     libssh nodejs pavucontrol alsa-utils
     python313Full xclip mpv element-desktop
     jmtpfs
     (chromium.override {
      commandLineArgs = [
      "--force-dark-mode"
      "--enable-features=WebUIDarkMode"
      ];
      })
    ])) ++ [
      (stable.python3.withPackages (ps: with ps; [ ps.ansible ps.pip ]))
    ];
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      alice ALL=(ALL) NOPASSWD: ALL
    '';
  };
  security.wrappers.ping = {
    source = "${pkgs.iputils}/bin/ping";
    owner = "root";
    group = "root";
    setuid = true;
  };

  home-manager.users.alice = {
    services.syncthing.enable = true;
    home.stateVersion = "24.11";
    home.enableNixpkgsReleaseCheck = false; # Disable warning
  };

  # system packages
  environment.systemPackages = with pkgs; [
    # unstable packages
    unstable.redshift unstable.iputils unstable.headsetcontrol
    unstable.bash unstable.cargo unstable.gcc unstable.fd unstable.git
    unstable.lm_sensors unstable.neovim unstable.openssh unstable.ripgrep
    unstable.rustup unstable.wget unstable.zellij unstable.zsh
    unstable.xorg.libX11 unstable.brightnessctl unstable.home-manager
    unstable.gtk-engine-murrine unstable.libsForQt5.qt5ct
    unstable.tailscale
    unstable.yazi
    unstable.pcmanfm              # file-explorer
    unstable.gvfs                 # mounting 
    unstable.xfce.tumbler         # thumbnails
    unstable.ffmpegthumbnailer    # video thumbnails
    unstable.poppler              # PDF thumbnails
    unstable.libopenraw           # RAW image support
    unstable.shared-mime-info     # extra MIME types

    unstable.ledger-live-desktop  # ledger live desktop application
    unstable.age-plugin-ledger    # if you use age encryption with your ledger
    unstable.ledger-agent         # use ledger as hardware ssh/pgp agent

    # stable packages
    stable.docker
    stable.docker-compose
    stable.ssh-agents
    stable.lightdm
    stable.parted
    stable.screen
    stable.sshfs
    stable.pkg-config
    stable.vim
  ];

  location = {
    latitude = 13.7563;
    longitude = 99.5018;
  };

  # Services
  services = {
    dbus.packages = [ pkgs.xfce.tumbler ];
    udev.packages = [
      pkgs.ledger-udev-rules # ensures ledger devices are recognized
    ];
    # location.provider = "geoclue2";
    tailscale = { enable = true; };
    redshift = {
      enable = true;
      temperature = {
        day = 2900;
        night = 2700;
      };
      # Bangkok coordinates
    };
    logind = {
      powerKey = "ignore";
      # lidSwitch = "ignore";
    };
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "us,fi";
        options = "grp:win_space_toggle";
      };
      windowManager.bspwm.enable = true;
      displayManager.lightdm.enable = true;
    };
    syncthing.enable = false;
    greenclip.enable = true;
    acpid = {
      enable = true;
      #extraRules = ''
      #  event=button/lid.*
      #  action=${pkgs.i3lock}/bin/i3lock 3 5
      #  '';
    };
  };
  systemd.user.services = {
    i3lock-on-lid = {
      description = "Lock screen on lid close";
      serviceConfig = {
        ExecStart = "${pkgs.i3lock}/bin/i3lock 3 5";
      };
      wantedBy = [ "suspend.target" ]; # Trigger on lid events
    };
  };

  programs = {
    chromium = {
      enable = true;
      extensions = [
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium-C
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "damllfnhhcbmclmjilomenbhkappdjgb" # Parity Signer Companion
        "khccbhhbocaaklceanjginbdheafklai" # Substrate connect
        "oboonakemofpalcgghocfoadofidjkkk" # KeepassXC
        "gobmdjdemnlkgfcgmhmmojgaebfediog" # manage tabs by domain mv3
        "mopnmbcafieddcagagdcbnhejhlodfdd" # Polkadot-js
        "lkpmkhpnhknhmibgnmmhdhgdilepfghe" # Prax wallet
        "dmkamcknogkgcdfhhbddcghachkejeap" # Kepler wallet
      ];
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };
    mtr.enable = true;
    nix-ld.enable = true;
    #ssh.startAgent = true;
    zsh.enable = true;
  };

  systemd.user.services.ssh-agent = {
    description = "SSH authentication agent";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent.socket -D";
      Type = "simple";
    };
  };

  environment.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  };

  virtualisation.docker = {
    enable = true;
  };

  # activation script
  system.activationScripts.linkDotfiles = ''
    # faster keyboardscroll
    # xset r rate 200 50

    # Create necessary directories
    mkdir -p /home/alice/.config

    # Symlink files and directories
    ln -sf /etc/nixos/dotfiles/zsh/.zshrc /home/alice/.zshrc
    ln -sfn /etc/nixos/dotfiles/nvim /home/alice/.config/nvim
    ln -sfn /etc/nixos/dotfiles/alacritty /home/alice/.config/alacritty
    ln -sfn /etc/nixos/dotfiles/dunst /home/alice/.config/dunst
    ln -sfn /etc/nixos/dotfiles/rofi /home/alice/.config/rofi
    ln -sfn /etc/nixos/dotfiles/polybar /home/alice/.config/polybar
    ln -sfn /etc/nixos/dotfiles/bspwm /home/alice/.config/bspwm
    ln -sfn /etc/nixos/dotfiles/sxhkd /home/alice/.config/sxhkd
    ln -sf /etc/nixos/dotfiles/greenclip.toml /home/alice/.config/greenclip.toml

    # Ensure ownership and permissions
    chown -R alice:users /home/alice/.config
    chown alice:users /home/alice/.zshrc

    # Set executable permissions on scripts if necessary
    chmod -R u+x /home/alice/.config/bspwm/scripts
    chmod -R u+x /home/alice/.config/sxhkd/scripts

  '';
}
