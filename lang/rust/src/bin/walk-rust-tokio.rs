use std::path::{Path, PathBuf};

use clap::Parser;

use tokio::{fs::read_dir, runtime::Runtime};

use std::future::Future;
use std::pin::Pin;

struct WalkStats {
    file_count: u32,
    dir_count: u32,
}

fn walk(root: &Path) -> Pin<Box<dyn Future<Output = anyhow::Result<WalkStats>> + Send>> {
    let root = root.to_path_buf();
    Box::pin(async move {
        let mut file_count = 0;
        let mut dir_count = 1;
        let mut handles = Vec::new();

        let mut entries = read_dir(&root).await?;
        while let Some(entry) = entries.next_entry().await? {
            let file_type = entry.file_type().await?;
            if file_type.is_dir() {
                handles.push(tokio::spawn(walk(&entry.path())));
            } else {
                file_count += 1;
            }
        }

        for handle in handles {
            let addl_stats = handle.await??;
            file_count += addl_stats.file_count;
            dir_count += addl_stats.dir_count;
        }

        Ok(WalkStats {
            file_count,
            dir_count,
        })
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

    let stats = Runtime::new()?.block_on(walk(&args.root))?;
    println!("{} file(s)", stats.file_count);
    println!("{} directories(s)", stats.dir_count);
    Ok(())
}
