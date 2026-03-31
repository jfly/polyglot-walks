{ lib, ... }:
{
  perSystem =
    {
      self',
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
            benchmark_dir=$2

            benchmark_csv=$(realpath --canonicalize-missing "$benchmark_dir/benchmarks.csv")
            benchmark_svg=$(realpath --canonicalize-missing "$benchmark_dir/benchmarks.svg")

            hyperfine \
              --shell=none \
              --warmup=2 \
              --export-csv="$benchmark_csv" \
              ${hyperfinePositionalArgsStr}

            ${lib.getExe self'.packages.plot} "$benchmark_csv" "$benchmark_svg"

            echo "Success!"
            echo "CSV results: $benchmark_csv"
            echo "Chart: $benchmark_svg"
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
                binary, *args = shlex.split(command)
                first_part, *rest_parts = os.path.basename(binary).split("-")
                assert first_part == "walk"
                return "\n".join(rest_parts)


            parser = argparse.ArgumentParser()
            parser.add_argument("csv_file", type=Path)
            parser.add_argument("output_svg", type=Path)
            args = parser.parse_args()

            df = pd.read_csv(args.csv_file)
            df['base_command'] = df['command'].apply(get_command_basename)
            df.sort_values('mean', inplace=True)

            ax = df.plot(kind="barh", x='base_command', y='mean')
            ax.set_xlabel("Time (seconds)")
            ax.set_ylabel("")

            plt.title("Filesystem walk performance. Smaller is better (faster).")
            plt.tight_layout()
            plt.savefig(args.output_svg, dpi=150)
            print(f"Saved {args.output_svg}")
          '';
    };
}
