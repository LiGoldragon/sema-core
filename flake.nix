{
  description = "sema-core — rkyv contract types for askic↔semac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
    corec = {
      url = "github:LiGoldragon/corec";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, fenix, crane, flake-utils, corec, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain = fenix.packages.${system}.stable.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        corec-bin = corec.packages.${system}.corec;

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            (craneLib.filterCargoSources path type)
            || (builtins.match ".*\\.aski$" path != null);
        };

        # Run corec on core/*.aski → generated/sema_core.rs
        generated = pkgs.runCommand "sema-core-generated" {
          nativeBuildInputs = [ corec-bin ];
        } ''
          mkdir -p generated
          corec ${./core} generated/sema_core.rs
          mkdir -p $out
          cp generated/sema_core.rs $out/
        '';

        # Full source tree with generated types in place.
        sema-core-source = pkgs.runCommand "sema-core-source" {} ''
          cp -r ${src} $out
          chmod -R +w $out
          mkdir -p $out/generated
          cp ${generated}/sema_core.rs $out/generated/
        '';

        # Build the lib crate (verifies the generated types compile)
        commonArgs = {
          src = sema-core-source;
          pname = "sema-core";
          version = "0.17.0";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        sema-core-lib = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

      in {
        packages = {
          default = sema-core-source;
          source = sema-core-source;
          lib = sema-core-lib;
          inherit generated;
        };

        checks = {
          lib-build = sema-core-lib;
        };

        devShells.default = craneLib.devShell {
          packages = [ corec-bin pkgs.rust-analyzer ];
        };
      }
    );
}
