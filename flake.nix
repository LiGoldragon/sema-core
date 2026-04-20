{
  description = "veri-core — rkyv contract types for veric↔semac (verified program)";

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
    aski-core = {
      url = "github:LiGoldragon/aski-core";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
      inputs.corec.follows = "corec";
    };
  };

  outputs = { self, nixpkgs, fenix, crane, flake-utils, corec, aski-core, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain = fenix.packages.${system}.stable.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        corec-bin = corec.packages.${system}.corec;
        aski-core-source = aski-core.packages.${system}.source;

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            (craneLib.filterCargoSources path type)
            || (builtins.match ".*\\.core$" path != null);
        };

        # Run corec on source/*.core → generated/veri_core.rs
        generated = pkgs.runCommand "veri-core-generated" {
          nativeBuildInputs = [ corec-bin ];
        } ''
          mkdir -p generated
          corec ${./source} generated/veri_core.rs
          mkdir -p $out
          cp generated/veri_core.rs $out/
        '';

        # Full source tree with generated types + aski-core dependency
        veri-core-source = pkgs.runCommand "veri-core-source" {} ''
          cp -r ${src} $out
          chmod -R +w $out
          mkdir -p $out/generated
          cp ${generated}/veri_core.rs $out/generated/
          mkdir -p $out/flake-crates
          cp -r ${aski-core-source} $out/flake-crates/aski-core
        '';

        commonArgs = {
          src = veri-core-source;
          pname = "veri-core";
          version = "0.17.0";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        veri-core-lib = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

      in {
        packages = {
          default = veri-core-source;
          source = veri-core-source;
          lib = veri-core-lib;
          inherit generated;
        };

        checks = {
          lib-build = veri-core-lib;
        };

        devShells.default = craneLib.devShell {
          packages = [ corec-bin pkgs.rust-analyzer ];
        };
      }
    );
}
