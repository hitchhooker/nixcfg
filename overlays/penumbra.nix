self: super: {
  pcli = super.callPackage ({
    rustPlatform,
    fetchFromGitHub,
    pkg-config,
    openssl,
    protobuf,
    ...
  }: rustPlatform.buildRustPackage rec {
    pname = "pcli";
    version = "unstable-2024-01-10";
    
    src = /home/alice/src/penumbra;
    
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
    };
    
    nativeBuildInputs = [ pkg-config protobuf rustPlatform.bindgenHook ];
    buildInputs = [ openssl ];
    
    cargoBuildFlags = [ "--bin" "pcli" ];
    PROTOC = "${protobuf}/bin/protoc";
  }) {};
}
