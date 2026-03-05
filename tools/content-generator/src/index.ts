#!/usr/bin/env node

/**
 * @module index
 *
 * CLI entry point for the Langu content generator.
 *
 * Usage:
 *   langu-generate generate -n English -t Korean
 *   langu-generate generate -n English -t Korean -o ./content --units 8 --lessons-per-unit 6
 */

import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { Command } from "commander";
import { ContentGenerator } from "./generator.js";

// ---------------------------------------------------------------------------
// CLI setup
// ---------------------------------------------------------------------------

const program = new Command();

program
  .name("langu-generate")
  .description("Generate language learning content using Anthropic Claude")
  .version("1.0.0");

program
  .command("generate")
  .description("Generate units, stories, and themes for language learning")
  .requiredOption(
    "-n, --native <language>",
    "Learner's native language (e.g. English)",
  )
  .requiredOption(
    "-t, --target <language>",
    "Target language to learn (e.g. Korean)",
  )
  .option("-o, --output <dir>", "Output directory", "./output")
  .option("--units <count>", "Number of units to generate", "6")
  .option(
    "--lessons-per-unit <count>",
    "Number of lessons per unit",
    "5",
  )
  .option("--stories <count>", "Number of stories to generate", "5")
  .option("--themes <count>", "Number of themes to generate", "6")
  .action(async (options: GenerateOptions) => {
    await runGenerate(options);
  });

program.parse();

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface GenerateOptions {
  native: string;
  target: string;
  output: string;
  units: string;
  lessonsPerUnit: string;
  stories: string;
  themes: string;
}

// ---------------------------------------------------------------------------
// Main generation flow
// ---------------------------------------------------------------------------

async function runGenerate(options: GenerateOptions): Promise<void> {
  // --- Validate API key --------------------------------------------------
  if (!process.env["ANTHROPIC_API_KEY"]) {
    console.error(
      "Error: ANTHROPIC_API_KEY environment variable is not set.\n" +
        "Set it in your shell or create a .env file:\n" +
        "  export ANTHROPIC_API_KEY=sk-ant-...",
    );
    process.exit(1);
  }

  // --- Parse numeric options ---------------------------------------------
  const unitCount = parseInt(options.units, 10);
  const lessonsPerUnit = parseInt(options.lessonsPerUnit, 10);
  const storyCount = parseInt(options.stories, 10);
  const themeCount = parseInt(options.themes, 10);

  if ([unitCount, lessonsPerUnit, storyCount, themeCount].some(Number.isNaN)) {
    console.error("Error: --units, --lessons-per-unit, --stories, and --themes must be numbers.");
    process.exit(1);
  }

  // --- Resolve output directory ------------------------------------------
  const outputDir = resolve(options.output);

  console.log("=".repeat(60));
  console.log("  Langu Content Generator");
  console.log("=".repeat(60));
  console.log();
  console.log(`  Native language:   ${options.native}`);
  console.log(`  Target language:   ${options.target}`);
  console.log(`  Units:             ${unitCount} (${lessonsPerUnit} lessons each)`);
  console.log(`  Stories:           ${storyCount}`);
  console.log(`  Themes:            ${themeCount}`);
  console.log(`  Output directory:  ${outputDir}`);
  console.log();

  // --- Ensure output directory exists ------------------------------------
  await mkdir(outputDir, { recursive: true });

  const generator = new ContentGenerator();
  const sharedOpts = {
    nativeLanguage: options.native,
    targetLanguage: options.target,
  };

  // --- Generate units ----------------------------------------------------
  console.log("[1/3] Generating lesson units...");
  const startUnits = performance.now();
  const units = await generator.generateUnits({
    ...sharedOpts,
    unitCount,
    lessonsPerUnit,
  });
  const unitsPath = resolve(outputDir, "units.json");
  await writeFile(unitsPath, JSON.stringify(units, null, 2) + "\n", "utf-8");
  const unitsTime = ((performance.now() - startUnits) / 1000).toFixed(1);
  const totalLessons = units.units.reduce((sum, u) => sum + u.lessons.length, 0);
  console.log(
    `       Done: ${units.units.length} units, ${totalLessons} lessons (${unitsTime}s)`,
  );

  // --- Generate stories --------------------------------------------------
  console.log("[2/3] Generating stories...");
  const startStories = performance.now();
  const stories = await generator.generateStories({
    ...sharedOpts,
    storyCount,
  });
  const storiesPath = resolve(outputDir, "stories.json");
  await writeFile(storiesPath, JSON.stringify(stories, null, 2) + "\n", "utf-8");
  const storiesTime = ((performance.now() - startStories) / 1000).toFixed(1);
  const totalSentences = stories.stories.reduce(
    (sum, s) => sum + s.sentences.length,
    0,
  );
  console.log(
    `       Done: ${stories.stories.length} stories, ${totalSentences} sentences (${storiesTime}s)`,
  );

  // --- Generate themes ---------------------------------------------------
  console.log("[3/3] Generating conversation themes...");
  const startThemes = performance.now();
  const themes = await generator.generateThemes({
    ...sharedOpts,
    themeCount,
  });
  const themesPath = resolve(outputDir, "themes.json");
  await writeFile(themesPath, JSON.stringify(themes, null, 2) + "\n", "utf-8");
  const themesTime = ((performance.now() - startThemes) / 1000).toFixed(1);
  console.log(
    `       Done: ${themes.themes.length} themes (${themesTime}s)`,
  );

  // --- Summary -----------------------------------------------------------
  console.log();
  console.log("=".repeat(60));
  console.log("  Generation complete!");
  console.log("=".repeat(60));
  console.log();
  console.log(`  Files written:`);
  console.log(`    ${unitsPath}`);
  console.log(`    ${storiesPath}`);
  console.log(`    ${themesPath}`);
  console.log();
}
