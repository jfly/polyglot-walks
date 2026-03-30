{
  perSystem =
    { pkgs, ... }:
    let
      basePkg = pkgs.buildNpmPackage {
        pname = "walk-javascript";
        version = "0.1.0";

        src = ./.;

        npmDeps = pkgs.importNpmLock {
          npmRoot = ./.;
        };

        npmConfigHook = pkgs.importNpmLock.npmConfigHook;

        nativeBuildInputs = [ pkgs.typescript ];
      };
    in
    {
      treefmt.programs = {
        biome.enable = true;
      };

      polyglot-walks.walkers.walk-javascript = basePkg.overrideAttrs {
        meta.mainProgram = "walk-javascript";
      };

      polyglot-walks.walkers.walk-javascript-recursive = basePkg.overrideAttrs {
        meta.mainProgram = "walk-javascript-recursive";
      };

      polyglot-walks.walkers.walk-javascript-concurrent-recursive = basePkg.overrideAttrs {
        meta.mainProgram = "walk-javascript-concurrent-recursive";
      };
    };
}
