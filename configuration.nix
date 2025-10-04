{ config, pkgs, ... }:

{
  imports = [
    ./anime-wallpaper.nix
    ./shell.nix
    ./wireguard.nix
    ./hardware.nix
    ./packages.nix
    ./desktop.nix
    ./services.nix
    <home-manager/nixos>
    <agenix/modules/age.nix>
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "slack" "libsciter" ];
    permittedInsecurePackages = [ "libsoup-2.74.3" "qtwebengine-5.15.19" ];
  };

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
  };

  system = {
    copySystemConfiguration = true;
    stateVersion = "24.11";
  };
}
