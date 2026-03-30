import fs from "fs/promises";
import { join } from "path";

const root = process.argv[2];

async function walk(root: string) {
	const counts = {
		files: 0,
		dirs: 1,
	};

	const children = await fs.readdir(root, { withFileTypes: true });
	for (const child of children) {
		if (child.isDirectory()) {
			const childCounts = await walk(join(child.parentPath, child.name));
			counts.files += childCounts.files;
			counts.dirs += childCounts.dirs;
		} else {
			counts.files++;
		}
	}
	return counts;
}

const counts = await walk(root);

console.log(`${counts.files} file(s)`);
console.log(`${counts.dirs} directories(s)`);
