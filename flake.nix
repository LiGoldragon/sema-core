{
  description = "sema-core — rkyv contract types for veric↔semac (verified program)";

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
    aski = {
      url = "github:Criome/aski";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
      inputs.corec.follows = "corec";
    };
  };

  outputs = { self, nixpkgs, fenix, crane, flake-utils, corec, aski, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain = fenix.packages.${system}.stable.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        corec-bin = corec.packages.${system}.corec;
        aski-source = aski.packages.${system}.source;

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            (craneLib.filterCargoSources path type)
            || (builtins.match ".*\\.aski$" path != null);
        };

        # Run corec on source/*.aski → generated/sema_core.rs
        generated = pkgs.runCommand "sema-core-generated" {
          nativeBuildInputs = [ corec-bin ];
        } ''
          mkdir -p generated
          corec ${./source} generated/sema_core.rs
          mkdir -p $out
          cp generated/sema_core.rs $out/
        '';

        # Full source tree with generated types + aski dependency
        sema-core-source = pkgs.runCommand "sema-core-source" {} ''
          cp -r ${src} $out
          chmod -R +w $out
          mkdir -p $out/generated
          cp ${generated}/sema_core.rs $out/generated/
          mkdir -p $out/flake-crates
          cp -r ${aski-source} $out/flake-crates/aski
        '';

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
