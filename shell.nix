# /etc/nixos/shell.nix
{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # these are system-wide zsh aliases.
    # for user-specific aliases, consider home-manager configuration.
    shellAliases = {
      # existing aliases
      vi = "nvim";
      rbt = "sudo nixos-rebuild dry-build";
      rbs = ''
        cd /etc/nixos
        echo 'rbs...'
        sudo nixos-rebuild switch | tee nixos-build.log
        build_path=$(grep -oe "/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+" nixos-build.log | head -n1)
        rm nixos-build.log
        git add -A
        git commit -m "update: $build_path"
      '';
      nx = "cd /etc/nixos/ && ls";
      ping = "/run/wrappers/bin/ping"; # uses the setuid wrapper for ping
    };
  };

  environment.shells = [ pkgs.zsh pkgs.bash ]; # available shells
  users.defaultUserShell = pkgs.zsh; # default shell for new users

  # global interactive shell init
  environment.interactiveShellInit = ''
    # ensures ssh_auth_sock is set if the systemd user service is running and created the socket,
    # and if the variable wasn't already set by the session environment.
    if [[ -z "$ssh_auth_sock" && -s "$xdg_runtime_dir/ssh-agent.socket" ]]; then
      export ssh_auth_sock="$xdg_runtime_dir/ssh-agent.socket"
    fi
  '';
}
