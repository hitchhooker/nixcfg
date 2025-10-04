{ config, lib, pkgs, ... }:

{
  imports = [ 
    (if builtins.pathExists ./hardware/lenovo.nix 
     then ./hardware/lenovo.nix 
     else ./hardware/default.nix)
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.conf.all.rp_filter" = 0;
  };

  networking = {
    nameservers = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ];
    resolvconf = { 
      enable = true; 
      extraOptions = [ "edns0" "trust-ad" "rotate" "timeout:2" "attempts:3" ]; 
    };
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

  i18n.defaultLocale = "en_US.UTF-8";
  console = { font = "Lat2-Terminus16"; useXkbConfig = true; };
  time.timeZone = "Asia/Bangkok";
  location = { latitude = 13.7563; longitude = 99.5018; };
}
