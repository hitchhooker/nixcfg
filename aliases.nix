# /etc/nixos/aliases.nix
{ config, pkgs, ... }:
{
  environment.shellAliases = {
    vi = "nvim";
    rbt = "sudo nixos-rebuild dry-build";
    rbs = ''cd /etc/nixos && git add -A && git commit -m "force commit $(date +%s)" && sudo nixos-rebuild switch'';
    nx = ''cd /etc/nixos/ && ls''
  };
}
