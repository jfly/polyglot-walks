# How to run the benchmarks

You'll need some large directory to run it against. I'm using my `~/src`
directory.

```console
nix run .#benchmark ~/src ./results
```

Then you can plot the results:

```console
nix run .#plot ./results/results.csv output.png
```
