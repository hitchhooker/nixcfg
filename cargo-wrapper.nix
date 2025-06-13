{ pkgs, unstable }:
pkgs.writeShellScriptBin "cargo-wrapped" ''
  export PATH="${unstable.rustc}/bin:${unstable.cargo}/bin:$PATH"
  export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.sqlite.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
  export OPENSSL_DIR="${pkgs.openssl.dev}"
  export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
  export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
  export SQLITE3_LIB_DIR="${pkgs.sqlite.out}/lib"
  export LD_LIBRARY_PATH="${pkgs.sqlite.out}/lib:${pkgs.openssl.out}/lib:$LD_LIBRARY_PATH"
  
  # Remove the unstable flags
  unset RUSTFLAGS
  unset CARGO_ENCODED_RUSTFLAGS
  
  exec ${unstable.cargo}/bin/cargo "$@"
''
