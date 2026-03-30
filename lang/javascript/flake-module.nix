{
  perSystem =
    { pkgs, ... }:
    {
      treefmt.programs = {
        biome.enable = true;
      };

      polyglot-walks.walkers.walk-javascript = pkgs.buildNpmPackage {
        pname = "walk-javascript";
        version = "0.1.0";

        src = ./.;

        npmDeps = pkgs.importNpmLock {
          npmRoot = ./.;
        };

        npmConfigHook = pkgs.importNpmLock.npmConfigHook;

        nativeBuildInputs = [ pkgs.typescript ];

        meta.mainProgram = "walk-javascript";
      };
    };
}
