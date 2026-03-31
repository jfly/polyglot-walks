{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      fs = lib.fileset;
      basePkg = pkgs.buildGoModule {
        name = "go";

        src = fs.toSource {
          root = ./.;
          fileset = fs.unions [
            ./go.mod
            ./cmd
          ];
        };

        vendorHash = null;
      };
    in
    {
      treefmt.programs.gofmt.enable = true;

      devShells.go = pkgs.mkShell {
        inputsFrom = [
          basePkg
        ];
      };

      polyglot-walks.walkers.walk-go = basePkg.overrideAttrs {
        meta.mainProgram = "walk-go";
      };

      polyglot-walks.walkers.walk-go-concurrent = basePkg.overrideAttrs {
        meta.mainProgram = "walk-go-concurrent";
      };
    };
}
