{ config, pkgs, ... }:

{
  services = {
    dbus.packages = [ pkgs.xfce.tumbler ];
    udev.packages = [ pkgs.ledger-udev-rules ];
    tailscale.enable = true;
    fwupd.enable = true;
    udisks2.enable = true;
    pcscd.enable = true;
    acpid.enable = true;

    logind.settings.Login.HandlePowerKey = "ignore";

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "127.0.0.1";
      port = 11434;
    };
  };

  programs = {
    appimage = { enable = true; binfmt = true; };
    gnupg.agent = { enable = true; enableSSHSupport = false; };
    mtr.enable = true;
    zsh.enable = true;
  };

  virtualisation.podman = { enable = true; dockerCompat = true; };
}
