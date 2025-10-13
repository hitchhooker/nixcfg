{ config, lib, pkgs, ... }:

let
  stable = import <nixos> { inherit (config.nixpkgs) config; };
  unstable = import <nixos-unstable> { inherit (config.nixpkgs) config; };

  pcDeps = with pkgs; [
    openssl.dev sqlite.dev glib.dev
    gst_all_1.gstreamer.dev
    gst_all_1.gst-plugins-base.dev
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
  ];

  pcPath = lib.makeSearchPath "lib/pkgconfig" pcDeps;

  pcli = pkgs.writeShellScriptBin "pcli" ''
    exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
      --library-path ${pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib pkgs.openssl.out pkgs.zlib
        pkgs.glibc pkgs.gcc.cc.lib
      ]} \
      /home/alice/src/penumbra/target/release/pcli "$@"
  '';

  run-binary = pkgs.writeShellScriptBin "run-binary" ''
    binary="$1"; shift
    exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
      --library-path ${pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib pkgs.openssl.out pkgs.zlib pkgs.glibc
        pkgs.gcc.cc.lib pkgs.libgcc.lib pkgs.xorg.libX11 pkgs.xwinwrap
        pkgs.xorg.libXcursor pkgs.xorg.libXrandr pkgs.xorg.libXi
      ]} \
      "$binary" "$@"
  '';

  ferroxide = pkgs.buildGoModule rec {
    pname = "ferroxide";
    version = "unstable-2025-01-14";

    src = pkgs.fetchFromGitHub {
      owner = "acheong08";
      repo = "ferroxide";
      rev = "fbf5dc23365646c63db358bc9c5713f435592c33";
      sha256 = "sha256-wSao/k+j9cQenn4oVPTcmluw6Kvl7J4SeK6JJTRrInc=";
    };

    vendorHash = "sha256-Ar7bCsye5qi1YIN+YUZ9fZnUOmIJ+s6hrQclKQnlvaA=";

    subPackages = [ "cmd/ferroxide" ];

    meta = with lib; {
      description = "Open-source ProtonMail bridge with CardDAV, CalDAV, IMAP, and SMTP support";
      homepage = "https://github.com/acheong08/ferroxide";
      license = licenses.gpl3;
    };
  };

in {
  environment = {
    variables = {
      GTK_THEME = "Adwaita:dark";
      QT_QPA_PLATFORMTHEME = "gtk2";
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";
      PKG_CONFIG_PATH = pcPath;
      OPENSSL_DIR = "${pkgs.openssl.dev}";
      OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
      OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    };

    systemPackages = with unstable; [
      bash fd gcc git iputils neovim openssh ripgrep wget zellij zsh fzf
      rustup nixd sqlite pgcli distrobox
      
      # system tools
      inetutils fscrypt-experimental lm_sensors nvme-cli dmidecode ryzenadj
      stress-ng s-tui btop bottom radeontop powertop intel-gpu-tools sysbench
      fwupd geekbench phoronix-test-suite inxi hwinfo cpu-x memtest86-efi
      hdparm smartmontools iotop sysstat ncdu
      
      # gui/desktop
      gtk-engine-murrine libsForQt5.qt5ct xorg.libX11 xwinwrap
      
      # file management
      appimage-run gvfs shared-mime-info xfce.tumbler ffmpegthumbnailer
      libopenraw poppler
      
      # build deps
      binutils glibc pkg-config openssl libiconv cmake gnumake glib.dev
      protobuf llvmPackages.clang llvmPackages.libclang.lib
      
      # stable packages
      stable.lightdm stable.parted stable.screen stable.ssh-agents stable.sshfs
      stable.vim stable.xdotool stable.podman stable.podman-compose stable.pcmanfm
      stable.unzip
    ] ++ [ pkgs.usbutils pkgs.esptool pkgs.picocom pcli run-binary ferroxide ];

    etc = {
      "pkcs11/modules/opensc-pkcs11".text = "module: ${pkgs.opensc}/lib/opensc-pkcs11.so";
      "chromium/native-messaging-hosts/eu.webeid.json".source = "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
      "opt/chrome/native-messaging-hosts/eu.webeid.json".source = "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
    };
  };

  users = {
    mutableUsers = true;
    users.alice = {
      isNormalUser = true;
      home = "/home/alice";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "podman" "dialout" ];
      packages = with unstable; [
        # terminal
        alacritty bottom tree zsh
        # wm
        dunst rofi sxhkd picom
        (polybar.override { pulseSupport = true; })
        # dev
        bun pnpm gh julia rust-analyzer rustfmt yarn polkadot nodejs
        # comm
        beeper discord iamb signal-desktop slack telegram-desktop thunderbird whatsie
        # media
        flameshot mpv ncspot peek obs-studio
        # tools
        television age ssh-to-age wireguard-tools tailscale zerotierone
        ollama-rocm dmidecode jq syncthing transmission_4-qt turbovnc websocat
        # nix
        nix-index nix-direnv nix-prefetch-git act deploy-rs
        # estonian id
        qdigidoc web-eid-app p11-kit opensc
        # stable
        stable.chromium stable.element-desktop stable.cinny-desktop
        stable.google-cloud-sdk stable.i3lock-fancy-rapid stable.jmtpfs
        stable.keepassxc stable.libssh stable.nodejs stable.pavucontrol
        stable.tigervnc stable.xclip stable.alsa-utils stable.toybox stable.pgcli
      ];
    };
  };

  security.wrappers.ping = {
    source = "${pkgs.iputils}/bin/ping";
    owner = "root";
    group = "root";
    setuid = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.iosevka jetbrains-mono nerd-fonts.fira-code iosevka
    font-awesome font-awesome_6
  ];
}
