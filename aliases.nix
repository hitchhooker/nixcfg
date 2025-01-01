# /etc/nixos/aliases.nix
{ config, pkgs, ... }:
{
  environment.shellAliases = {
    vi = "nvim";
    rbt = "sudo nixos-rebuild dry-build";
    rbs = ''
      cd /etc/nixos && \
      echo 'rbs...' && \
      build_output=$(sudo nixos-rebuild switch 2>&1) && \
      build_path=$(echo "$build_output" | grep -oE "/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+" | head -n1) && \
      git add -A && \
      git commit -m "$build_path" && \
      source /etc/zshrc && \
      source /etc/bashrc
    '';
    nx = ''cd /etc/nixos/ && ls'';
  };
}
