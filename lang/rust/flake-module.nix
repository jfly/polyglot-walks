{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) rustPlatform;
      fs = lib.fileset;
      cargoToml = fromTOML (builtins.readFile ./Cargo.toml);
      basePkg = rustPlatform.buildRustPackage (finalAttrs: {
        pname = cargoToml.package.name;
        version = cargoToml.package.version;

        src = fs.toSource {
          root = ./.;
          fileset = fs.unions [
            ./src
            ./Cargo.toml
            ./Cargo.lock
          ];
        };

        nativeCheckInputs = [
          pkgs.clippy
        ];

        checkPhase = ''
          runHook preCheck
          cargo clippy --all-targets --all-features -- -D warnings
          runHook postCheck
        '';

        cargoLock.lockFile = ./Cargo.lock;
      });
    in
    {
      treefmt.programs.rustfmt.enable = true;

      devShells.rust = pkgs.mkShell {
        inputsFrom = [
          basePkg
        ];
        packages = [
          pkgs.clippy
          pkgs.rust-analyzer
        ];
      };

      polyglot-walks.walkers.walk-rust = basePkg.overrideAttrs {
        meta.mainProgram = "walk-rust";
      };

      polyglot-walks.walkers.walk-rust-rayon = basePkg.overrideAttrs {
        meta.mainProgram = "walk-rust-rayon";
      };

      polyglot-walks.walkers.walk-rust-tokio = basePkg.overrideAttrs {
        meta.mainProgram = "walk-rust-tokio";
      };
    };
}
