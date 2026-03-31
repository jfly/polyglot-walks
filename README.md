# `polyglot-walks`

Experiments with walking the filesystem in many languages.

Challenge: given a directory, recurse through the filesystem (ignoring
symlinks) and count the number of directories and files discovered.

## Results

Benchmarking is hard, I just slapped this together, and I don't really know
what I'm doing. Still, I believe some of these differences are material.

Here's what I got on my laptop when run against a large directory. The absolute
numbers don't matter, just the relative ones.

![Some benchmark data](./benchmark/benchmarks.svg)

Check out the [raw data](./benchmark/benchmarks.csv), or feel free to [run the
benchmarks yourself](./benchmark/README.md).

### Thoughts

I'm only curious about Linux here.

I wanted to figure out if real OS threads or lightweight/green threads is the
better way to tackle this problem. Since the underlying syscalls (`openat(2)`
and `readdir(2)`) are blocking, I wouldn't expect green threads to have an
advantage, and perhaps to have some overhead.

Some research led me to ripgrep, which seems to take performance pretty
seriously. It is written in Rust and uses real OS threads that do
[work stealing](https://en.wikipedia.org/wiki/Work_stealing). See the [source code
here](https://github.com/BurntSushi/ripgrep/blob/15.1.0/crates/ignore/src/walk.rs#L1528-L1530).
Interestingly, it has implemented the work stealing by hand using the low level
`crossbeam` crate, whereas I wrote it using the higher level `rayon` crate
(which uses `crossbeam` under the hood). If you look at their code, you'll see
it's a lot more finicky than the code in here. I'm not sure if this is strictly
necessary, it may be because they're being [careful to avoid
BFS](https://github.com/BurntSushi/ripgrep/blob/15.1.0/crates/ignore/src/walk.rs#L1532-L1535)?
I don't totally understand what they're worried about there.

I don't feel like my results give me a clear answer about the fastest way to do
this. The fastest implementation (Rust with `rayon`) is using real OS threads, and the
second fastest implementation (go concurrent) uses go coroutines (aka: green
threads).

I don't understand why my Rust `tokio` implementation is so slow. I'd expect it to
to be comparable to the go implementation. I suspect I did something dumb
there.
