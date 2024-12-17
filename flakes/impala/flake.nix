{
  description = "Flake for Impala from pythops/impala";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }: 
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in {
    # Define the impala package
    packages.x86_64-linux.impala = pkgs.python3Packages.buildPythonPackage {
      pname = "impala";
      version = "1.0.0"; # Replace with actual version

      # Fetch the source code from GitHub
      src = pkgs.fetchFromGitHub {
        owner = "pythops";
        repo = "impala";
        rev = "main"; # Replace with specific tag/commit hash if needed
        sha256 = "0000000000000000000000000000000000000000000000000000"; # Replace with actual hash
      };

      # Add Python dependencies
      propagatedBuildInputs = with pkgs.python3Packages; [
        requests # Add other Python dependencies as needed
      ];

      # Metadata about the package
      meta = with pkgs.lib; {
        description = "Impala - Python CLI tool from pythops";
        homepage = "https://github.com/pythops/impala";
        license = licenses.mit;
      };
    };
  };
}
