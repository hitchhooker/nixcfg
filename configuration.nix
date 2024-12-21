{ config, lib, pkgs, ... }:

let
  aliceSecret = import /etc/secrets/alice-hash.nix;
  wifiSecret = import /etc/secrets/wifi-networks.nix;
  hostSpecificHardwareConfig = ./machines/lenovo.nix;
  useHostConfig = if builtins.pathExists hostSpecificHardwareConfig 
                  then hostSpecificHardwareConfig 
                  else ./machines/default.nix;
  stable = import <nixos> { config = config.nixpkgs.config; };
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  # imports
  imports = [ ./aliases.nix <home-manager/nixos> useHostConfig ];

  # Nix settings
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "slack"
  ];

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  time.timeZone = "Asia/Bangkok";

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Iosevka" "IosevkaTerm" "FiraCode" "Hack" ]; })
    nerdfonts font-awesome iosevka dejavu_fonts
  ];

  system.copySystemConfiguration = true;
  system.stateVersion = "24.05";

  # Networking
  networking = {
    wireless = {
      enable = true;
      networks = wifiSecret.wifiNetworks;
    };

    firewall = {
      allowedTCPPorts = [ 22 80 443 22000 5222 5223 5269 5280 ];
      allowedUDPPorts = [ 21027 51280 ];
    };
  };

  # Environment Variables for Dark Mode
  environment.variables = {
    GTK_THEME = "Adwaita:dark";               # Forces GTK apps to use a dark theme
    QT_QPA_PLATFORMTHEME = "gtk2";           # Ensures Qt apps follow GTK themes
    XDG_CURRENT_DESKTOP = "BSPWM";           # Helps some apps detect the desktop environment
    MOZ_ENABLE_WAYLAND = "1";                # Optional for Wayland setups
  };

  # User configuration
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = false;

  users.users.alice = {
    isNormalUser = true;
    home = "/home/alice";
    hashedPassword = aliceSecret.hashedPassword;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];

    # User-specific packages
    packages = with pkgs; [
      # Unstable packages
      unstable.alacritty unstable.bspwm unstable.bun #unstable.ungoogled-chromium
      unstable.dunst unstable.element-desktop unstable.flameshot unstable.gh
      unstable.polybar unstable.rofi unstable.signal-desktop unstable.sxhkd
      unstable.syncthing unstable.telegram-desktop unstable.tree unstable.zsh
      unstable.yarn unstable.transmission_4-qt unstable.firefox

      # Stable packages
      stable.electrum stable.google-cloud-sdk stable.i3lock-fancy-rapid
      stable.libssh stable.keepassxc stable.nodejs stable.pavucontrol
      stable.python313Full stable.xclip stable.chromium

      # Stable Python packages
      (stable.python3.withPackages (ps: with ps; [ ps.ansible ps.pip ]))
    ];
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      alice ALL=(ALL) NOPASSWD: ALL
    '';
  };

  home-manager.users.alice = {
    services.syncthing.enable = true;
    home.stateVersion = "24.05";
  };

  # System packages
  environment.systemPackages = with pkgs; [
#    (pkgs.chromium.overrideAttrs (old: rec {
#                                  postInstall = old.postInstall or "" + ''
#                                  wrapProgram "$out/bin/chromium" --add-flags \
#                                  "--enable-features=WebUIDarkMode --force-dark-mode"
#                                  '';
#                                  }))
    # Unstable packages
    unstable.bash unstable.cargo unstable.gcc unstable.fd unstable.git
    unstable.lm_sensors unstable.neovim unstable.openssh unstable.ripgrep
    unstable.rustup unstable.wget unstable.zellij unstable.zsh
    unstable.xorg.libX11 unstable.brightnessctl unstable.home-manager
    unstable.gtk-engine-murrine unstable.libsForQt5.qt5ct

    # Stable packages
    stable.lightdm stable.parted stable.screen stable.ssh-agents
    stable.sshfs stable.pkg-config
  ];

  environment.shells = [ pkgs.zsh pkgs.bash ];
  environment.variables.SHELL = pkgs.zsh;

  # Services
  services = {
    logind = {
      powerKey = "ignore";
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
  };

  systemd.user.services = {
    i3lock-on-lid = {
   j  description = "Lock screen on lid close";
      serviceConfig = {
        ExecStart = "${pkgs.i3lock}/bin/i3lock-fancy-rapid 3 5";
      };
      wantedBy = [ "sleep.target" ]; # Trigger on lid events
    };
  };

  programs = {
    zsh.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    chromium = {
      enable = true;
      extensions = [
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium-C
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "damllfnhhcbmclmjilomenbhkappdjgb" # Parity Signer Companion
        "mopnmbcafieddcagagdcbnhejhlodfdd" # Polkadot-js
        "oboonakemofpalcgghocfoadofidjkkk" # KeepassXC
      ];
    };
  };

  # Activation script
  system.activationScripts.linkDotfiles = ''
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
