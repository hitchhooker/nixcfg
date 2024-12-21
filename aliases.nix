# /etc/nixos/aliases.nix
{ config, pkgs, ... }:
{
  environment.shellAliases = {
    vi = "nvim";
    rbt = "sudo nixos-rebuild dry-build";
    rbs = ''
      bash -c '
      cd /etc/nixos
      git add -A
      nixos_version=$(nixos-version)
      build_output=$(sudo nixos-rebuild switch 2>&1)
      build_path=$(echo "$build_output" | grep -oE "/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+")
      git commit -m "nixos ${nixos_version}, build ${build_path}"
      '
      '';
    nx = ''cd /etc/nixos/ && ls'';
  };
}
