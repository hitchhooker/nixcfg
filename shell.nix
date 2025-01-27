# /etc/nixos/shell.nix
{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      vi = "nvim";
      rbt = "sudo nixos-rebuild dry-build";
      rbs = ''
        cd /etc/nixos
        echo 'rbs...'
        sudo nixos-rebuild switch | tee nixos-build.log
        build_path=$(grep -oE "/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+" nixos-build.log | head -n1)
        rm nixos-build.log
        git add -A 
        git commit -m "update: $build_path"
        '';
      nx = "cd /etc/nixos/ && ls";
    };
  };

  environment.shells = [ pkgs.zsh pkgs.bash ];
  users.defaultUserShell = pkgs.zsh;
}
