{
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };
          toolchain = pkgs.rust-bin.stable.latest.default.override {
            targets = [ "wasm32-unknown-unknown" ];
          };
          platform = pkgs.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          };
        in
        {
          packages.default = platform.buildRustPackage {
            pname = "lldap";
            version = self.lastModifiedDate;
            src = self;
            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes = {
                "lber-0.4.1" = "sha256-2rGTpg8puIAXggX9rEbXPdirfetNOHWfFc80xqzPMT4=";
                "opaque-ke-0.6.1" = "sha256-99gaDv7eIcYChmvOKQ4yXuaGVzo2Q6BcgSQOzsLF+fM=";
                "yew_form-0.1.8" = "sha256-1n9C7NiFfTjbmc9B5bDEnz7ZpYJo9ZT8/dioRXJ65hc=";
              };
            };
            nativeBuildInputs = with pkgs; [
              wasm-pack
              wasm-bindgen-cli
              binaryen
            ];
            postPatch = ''
              substituteInPlace server/src/infra/tcp_server.rs \
                --replace "app/index.html"     "$out/share/lldap/index.html" \
                --replace "./app/pkg"          "$out/share/lldap/pkg" \
                --replace "./app/static"       "$out/share/lldap/static"
            '';
            preBuild = ''
              wasm-pack build app --target web --release
              gzip -9 -f app/pkg/lldap_app_bg.wasm
            '';
            postInstall = ''
              install -Dm444 app/index.html       $out/share/lldap/index.html
              cp -a          app/static           $out/share/lldap/static
              cp -a          app/pkg              $out/share/lldap/pkg
            '';
          };
        });
}
