{ lib, ... }:
let
  fs = lib.fileset;
in
{
  perSystem =
    { pkgs, ... }:
    {
      treefmt.programs = {
        ruff-check.enable = true;
        ruff-format.enable = true;
      };

      polyglot-walks.walkers.walk-python = pkgs.python3Packages.buildPythonApplication {
        name = "python";
        src = fs.toSource {
          root = ./.;
          fileset = fs.unions [
            ./pyproject.toml
            ./src
          ];
        };
        pyproject = true;
        build-system = [ pkgs.python3Packages.uv-build ];
        meta.mainProgram = "walk-python";
      };
    };
}
