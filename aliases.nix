{ config, pkgs, ... }:

{
	programs.zsh = {
		enable = true;
		shellAliases = {
			vi = "nvim";
			rbs = "sudo nixos-rebuild switch";
			rbt = "nixos-rebuild dry-build";
		};
	};
}
