{ config, pkgs, ... }:

{
  imports = [
    ./anime-wallpaper.nix
    ./shell.nix
    ./wireguard.nix
    ./containers.nix
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

    settings = {
      # Pull from cachix
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://rotkonetworks.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "rotkonetworks.cachix.org-1:gCMOZq+qhrs6iZsgOgCxAPog8qe9izFB3Vcw8kAVvBQ="
      ];
    };
  };

  system = {
    copySystemConfiguration = true;
    stateVersion = "24.11";
  };
}
