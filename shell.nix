# /etc/nixos/shell.nix
{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      vi = "nvim";
      rbt = "sudo nixos-rebuild dry-build";
      rbs = ''
        cd /etc/nixos && \
        echo 'rbs...' && \
        build_output=$(sudo nixos-rebuild switch 2>&1) && \
        build_path=$(echo "$build_output" | grep -oE "/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+" | head -n1) && \
        git add -A && \
        git commit -m "$build_path"
      '';
      nx = "cd /etc/nixos/ && ls";
    };
  };
  
  environment.shells = [ pkgs.zsh pkgs.bash ];
  users.defaultUserShell = pkgs.zsh;
}
