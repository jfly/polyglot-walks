package main

import (
	"fmt"
	"log"
	"os"
	"path"
	"sync"
)

type WalkStats struct {
	fileCount int
	dirCount  int
}

func walk(root string) WalkStats {
	fileCount := 0
	dirCount := 1

	entries, err := os.ReadDir(root)
	if err != nil {
		log.Fatal(err)
	}

	wg := sync.WaitGroup{}

	for _, entry := range entries {
		if entry.IsDir() {
			wg.Go(func() {
				addlStats := walk(path.Join(root, entry.Name()))
				fileCount += addlStats.fileCount
				dirCount += addlStats.dirCount
			})
		} else {
			fileCount++
		}
	}

	wg.Wait()

	return WalkStats{fileCount, dirCount}
}

func main() {
	root := os.Args[1]
	stats := walk(root)
	fmt.Println(stats.fileCount, "file(s)")
	fmt.Println(stats.dirCount, "directories(s)")
}
