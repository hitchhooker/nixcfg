# /etc/nixos/shell.nix
{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      # existing aliases
      vi = "nvim";
      rbt = "sudo nixos-rebuild dry-build";
      rbs = ''
        (
          cd /etc/nixos || exit 1
          echo "Running nixos-rebuild switch..."
          if sudo nixos-rebuild switch; then
            if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
              git add -A
              git commit -m "update: $(readlink /nix/var/nix/profiles/system)"
              echo "Changes committed successfully"
            fi
          else
            echo "Rebuild failed! No changes committed."
            exit 1
          fi
        )
      '';
      rbsu = "sudo nix-channel --update && rbs";
      rbsd = "sudo nixos-rebuild switch --show-trace";
      rbd = "sudo nixos-rebuild dry-run";
      rbb = "sudo nixos-rebuild boot";
      
      # channel management
      ncu = "sudo nix-channel --update";
      ncl = "sudo nix-channel --list";
      nca = "sudo nix-channel --add";
      
      # config editing
      nixcfg = "nvim /etc/nixos/configuration.nix";
      nixhw = "nvim /etc/nixos/hardware/$(hostname).nix";
      
      # garbage collection
      ngc = "sudo nix-collect-garbage -d";
      ngo = "sudo nix-store --optimise";
      
      # search packages
      nps = "nix search nixpkgs";
      npsu = "nix search nixpkgs-unstable";
      
      # shortcuts
      nx = "cd /etc/nixos/ && ls";
      ping = "/run/wrappers/bin/ping";
    };
  };
  environment.shells = [ pkgs.zsh pkgs.bash ];
  users.defaultUserShell = pkgs.zsh;
  environment.interactiveShellInit = ''
    if [[ -z "$SSH_AUTH_SOCK" && -s "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
      export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
    fi
    # Rust development environment
    export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.sqlite.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export OPENSSL_DIR="${pkgs.openssl.dev}"
    export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
    export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
    export SQLITE3_LIB_DIR="${pkgs.sqlite.out}/lib"
    export LD_LIBRARY_PATH="${pkgs.sqlite.out}/lib:${pkgs.openssl.out}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';
}
