import argparse
from pathlib import Path


def walk() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    args = parser.parse_args()

    root: Path = args.root
    assert root.exists()
    assert not root.is_symlink()
    assert root.is_dir()

    file_count = 0
    dir_count = 1
    for root, dirs, files in root.walk():
        file_count += len(files)
        dir_count += len(dirs)

    print(f"{file_count} file(s)")
    print(f"{dir_count} directories(s)")
