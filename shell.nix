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
        git add -a
        git commit -m "update: $build_path"
      '';
      nx = "cd /etc/nixos/ && ls";
      ping = "/run/wrappers/bin/ping"; # uses the setuid wrapper for ping

      # git aliases
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gap = "git add --patch"; # add with patch mode (interactive)
      gb = "git branch";
      gba = "git branch -a"; # all branches (local and remote tracking)
      gcb = "git checkout -b"; # create and checkout new branch
      gco = "git checkout";
      gcm = "git checkout main"; # checkout main (or master)
      gc = "git commit -v"; # commit verbose
      "gc!" = "git commit -v --amend"; # amend previous commit
      gcn = "git commit -v --no-edit --amend"; # amend previous commit without editing message
      gca = "git commit -v -a"; # add all tracked changes and commit
      "gca!" = "git commit -v -a --amend"; # add all tracked changes and amend
      gcam = "git commit -am"; # add all tracked changes and commit with message (prompts for message)
      gm = "git commit -m"; # <<< --- new alias for commit with message
      gcs = "git commit -s"; # signed commit
      gcss = "git commit -S"; # gpg signed commit
      gd = "git diff";
      gds = "git diff --staged"; # diff staged changes
      gdv = "git difftool -y"; # use difftool
      gf = "git fetch";
      gfa = "git fetch --all --prune --tags"; # fetch all, prune deleted, get tags
      gl = "git pull";
      glr = "git pull --rebase";
      gp = "git push";
      gpd = "git push --dry-run";
      gpf = "git push --force-with-lease"; # force push with lease (safer)
      gpl = "git pull"; # alias for pull
      gpu = "git push -u origin head"; # push current branch and set upstream
      gs = "git status -sb"; # status short branch
      gss = "git status -s"; # status short
      gst = "git status"; # standard status
      gsh = "git show";
      glog = "git log --oneline --decorate --graph"; # pretty log
      gloga = "git log --oneline --decorate --graph --all"; # pretty log all branches
      grh = "git reset --hard";
      grhh = "git reset --hard head"; # reset hard to head
      grm = "git rm";
      grmc = "git rm --cached"; # remove from index
      gstash = "git stash";
      gstasha = "git stash apply";
      gstashp = "git stash pop";
      gstashd = "git stash drop";
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
