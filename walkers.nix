{ lib, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      expectedFileCount = 10 * 10 * 10;
      expectedDirCount = 1 + 10 + 10 * 10;

      testDir = pkgs.runCommand "test-dir" { } ''
        mkdir $out
        for i in {1..10}; do
          mkdir $out/d$i
          for j in {1..10}; do
            mkdir $out/d$i/d$j
            for k in {1..10}; do
              touch $out/d$i/d$j/f$k
            done
          done
        done
      '';
      expectedOutput = pkgs.writeTextFile {
        name = "expected.out";
        text = ''
          ${toString expectedFileCount} file(s)
          ${toString expectedDirCount} directories(s)
        '';
      };
      buildWalkerTest =
        pkg:
        let
          exe = lib.getExe pkg;
          actualOutput = pkgs.runCommand "actual-${pkg.name}.out" { } ''
            ${exe} ${testDir} > $out
          '';
        in
        pkgs.runCommand "test-${pkg.name}"
          {
            nativeBuildInputs = [ pkgs.diffutils ];
          }
          ''
            if diff ${actualOutput} ${expectedOutput} >/dev/null; then
              echo "Success!"
              touch $out
            else
              echo "FAIL: unexpected output. Comparing actual to expected:";
              diff --unified ${actualOutput} ${expectedOutput} || true
              exit 1
            fi
          '';
    in
    {
      options = {
        polyglot-walks.walkers = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.package;
        };
      };

      config = {
        packages = config.polyglot-walks.walkers;

        checks = lib.mapAttrs' (
          walkerName: walker: lib.nameValuePair "test/${walkerName}" (buildWalkerTest walker)
        ) config.polyglot-walks.walkers;
      };
    };
}
