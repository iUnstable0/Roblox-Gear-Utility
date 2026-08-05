import { basename, dirname, extname, join, resolve } from "node:path";

const args = Bun.argv.slice(2);
const inPlace = args.includes("--in-place");
const paths = args.filter((arg) => arg !== "--in-place");
const inputPath = paths[0];

if (!inputPath || paths.length > 2) {
  console.error(
    "Usage: bun run minify-json.ts <input.json> [output.json] [--in-place]",
  );
  process.exit(1);
}

if (inPlace && paths[1]) {
  console.error("Do not provide an output file when using --in-place.");
  process.exit(1);
}

const absoluteInputPath = resolve(inputPath);
const extension = extname(absoluteInputPath);

if (extension.toLowerCase() !== ".json") {
  console.error(`Expected a .json file, received: ${inputPath}`);
  process.exit(1);
}

const defaultOutputName = `${basename(absoluteInputPath, extension)}.min.json`;
const outputPath = inPlace
  ? absoluteInputPath
  : resolve(paths[1] ?? join(dirname(absoluteInputPath), defaultOutputName));

try {
  const inputFile = Bun.file(absoluteInputPath);

  if (!(await inputFile.exists())) {
    throw new Error(`File not found: ${absoluteInputPath}`);
  }

  const json = await inputFile.json();
  const minified = JSON.stringify(json);

  await Bun.write(outputPath, minified);
  console.log(`Minified JSON written to ${outputPath}`);
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Could not minify JSON: ${message}`);
  process.exit(1);
}
