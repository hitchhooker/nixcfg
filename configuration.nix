{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf optional optionals;
  inherit (builtins) pathExists elem readFile;

  # Package sets
  stable = import <nixos> { inherit (config.nixpkgs) config; };
  unstable = import <nixos-unstable> { inherit (config.nixpkgs) config; };

  # Hardware config selection
  hwConfig = let
    specific = ./hardware/lenovo.nix;
  in if pathExists specific then specific else ./hardware/default.nix;

  # DNS configuration
  dns = {
    servers = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ];
    options = [ "edns0" "trust-ad" "rotate" "timeout:2" "attempts:3" ];
  };

  # User packages organized by category
  userPkgs = with unstable; {
    terminal = [ alacritty bottom tree zsh ];
    wm = [ bspwm dunst polybar rofi sxhkd ];
    dev = [ bun gh julia rust-analyzer rustfmt clippy yarn polkadot ];
    comm = [ beeper discord iamb signal-desktop slack telegram-desktop thunderbird whatsie ];
    media = [ flameshot mpv ncspot ];
    system = [ dmidecode jq syncthing tailscale transmission_4-qt turbovnc websocat ];
    # Estonian ID packages
    estonian-id = [ qdigidoc web-eid-app p11-kit opensc ];
  } // {
    stable = with stable; [
      (chromium.override {
        enableWideVine = true;
        commandLineArgs = [ "--force-dark-mode" "--enable-features=WebUIDarkMode" ];
      })
      element-desktop google-cloud-sdk i3lock-fancy-rapid
      jmtpfs keepassxc libssh nodejs pavucontrol
      tigervnc xclip alsa-utils
      (python3.withPackages (ps: [ ps.ansible ps.pip ]))
      python313Full
    ];
  };

  # System packages
  sysPkgs = {
    unstable = with unstable; [
      # Core
      bash fd gcc git iputils neovim openssh ripgrep wget zellij zsh
      # System tools
      age-plugin-ledger brightnessctl headsetcontrol home-manager
      ledger-agent ledger-live-desktop lm_sensors mdbook redshift
      tailscale yazi
      # GUI/Desktop
      gtk-engine-murrine libsForQt5.qt5ct xorg.libX11
      # File management
      appimage-run gvfs pcmanfm shared-mime-info xfce.tumbler
      ffmpegthumbnailer libopenraw poppler
      # Rust toolchain
      rustc cargo rustup binutils glibc pkg-config openssl
      libiconv cmake gnumake llvmPackages.clang
    ];
    stable = with stable; [
      docker docker-compose lightdm parted screen
      ssh-agents sshfs vim
    ];
  };

# nothing else touched

  # Environment variables
  envVars = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk2";
    BROWSER_DARK_MODE = "1";
    FORCE_DARK_MODE = "1";
    XDG_CURRENT_DESKTOP = "BSPWM";
    SHELL = pkgs.zsh;
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  };

  # Service configurations
  mkUserService = name: cfg: {
    inherit (cfg) description;
    serviceConfig = cfg.exec;
    wantedBy = cfg.targets or [ "default.target" ];
    after = cfg.after or [];
  };

  userServices = {
    ssh-agent = {
      description = "ssh authentication agent";
      exec = {
        Type = "simple";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent.socket -D";
      };
    };
    xset-repeat = {
      description = "Set xset keyboard repeat rate";
      exec = {
        Type = "oneshot";
        ExecStart = "${pkgs.xorg.xset}/bin/xset r rate 200 50";
      };
      after = [ "graphical-session.target" ];
    };
  };
  
  security.pam.services.i3lock = {};
  
  # Dotfile mappings
  dotfiles = {
    ".zshrc" = "zsh/.zshrc";
    ".config/nvim/" = "nvim";
    ".config/alacritty/" = "alacritty";
    ".config/dunst/" = "dunst";
    ".config/rofi/" = "rofi";
    ".config/polybar/" = "polybar";
    ".config/bspwm/" = "bspwm";
    ".config/sxhkd/" = "sxhkd";
    ".config/greenclip.toml" = "greenclip.toml";
  };

in {
  imports = [
    ./shell.nix
    <home-manager/nixos>
    hwConfig
    <agenix/modules/age.nix>
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: elem (lib.getName pkg) [ "slack" "libsciter" ];
  };

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
  };

  networking = {
    nameservers = dns.servers;
    resolvconf = {
      enable = true;
      extraOptions = dns.options;
    };
    networkmanager.dns = "none";
    dhcpcd.extraConfig = ''
      nohook resolv.conf
      noipv4ll
    '';
    firewall = {
      allowedTCPPorts = [ 22 80 443 22000 5222 5223 5269 5280 ];
      allowedUDPPorts = [ 21027 51280 ];
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
    nerd-fonts.fira-code
    iosevka
    font-awesome
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  time.timeZone = "Asia/Bangkok";
  location = { latitude = 13.7563; longitude = 99.5018; };

  system = {
    copySystemConfiguration = true;
    stateVersion = "24.11";
  };

  environment = {
    variables = envVars;
    sessionVariables = { inherit (envVars) SSH_AUTH_SOCK; };
    systemPackages = sysPkgs.unstable ++ sysPkgs.stable;
    etc = {
      "pkcs11/modules/opensc-pkcs11".text = ''
        module: ${pkgs.opensc}/lib/opensc-pkcs11.so
        '';
      "chromium/native-messaging-hosts/eu.webeid.json".source = 
        "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
      "opt/chrome/native-messaging-hosts/eu.webeid.json".source = 
        "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
    };
  };

  users = {
    mutableUsers = true;
    users.alice = {
      isNormalUser = true;
      home = "/home/alice";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" ];
      packages = lib.flatten (lib.attrValues userPkgs);
    };
  };

  security = {
    sudo = {
      enable = true;
      extraConfig = "alice ALL=(ALL) NOPASSWD: ALL";
    };
    wrappers.ping = {
      source = "${pkgs.iputils}/bin/ping";
      owner = "root";
      group = "root";
      setuid = true;
    };
  };

  home-manager.users.alice = {
    services.syncthing.enable = true;
    home = {
      stateVersion = "24.11";
      enableNixpkgsReleaseCheck = false;
    };
  };

  services = {
    dbus.packages = [ pkgs.xfce.tumbler ];
    udev.packages = [ pkgs.ledger-udev-rules ];

    tailscale.enable = true;
    greenclip.enable = true;
    syncthing.enable = false;
    
    # Estonian ID card support
    pcscd.enable = true;

    redshift = {
      enable = true;
      temperature = { day = 2900; night = 2700; };
    };

    logind.powerKey = "ignore";

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
      displayManager.lightdm.enable = true;
      windowManager.bspwm.enable = true;
    };

    acpid = {
      enable = true;
    };
  };

  systemd.user.services = lib.mapAttrs mkUserService userServices;

  programs = {
    appimage = { enable = true; binfmt = true; };
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
    
    # LibreWolf with Estonian ID support
    firefox = {
      enable = true;
      package = pkgs.librewolf;
      nativeMessagingHosts.packages = [ pkgs.web-eid-app ];
      policies = {
        SecurityDevices.p11-kit-proxy = "${pkgs.p11-kit}/lib/p11-kit-proxy.so";
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        Preferences = {
          "cookiebanners.service.mode.privateBrowsing" = 2;
          "cookiebanners.service.mode" = 2;
          "privacy.donottrackheader.enabled" = true;
          "privacy.fingerprintingProtection" = true;
          "privacy.resistFingerprinting" = false; # Disable to allow Estonian ID
          "privacy.trackingprotection.emailtracking.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          # Estonian ID specific
          "webgl.disabled" = false;
          "privacy.clearOnShutdown.cookies" = false;
          "network.cookie.lifetimePolicy" = 0;
        };
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
    };
    
    gnupg.agent = { enable = true; enableSSHSupport = false; };
    mtr.enable = true;
    nix-ld.enable = true;
    zsh.enable = true;
  };

  virtualisation.docker.enable = true;

  system.activationScripts.linkDotfiles = ''
    mkdir -p /home/alice/.config
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (dest: src:
      "ln -sf${if lib.hasSuffix "/" dest then "n" else ""} /etc/nixos/dotfiles/${src} /home/alice/${dest}"
    ) dotfiles)}
    chown -R alice:users /home/alice/.config /home/alice/.zshrc
    chmod -R u+x /home/alice/.config/{bspwm,sxhkd}/scripts
  '';
}
