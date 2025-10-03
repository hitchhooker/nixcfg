{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf optional optionals;
  inherit (builtins) pathExists elem readFile;

  # ────────── package sets ──────────
  stable    = import <nixos>           { inherit (config.nixpkgs) config; };
  unstable  = import <nixos-unstable>  { inherit (config.nixpkgs) config; };

  # ────────── hardware config ───────
  hwConfig = let
    specific = ./hardware/lenovo.nix;
  in if pathExists specific then specific else ./hardware/default.nix;

  # ────────── DNS ────────────────────
  dns = {
    servers = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ];
    options = [ "edns0" "trust-ad" "rotate" "timeout:2" "attempts:3" ];
  };

  # ────────── pcli wrapper ───────────
  pcli = pkgs.writeShellScriptBin "pcli" ''
    exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
      --library-path ${pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.openssl.out
        pkgs.zlib
        pkgs.glibc
        pkgs.gcc.cc.lib  # This provides libstdc++.so.6
      ]} \
      /home/alice/src/penumbra/target/release/pcli "$@"
  '';

  # ────────── universal binary runner ─
  run-binary = pkgs.writeShellScriptBin "run-binary" ''
    binary="$1"
    shift
    exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
      --library-path ${pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.openssl.out
        pkgs.zlib
        pkgs.glibc
        pkgs.gcc.cc.lib  # This provides libstdc++.so.6
        pkgs.libgcc.lib
        pkgs.xorg.libX11
        pkgs.xorg.libXcursor
        pkgs.xorg.libXrandr
        pkgs.xorg.libXi
      ]} \
      "$binary" "$@"
  '';

  # ────────── user-level bundles ────
  userPkgs = with unstable; {
    terminal = [ alacritty bottom tree zsh ];
    wm = [ 
      (pkgs.bspwm.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "rotkonetworks";
        repo = "bspwm";
        # nix-prefetch-git https://github.com/rotkonetworks/bspwm
        rev = "master";
        sha256 = "sha256-54NM7gP+VqylOKYGt5rv+f2zJc075iT020YUHrrNlks=";
      };
      }))
      dunst 
      (polybar.override { pulseSupport = true; }) 
      rofi 
      sxhkd 
    ];
    dev      = [ bun pnpm gh julia rust-analyzer rustfmt yarn polkadot ];
    comm     = [ beeper discord iamb signal-desktop slack telegram-desktop thunderbird whatsie ];
    media    = [ flameshot mpv ncspot peek obs-studio ];
    tools    = [ television age ];
    net      = [ wireguard-tools tailscale zerotierone ];
    ai       = [ ollama-rocm ];
    system   = [ dmidecode jq syncthing transmission_4-qt turbovnc websocat ];
    nix      = [ nix-index nix-direnv nix-prefetch-git ];
    deploy   = [ act deploy-rs ];
    # Estonian ID
    estonian-id = [ qdigidoc web-eid-app p11-kit opensc ];
  } // {
    stable = with stable; [
      (chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--force-dark-mode"
          "--enable-features=WebUIDarkMode"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--ignore-gpu-blocklist"
          "--enable-features=VaapiVideoDecoder"
        ];
      })
      element-desktop cinny-desktop google-cloud-sdk i3lock-fancy-rapid
      jmtpfs keepassxc libssh nodejs pavucontrol
      tigervnc xclip alsa-utils toybox pgcli
    ];
  };

  # ────────── system-level pkgs ─────
  sysPkgs = {
    unstable = with unstable; [
      # db
      sqlite pgcli distrobox claude-code
      # Core
      bash fd gcc git iputils neovim openssh ripgrep wget zellij zsh fzf
      # Rust toolchain
      rustup 
      # lazyvim lsp
      nixd
      # System tools
      inetutils fscrypt-experimental
      # Hardware monitoring
      lm_sensors nvme-cli dmidecode ryzenadj stress-ng s-tui btop bottom
      radeontop powertop intel-gpu-tools sysbench fwupd
      geekbench phoronix-test-suite inxi hwinfo cpu-x memtest86-efi
      hdparm smartmontools iotop sysstat ncdu
      # GUI/Desktop
      gtk-engine-murrine libsForQt5.qt5ct xorg.libX11
      # File management
      appimage-run gvfs shared-mime-info xfce.tumbler
      ffmpegthumbnailer libopenraw poppler
      # build deps for Rust FFI  
      binutils glibc pkg-config openssl libiconv cmake gnumake glib.dev
      llvmPackages.clang llvmPackages.libclang.lib
    ];
    stable = with stable; [
      lightdm parted screen
      ssh-agents sshfs vim xdotool
      podman podman-compose
      pcmanfm
      unzip
    ];
  };

  # ────────── env vars ──────────────
  envVars = {
    GTK_THEME              = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME   = "gtk2";
    BROWSER_DARK_MODE      = "1";
    FORCE_DARK_MODE        = "1";
    XDG_CURRENT_DESKTOP    = "BSPWM";
    SHELL                  = pkgs.zsh;
    CARGO_HOME             = "$HOME/.cargo";
    RUSTUP_HOME            = "$HOME/.rustup";
    SSH_AUTH_SOCK          = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  };

  # ────────── helper for user units ─
  mkUserService = name: cfg: {
    inherit (cfg) description;
    serviceConfig = cfg.exec;
    wantedBy      = cfg.targets or [ "default.target" ];
    after         = cfg.after   or [];
  };

  # ────────── user units ─────────────
  userServices = {
    ssh-agent = {
      description = "ssh authentication agent";
      exec = {
        Type      = "simple";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent.socket -D";
      };
    };
    xset-repeat = {
      description = "Set xset keyboard repeat rate";
      exec = {
        Type      = "oneshot";
        ExecStart = "${pkgs.xorg.xset}/bin/xset r rate 200 50";
      };
      after = [ "graphical-session.target" ];
    };
  };

  # ────────── dotfile map ────────────
  dotfiles = {
    ".zshrc"                = "zsh/.zshrc";
    ".config/nvim/"         = "nvim";
    ".config/alacritty/"    = "alacritty";
    ".config/dunst/"        = "dunst";
    ".config/rofi/"         = "rofi";
    ".config/polybar/"      = "polybar";
    ".config/bspwm/"        = "bspwm";
    ".config/sxhkd/"        = "sxhkd";
    ".config/greenclip.toml"= "greenclip.toml";
  };

in
{
  imports = [
    ./shell.nix
    ./wireguard.nix
    <home-manager/nixos>
    hwConfig
    <agenix/modules/age.nix>
  ];

  # ────────── nix settings ───────────
  nixpkgs.config = {
    allowUnfree           = true;
    allowUnfreePredicate  = pkg: elem (lib.getName pkg) [ "slack" "libsciter" ];
    permittedInsecurePackages = [ "libsoup-2.74.3" "qtwebengine-5.15.19" ];

  };

  nix = {
    package      = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
  };

  # ────────── networking ─────────────
  networking = {
    nameservers = dns.servers;
    resolvconf = { enable = true; extraOptions = dns.options; };
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

  # ────────── locale/console/fonts ───
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
    jetbrains-mono nerd-fonts.fira-code iosevka
    font-awesome font-awesome_6
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  console = { font = "Lat2-Terminus16"; useXkbConfig = true; };

  time.timeZone = "Asia/Bangkok";
  location       = { latitude = 13.7563; longitude = 99.5018; };

  # ────────── base system opts ───────
  system = {
    copySystemConfiguration = true;
    stateVersion            = "24.11";
  };

# ────────── env + pkgs ─────────────
  environment = let
# *.pc providers used by Rust FFI crates
    pcDeps = with pkgs; [
    openssl.dev
      sqlite.dev
      glib.dev
      gst_all_1.gstreamer.dev
      gst_all_1.gst-plugins-base.dev
      gst_all_1.gstreamer              # core libs
      gst_all_1.gst-plugins-base       # libgstapp-1.0.so.* lives here
      gst_all_1.gst-plugins-good       # common useful elements
      gst_all_1.gst-plugins-bad        # contains ximagesrc etc. you use
      # uncomment if you ever need proprietary codecs
      # gst_all_1.gst-plugins-ugly
      # gst_all_1.gst-libav
    ];
  pcPath = lib.makeSearchPath "lib/pkgconfig" pcDeps;
  in {
## global env vars
    variables = envVars // {
      TERMINAL            = "${pkgs.alacritty}/bin/alacritty";
    PKG_CONFIG_PATH     = pcPath;
    OPENSSL_DIR         = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR     = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
  };

## inherited session-only vars
  sessionVariables = { inherit (envVars) SSH_AUTH_SOCK; };

## packages plus a cargo wrapper
  systemPackages = sysPkgs.unstable ++ sysPkgs.stable ++ [
    pkgs.usbutils
    pkgs.esptool
    pkgs.picocom
    pcli
    run-binary
    (import ./dotfiles/wpa { inherit pkgs; })
    (pkgs.writeShellScriptBin "cargo-wrapped" ''
     export PATH="${pkgs.rustup}/bin:$PATH"
     export PKG_CONFIG_PATH="${pcPath}:$PKG_CONFIG_PATH"
     export OPENSSL_DIR="${pkgs.openssl.dev}"
     export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
     export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
     export SQLITE3_LIB_DIR="${pkgs.sqlite.out}/lib"
     export LD_LIBRARY_PATH="${pkgs.sqlite.out}/lib:${pkgs.openssl.out}/lib:${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
     export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
     export BINDGEN_EXTRA_CLANG_ARGS="-I${pkgs.glibc.dev}/include"
     exec ${pkgs.rustup}/bin/rustup run nightly cargo "$@"
     '')
  ];

## misc system-wide config files
  etc = {
    "pkcs11/modules/opensc-pkcs11".text =
      "module: ${pkgs.opensc}/lib/opensc-pkcs11.so";
    "chromium/native-messaging-hosts/eu.webeid.json".source =
      "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
    "opt/chrome/native-messaging-hosts/eu.webeid.json".source =
      "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  };
  };

# ────────── users ──────────────────
  users = {
    mutableUsers = true;
    users.alice = {
      isNormalUser = true;
      home         = "/home/alice";
      shell        = pkgs.zsh;
      extraGroups  = [ "wheel" "podman" "dialout" ];
      packages     = lib.flatten (lib.attrValues userPkgs);
    };
  };

  security = {
    sudo = {
      enable      = true;
      extraConfig = "alice ALL=(ALL) NOPASSWD: ALL";
    };
    wrappers.ping = {
      source = "${pkgs.iputils}/bin/ping";
      owner  = "root"; group = "root"; setuid = true;
    };
  };

# ────────── home-manager part ──────
  home-manager.users.alice = {
    services.syncthing.enable = true;
    home = { stateVersion = "24.11"; enableNixpkgsReleaseCheck = false; };
  };

# ────────── services (excerpt) ─────
  services = {
    dbus.packages   = [ pkgs.xfce.tumbler ];
    udev.packages   = [ pkgs.ledger-udev-rules ];
    tailscale.enable = true;
#greenclip.enable = true;
    syncthing.enable = false;

    fwupd.enable      = true;
    udisks2.enable    = true;
    pcscd.enable      = true;   # Estonian ID

      redshift = { enable = true; temperature = { day = 2900; night = 2700; }; };

    logind.settings.Login.HandlePowerKey = "ignore";

    openssh = {
      enable   = true;
      settings = {
        PermitRootLogin        = "no";
        PasswordAuthentication = false;
      };
    };

    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
      deviceSection = ''
        Option "TearFree" "true"
        Option "VariableRefresh" "true"
        '';
      xkb = { layout = "us,fi"; options = "grp:win_space_toggle"; };
      displayManager.lightdm.enable = true;
      windowManager.bspwm = {
        enable = true;
        package = pkgs.bspwm.overrideAttrs (old: {
            src = pkgs.fetchFromGitHub {
            owner = "rotkonetworks";
            repo = "bspwm";
            rev = "master";
            sha256 = "sha256-54NM7gP+VqylOKYGt5rv+f2zJc075iT020YUHrrNlks=";
            };
            });
      };
    };

    # ────────── ollama service ─────────
    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "127.0.0.1";
      port = 11434;
    };


    acpid.enable = true;
  };

# ────────── systemd user units ─────
  systemd.user.services = lib.mapAttrs mkUserService userServices // {
    tearfree = {
      description = "Enable AMD TearFree";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.xorg.xrandr}/bin/xrandr --output eDP --set TearFree on";
        RemainAfterExit = true;
      };
    };
  };

# ────────── desktop programs ───────
  programs = {
    appimage = { enable = true; binfmt = true; };
    chromium = {
      enable = true;
      extensions = [
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium-C
          "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
          "damllfnhhcbmclmjilomenbhkappdjgb" # Parity Signer Companion
          "oboonakemofpalcgghocfoadofidjkkk" # KeepassXC
          "gobmdjdemnlkgfcgmhmmojgaebfediog" # Manage tabs by domain MV3
          "ginchbkmljhldofnbjabmeophlhdldgp" # polkagate-js
          "lkpmkhpnhknhmibgnmmhdhgdilepfghe" # Prax wallet
          "dmkamcknogkgcdfhhbddcghachkejeap" # Kepler wallet
      ];
    };

    firefox = {
      enable  = true;
      package = pkgs.librewolf;
      nativeMessagingHosts.packages = [ pkgs.web-eid-app ];
      policies = {
        SecurityDevices.p11-kit-proxy = "${pkgs.p11-kit}/lib/p11-kit-proxy.so";
        DisableTelemetry              = true;
        DisableFirefoxStudies         = true;
        Preferences = {
          "cookiebanners.service.mode.privateBrowsing" = 2;
          "cookiebanners.service.mode"                 = 2;
          "privacy.donottrackheader.enabled"           = true;
          "privacy.fingerprintingProtection"           = true;
          "privacy.resistFingerprinting"               = false;
          "privacy.trackingprotection.emailtracking.enabled" = true;
          "privacy.trackingprotection.enabled"         = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "webgl.disabled"                             = false;
          "privacy.clearOnShutdown.cookies"            = false;
          "network.cookie.lifetimePolicy"              = 0;
        };
        ExtensionSettings."uBlock0@raymondhill.net" = {
          install_url        = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode  = "force_installed";
        };
      };
    };

    gnupg.agent  = { enable = true; enableSSHSupport = false; };
    mtr.enable   = true;
    
    # ────────── Enhanced nix-ld ──────────
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Basic runtime
        stdenv.cc.cc.lib
        glibc
        zlib
        
        # Common dependencies
        openssl
        curl
        expat
        freetype
        glib
        libuuid
        libgcc.lib
        
        # GUI libraries
        libGL
        libxkbcommon
        fontconfig
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libxcb
        xorg.libXext
        xorg.libXfixes
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXtst
        xorg.libXScrnSaver
        xorg.libXau
        xorg.libXdmcp
        xorg.libXinerama
        xorg.libXxf86vm
        
        # Wayland
        wayland
        
        # Additional common libs
        bzip2
        pcre
        pcre2
        ncurses
        readline
        sqlite
        libxml2
        libxslt
        icu
        harfbuzz
        pango
        cairo
        gdk-pixbuf
        gtk3
        dbus
        at-spi2-core
        at-spi2-atk
        
        # Audio
        alsa-lib
        pulseaudio
        
        # Compression
        lz4
        xz
        
        # Crypto
        libgcrypt
        libgpg-error
        
        # Networking
        libssh2
        nghttp2
        
        # System
        systemd
        libcap
        util-linux.lib
        libffi
        libtasn1
        p11-kit
      ];
    };
    
    zsh.enable   = true;
  };

# ────────── containers / virt ──────
  virtualisation.podman = { enable = true; dockerCompat = true; };

# ────────── activation scripts ─────
  system.activationScripts.linkDotfiles = ''
    mkdir -p /home/alice/.config
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
        (dest: src:
         "ln -sf${if lib.hasSuffix "/" dest then "n" else ""} /etc/nixos/dotfiles/${src} /home/alice/${dest}"
        ) dotfiles)}
  chown -R alice:users /home/alice/.config /home/alice/.zshrc
    chmod -R u+x /home/alice/.config/{bspwm,sxhkd}/scripts
    '';

  system.activationScripts.terminalEmulator = ''
    mkdir -p /usr/bin
    ln -sf ${pkgs.alacritty}/bin/alacritty /usr/bin/x-terminal-emulator
    '';
}
