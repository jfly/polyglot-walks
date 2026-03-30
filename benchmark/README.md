# How to run the benchmarks

You'll need some large directory to run it against. I'm using my `~/src`
directory (~millions of files, ~hundreds of thousands of directories).

```console
nix run .#benchmark ~/src benchmark/benchmarks.csv
```

Then you can plot the results:

```console
nix run .#plot benchmark/benchmarks.csv benchmark/benchmarks.png
```
