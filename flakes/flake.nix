# /etc/nixos/flake.nix
{
  description = "My NixOS configuration with Polkadot";

  inputs = {
    # Main Nixpkgs (you can choose a specific branch like nixos-24.05)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05"; # Or "github:NixOS/nixpkgs/nixos-24.05"

    # Unstable Nixpkgs
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensures Home Manager uses the same nixpkgs
    };

    # Agenix
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Polkadot Overlay
    polkadot-nix = {
      url = "github:andresilva/polkadot.nix";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensures it uses the same nixpkgs version
    };
  };

  outputs = { self, nixpkgs, nixos-unstable, home-manager, agenix, polkadot-nix, ... }@inputs:
  let
    system = "x86_64-linux"; # Specify your system architecture

    # Special arguments to pass to your NixOS modules (like configuration.nix)
    specialArgs = {
      # This makes 'unstable' packages available in your configuration.nix
      unstable = import nixos-unstable {
        inherit system;
        # You can set configuration for this unstable pkgs set here
        config.allowUnfree = true;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "slack" # If slack is from unstable and you need it there
          # Add other unstable unfree packages if necessary
        ];
      };
      # You can pass other inputs if needed by your modules:
      # inherit inputs;
    };
  in
  {
    nixosConfigurations = {
      # Replace "your-hostname" with the actual hostname of your machine.
      # This is the name you'll use with `nixos-rebuild switch --flake .#your-hostname`
      "nixos" = nixpkgs.lib.nixosSystem { # Example: "nixos" or "lenovo"
        inherit system specialArgs;
        modules = [
          # Your main NixOS configuration file
          ./configuration.nix

          # Apply the Polkadot overlay globally to your system's 'pkgs'
          { nixpkgs.overlays = [ polkadot-nix.overlays.default ]; }

          # Home Manager NixOS module
          home-manager.nixosModules.home-manager

          # Agenix NixOS module
          agenix.nixosModules.age
        ];
      };
    };

    # Optional: You can also expose the Polkadot package for direct use, e.g.:
    # nix build .#polkadot-pkg
    # nix shell .#polkadot-pkg
    packages.${system}.polkadot-pkg = (import nixpkgs {
      inherit system;
      overlays = [ polkadot-nix.overlays.default ];
      config = { # Apply relevant config if building package standalone
        allowUnfree = true; # As an example
        # allowUnfreePredicate = ...;
      };
    }).polkadot; # Assuming the overlay provides 'pkgs.polkadot'
  };
}
