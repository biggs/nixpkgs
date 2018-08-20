{ stdenv, cacert, git, rust, cargo-vendor }:
{ name ? "cargo-deps", src, srcs, patches, sourceRoot, sha256, cargoUpdateHook ? "", writeVendorConfig ? false }:
stdenv.mkDerivation {
  name = "${name}-vendor";
  nativeBuildInputs = [ cacert cargo-vendor git rust.cargo ];
  inherit src srcs patches sourceRoot;

  phases = "unpackPhase patchPhase installPhase";

  installPhase = ''
    if [[ ! -f Cargo.lock ]]; then
        echo
        echo "ERROR: The Cargo.lock file doesn't exist"
        echo
        echo "Cargo.lock is needed to make sure that cargoSha256 doesn't change"
        echo "when the registry is updated."
        echo

        exit 1
    fi

    export CARGO_HOME=$(mktemp -d cargo-home.XXX)

    ${cargoUpdateHook}

    mkdir -p $out
    cargo vendor $out > config
  '' + stdenv.lib.optionalString writeVendorConfig ''
    mkdir $out/.cargo
    sed "s|directory = \".*\"|directory = \"./vendor\"|g" config > $out/.cargo/config
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = sha256;

  impureEnvVars = stdenv.lib.fetchers.proxyImpureEnvVars;
  preferLocalBuild = true;
}
