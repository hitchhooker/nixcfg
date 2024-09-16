{ config, pkgs, ... }:

{
	programs.zsh = {
		enable = true;
		shellAliases = {
			vi = "nvim";
			rbs = "sudo nixos-rebuild switch";
			rbt = "sudo nixos-rebuild dry-build";
		};
	};
}
