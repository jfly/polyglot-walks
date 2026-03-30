use std::{
    fs::read_dir,
    path::{Path, PathBuf},
};

use clap::Parser;

struct WalkStats {
    file_count: u32,
    dir_count: u32,
}

fn walk(root: &Path) -> anyhow::Result<WalkStats> {
    let mut file_count = 0;
    let mut dir_count = 1;

    for entry in read_dir(root)? {
        let entry = entry?;
        let file_type = entry.file_type()?;
        if file_type.is_dir() {
            let addl_stats = walk(&entry.path())?;
            file_count += addl_stats.file_count;
            dir_count += addl_stats.dir_count;
        } else {
            file_count += 1;
        }
    }

    Ok(WalkStats {
        file_count,
        dir_count,
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
