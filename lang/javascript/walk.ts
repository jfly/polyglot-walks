import fs from "fs/promises";
import { join } from "path";

const root = process.argv[2];

let fileCount = 0;
let dirCount = 0;

const fringe = [root];
while (true) {
	const dir = fringe.pop();
	if (dir == null) {
		break;
	}

	dirCount++;
	const children = await fs.readdir(dir, { withFileTypes: true });
	for (const child of children) {
		if (child.isDirectory()) {
			fringe.push(join(child.parentPath, child.name));
		} else {
			fileCount++;
		}
	}
}

console.log(`${fileCount} file(s)`);
console.log(`${dirCount} directories(s)`);
