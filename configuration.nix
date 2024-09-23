{ config, lib, pkgs, ... }:

let
  aliceSecret = import /etc/secrets/alice-hash.nix;
  wifiSecret = import /etc/secrets/wifi-networks.nix;

  hostSpecificHardwareConfig = ./machines/lenovo.nix;
  useHostConfig = if builtins.pathExists hostSpecificHardwareConfig then hostSpecificHardwareConfig else ./machines/default.nix;
in
{
# imports
  imports = [ ./aliases.nix <home-manager/nixos> useHostConfig ];

# system.nix
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "slack"
  ];

# locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  time.timeZone = "Asia/Bangkok";

# fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Iosevka" "IosevkaTerm" "FiraCode" "Hack" ]; })
      nerdfonts font-awesome iosevka dejavu_fonts
  ];

  system.copySystemConfiguration = true;
  system.stateVersion = "24.05";

# network.nix
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

# home.nix
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
      alacritty bspwm bun chromium dunst electrum element-desktop flameshot gh google-cloud-sdk
        i3lock-fancy-rapid libssh keepassxc nodejs pavucontrol python313Full polybar
        rofi signal-desktop slack sxhkd syncthing telegram-desktop tree xclip yarn
        (python3.withPackages (ps: with ps; [ ansible pip ]))
    ];
  };

  home-manager.users.alice = {
    services.syncthing.enable = true;
    home.stateVersion = "24.05";
  };

# packages.nix
  environment.systemPackages = with pkgs; [
    bash cargo gcc fd git lightdm lm_sensors neovim openssh parted ripgrep rustup screen ssh-agents sshfs wget zellij zsh
  ];
# environment.variables.SHELL = "/run/current-system/sw/bin/bash";
  environment.variables.SHELL = pkgs.zsh;

# services.nix
  programs = {
#    ssh = {
#      startAgent = true;
#      agentTimeout = "1h";
#    };
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

# Ensure ownership and permissions
    chown -R alice:users /home/alice/.config
    chown alice:users /home/alice/.zshrc

# Set executable permissions on scripts if necessary
    chmod -R u+x /home/alice/.config/bspwm/scripts
    chmod -R u+x /home/alice/.config/sxhkd/scripts
    '';
}
