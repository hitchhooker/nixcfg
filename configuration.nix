{ config, lib, pkgs, ... }:

{
  # imports
  imports = [ ./aliases.nix ./hardware.nix <home-manager/nixos> ];

  # system.nix
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;   # xkb options in tty
  };

  # fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Iosevka" "IosevkaTerm" "FiraCode" "Hack" ]; })
    nerdfonts font-awesome iosevka dejavu_fonts
  ];

  system.copySystemConfiguration = true;
  system.stateVersion = "24.05";  # For upgrade security

  # network.nix
  networking = {
    wireless.enable = true;   # Use wpa_supplicant for wireless
    firewall = {
      allowedTCPPorts = [ 22 80 443 22000 ];
      allowedUDPPorts = [ 21027 51280 ];
    };
  };
  time.timeZone = "Asia/Bangkok";

  # home.nix
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = false;


  let
    aliceSecret = import /etc/secrets/alice-hash.nix;
  in
  users.users.alice = {
    isNormalUser = true;
    home = "/home/alice";
    hashedPassword = aliceSecret.hashedPassword;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];

    # User-specific packages
    packages = with pkgs; [
      alacritty bspwm bun chromium dunst element-desktop google-cloud-sdk
      i3lock-fancy-rapid keepassxc nodejs polybar rofi signal-desktop sxhkd
      syncthing telegram-desktop tree xclip yarn
    ];
  };

  home-manager.users.alice = {
    services.syncthing.enable = true;
    home.stateVersion = "24.05";  # For upgrade security
  };

  # packages.nix
  environment.systemPackages = with pkgs; [
    cargo gcc fd gh git lightdm lm_sensors neovim ripgrep rustup screen wget zellij zsh
  ];

  # services.nix
  programs = {
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    chromium = {
      enable = true;
      extensions = [
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # vimium-c
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "damllfnhhcbmclmjilomenbhkappdjgb" # Parity Signer Companion
        "mopnmbcafieddcagagdcbnhejhlodfdd" # Polkadot-js
        "oboonakemofpalcgghocfoadofidjkkk" # KeepassXC
      ];
    };
  };

  services = {
    openssh.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "eurosign:e,caps:escape";
      };
      windowManager.bspwm.enable = true;
      displayManager.lightdm.enable = true;
    };
    syncthing.enable = false;
    greenclip.enable = true;
  };

  # activation.nix
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

    # Symlink the wifi script
    ln -sf /etc/nixos/dotfiles/wifi/.wifi /home/alice/.wifi

    # Ensure ownership and permissions
    chown -R alice:users /home/alice/.config
    chown alice:users /home/alice/.zshrc
    chown alice:users /home/alice/.wifi

    # Set executable permissions on scripts if necessary
    chmod -R u+x /home/alice/.config/bspwm/scripts
    chmod -R u+x /home/alice/.config/sxhkd/scripts
    chmod +x /home/alice/.wifi
  '';
}

