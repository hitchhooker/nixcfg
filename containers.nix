{ config, pkgs, ... }:

{
  containers.arch-dev = {
    autoStart = true;
    privateNetwork = false;
    
    config = { config, pkgs, ... }: {
      system.stateVersion = "24.11";
      
      environment.systemPackages = with pkgs; [
        gcc
        gnumake
        git
        vim
        wget
        curl
        rustup
        nodejs
        python3
      ];
      
      users.users.dev = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "dev";
      };
      
      security.sudo.wheelNeedsPassword = false;
    };
    
    bindMounts = {
      "/mnt/dev" = {
        hostPath = "/home/alice/dev";
        isReadOnly = false;
      };
    };
  };
}
