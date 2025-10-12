{ config, pkgs, ... }:

{
  services = {
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
            repo = "bspwm1";
            rev = "063bf2d314d2f34ed190c734be7eeecb5e39da1e";
            sha256 = "sha256-lPfe08LQHHxxqfAJltbYlM94iHJvl5FBkeH4BPoF07A=";
          };
        });
      };
    };

    picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      settings.opacity-rule = [ "96:class_g = 'Alacritty'" ];
    };

    redshift = {
      enable = true;
      temperature = { day = 2900; night = 2700; };
    };
  };

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib glibc zlib openssl curl expat freetype glib libuuid
        libgcc.lib libGL libxkbcommon fontconfig xorg.libX11 xwinwrap
        xorg.libXcursor xorg.libXi xorg.libXrandr xorg.libXrender xorg.libxcb
        xorg.libXext xorg.libXfixes xorg.libXcomposite xorg.libXdamage
        xorg.libXtst xorg.libXScrnSaver xorg.libXau xorg.libXdmcp
        xorg.libXinerama xorg.libXxf86vm wayland bzip2 pcre pcre2 ncurses
        readline sqlite libxml2 libxslt icu harfbuzz pango cairo gdk-pixbuf
        gtk3 dbus at-spi2-core at-spi2-atk alsa-lib pulseaudio lz4 xz
        libgcrypt libgpg-error libssh2 nghttp2 systemd libcap util-linux.lib
        libffi libtasn1 p11-kit
      ];
    };

    chromium = {
      enable = true;
      extensions = [
        "hfjbmagddngcpeloejdejnfgbamkjaeg" "ddkjiahejlhfcafbddmgiahcphecmpfh"
        "damllfnhhcbmclmjilomenbhkappdjgb" "oboonakemofpalcgghocfoadofidjkkk"
        "gobmdjdemnlkgfcgmhmmojgaebfediog" "ginchbkmljhldofnbjabmeophlhdldgp"
        "lkpmkhpnhknhmibgnmmhdhgdilepfghe" "dmkamcknogkgcdfhhbddcghachkejeap"
      ];
    };

    firefox = {
      enable = true;
      package = pkgs.librewolf;
      nativeMessagingHosts.packages = [ pkgs.web-eid-app ];
      policies = {
        SecurityDevices.p11-kit-proxy = "${pkgs.p11-kit}/lib/p11-kit-proxy.so";
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
      };
    };
  };

  systemd.user.services = {
    ssh-agent = {
      description = "ssh authentication agent";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent.socket -D";
      };
      wantedBy = [ "default.target" ];
    };

    tearfree = {
      description = "enable AMD TearFree";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.xorg.xrandr}/bin/xrandr --output eDP --set TearFree on";
        RemainAfterExit = true;
      };
    };
  };

  system.activationScripts = {
    linkDotfiles = ''
      mkdir -p /home/alice/.config
      ln -sf /etc/nixos/dotfiles/zsh/.zshrc /home/alice/.zshrc
      ln -sfn /etc/nixos/dotfiles/nvim /home/alice/.config/nvim
      ln -sfn /etc/nixos/dotfiles/alacritty /home/alice/.config/alacritty
      ln -sfn /etc/nixos/dotfiles/dunst /home/alice/.config/dunst
      ln -sfn /etc/nixos/dotfiles/rofi /home/alice/.config/rofi
      ln -sfn /etc/nixos/dotfiles/polybar /home/alice/.config/polybar
      ln -sfn /etc/nixos/dotfiles/bspwm /home/alice/.config/bspwm
      ln -sfn /etc/nixos/dotfiles/sxhkd /home/alice/.config/sxhkd
      ln -sf /etc/nixos/dotfiles/greenclip.toml /home/alice/.config/greenclip.toml
      chown -R alice:users /home/alice/.config /home/alice/.zshrc
      chmod -R u+x /home/alice/.config/{bspwm,sxhkd}/scripts
    '';

    terminalEmulator = ''
      mkdir -p /usr/bin
      ln -sf ${pkgs.alacritty}/bin/alacritty /usr/bin/x-terminal-emulator
    '';
  };

  home-manager.users.alice = {
    services.syncthing.enable = true;
    home = { stateVersion = "24.11"; enableNixpkgsReleaseCheck = false; };
  };
}
