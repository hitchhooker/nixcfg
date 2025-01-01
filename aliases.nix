# /etc/nixos/aliases.nix
{ config, pkgs, ... }:
{
  environment.shellAliases = {
    vi = "nvim";
    rbt = "sudo nixos-rebuild dry-build";
    rbs = ''
      cd /etc/nixos && \
      echo "Running nixos-rebuild switch..." && \
      build_output=$(sudo nixos-rebuild switch 2>&1) && \
      echo "$build_output" && \
      build_path=$(echo "$build_output" | grep -oE "/nix/store/[a-z0-9]{32}-nixos-system-[^ ]+" | head -n 1) && \
      if [ -n "$build_path" ]; then \
        git add -A && \
          git commit -m "$build_path" && \
          echo "Rebuild complete. Changes activated."; \
      else \
        echo "Error: Failed to extract build path from nixos-rebuild output"; \
        exit 1; \
      fi
        '';
    nx = ''cd /etc/nixos/ && ls'';
  };
}
