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
          echo rbs...
          sudo nixos-rebuild switch | tee nixos-build.log
          build_path=$(grep -oE '/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+' nixos-build.log | head -n1)
          rm nixos-build.log
          git add -A
          git commit -m "update: $build_path"
        )
      '';
      nx = "cd /etc/nixos/ && ls";
      ping = "/run/wrappers/bin/ping";
      cargo = "cargo-wrapped";  # use wrapper by default
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
