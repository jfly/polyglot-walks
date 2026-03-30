{ lib, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages.benchmark =
        let
          # Each entry is actually a bash expression which generates a
          # command to test.
          commands = lib.mapAttrsToList (
            _walkerName: walkerPkg: "${lib.getExe walkerPkg} $benchdir"
          ) config.polyglot-walks.walkers;

          # Wrap the bash expression in double quotes so it can be
          # passed as a positional argument to hyperfine.
          # This doesn't work if the expression has double quotes in it, so
          # make sure that's not the case.
          hyperfinePositionalArgsStr = lib.concatStringsSep " " (
            map (
              bashExpr:
              assert !(lib.strings.hasInfix ''"'' bashExpr);
              ''"${bashExpr}"''
            ) commands
          );
        in
        pkgs.writeShellApplication {
          name = "benchmark";
          runtimeInputs = [ pkgs.hyperfine ];
          text = ''
            if [ $# -ne 2 ]; then
              echo "Usage $0 [benchdir] [results]";
              exit 1
            fi

            benchdir=$1
            results=$2

            mkdir "$results"
            hyperfine \
              --shell=none \
              --warmup=2 \
              --export-markdown="$results/results.md" \
              --export-csv="$results/results.csv" \
              ${hyperfinePositionalArgsStr}
          '';
        };

      packages.plot =
        pkgs.writers.writePython3Bin "plot"
          {
            libraries = ps: [
              ps.pandas
              ps.matplotlib
            ];
          }
          /* python */ ''
            from pathlib import Path
            import argparse
            import matplotlib.pyplot as plt
            import os.path
            import pandas as pd
            import shlex


            def get_command_basename(command: str) -> str:
                return os.path.basename(shlex.split(command)[0])


            parser = argparse.ArgumentParser()
            parser.add_argument("csv_file", type=Path)
            parser.add_argument("output_png", type=Path)
            args = parser.parse_args()

            df = pd.read_csv(args.csv_file)
            df['base_command'] = df['command'].apply(get_command_basename)

            ax = df.plot(kind="bar", x='base_command', y='mean')
            ax.set_ylabel("Time (seconds)")
            ax.set_xlabel("")
            ax.tick_params(axis='x', rotation=0)

            plt.tight_layout()
            plt.savefig(args.output_png, dpi=150)
            print(f"Saved {args.output_png}")
          '';
    };
}
