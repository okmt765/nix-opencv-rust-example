{
  description = "Nix opencv-rust example.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import inputs.rust-overlay) ];
        pkgs = import (inputs.nixpkgs) { inherit system overlays; };

        nativeBuildInputs = with pkgs; [
          clang
          pkg-config
          rustPlatform.bindgenHook
          makeWrapper
        ];

        buildInputs = with pkgs; [
          (opencv4.override { enableGtk3 = true; })
        ];

        rustPlatform = pkgs.makeRustPlatform {
          cargo = pkgs.rust-bin.stable.latest.minimal;
          rustc = pkgs.rust-bin.stable.latest.minimal;
        };

        GST_PLUGIN_SYSTEM_PATH_1_0 =
          with pkgs.gst_all_1;
          "${gstreamer.out}/lib/gstreamer-1.0:${gst-plugins-base}/lib/gstreamer-1.0:${gst-plugins-good}/lib/gstreamer-1.0";
      in
      {
        packages.default = rustPlatform.buildRustPackage rec {
          inherit buildInputs nativeBuildInputs;

          name = "nix-opencv-rust-example";
          src = ./.;
          version = "0.0.1";
          meta.mainProgram = name;

          cargoLock = {
            lockFile = ./Cargo.lock;
            allowBuiltinFetchGit = true;
          };

          postFixup = ''
            wrapProgram $out/bin/${name} \
              --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${GST_PLUGIN_SYSTEM_PATH_1_0}
          '';
        };

        devShells.default = pkgs.mkShell {
          inherit nativeBuildInputs;
          inherit GST_PLUGIN_SYSTEM_PATH_1_0;

          buildInputs =
            buildInputs
            ++ (with pkgs.rust-bin; [
              (stable.latest.minimal.override {
                extensions = [
                  "clippy"
                  "rust-src"
                ];
              })
              nightly.latest.rustfmt
              nightly.latest.rust-analyzer
            ]);

          RUST_BACKTRACE = 1;
        };
      }
    );
}
