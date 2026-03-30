use std::{
    fs::read_dir,
    path::{Path, PathBuf},
    sync::atomic::{AtomicU32, Ordering},
};

use clap::Parser;
use rayon::iter::{IntoParallelIterator, ParallelIterator};

struct WalkStats {
    file_count: u32,
    dir_count: u32,
}

fn walk(root: &Path) -> anyhow::Result<WalkStats> {
    fn inner(root: &Path, file_count: &AtomicU32, dir_count: &AtomicU32) -> anyhow::Result<()> {
        let entries: Vec<_> = read_dir(root)?.collect();

        let errors: Vec<_> = entries
            .into_par_iter()
            .map(
                |entry: Result<std::fs::DirEntry, _>| -> anyhow::Result<()> {
                    let entry = entry?;
                    let file_type = entry.file_type()?;
                    if file_type.is_dir() {
                        dir_count.fetch_add(1, Ordering::Relaxed);
                        inner(&entry.path(), file_count, dir_count)?;
                    } else {
                        file_count.fetch_add(1, Ordering::Relaxed);
                    }

                    Ok(())
                },
            )
            .filter(Result::is_err)
            .collect();

        if !errors.is_empty() {
            anyhow::bail!("couldn't process all children");
        }

        Ok(())
    }

    let mut file_count = AtomicU32::new(0);
    let mut dir_count = AtomicU32::new(1);
    inner(root, &file_count, &dir_count)?;

    Ok(WalkStats {
        file_count: *file_count.get_mut(),
        dir_count: *dir_count.get_mut(),
    })
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Path to analyze.
    root: PathBuf,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let stats = walk(&args.root)?;
    println!("{} file(s)", stats.file_count);
    println!("{} directories(s)", stats.dir_count);
    Ok(())
}
