/**
 * Extracts plan data from .claude/plans/open/ and .claude/plans/done/ directories.
 * Generates plans.json with all open and done plans.
 * 
 * Runs via GitHub Actions (hourly) or manual npm script.
 * Output: docs/public/data/plans.json
 */

import fs from "fs";
import path from "path";

interface PlanData {
  date: string;
  slug: string;
  title: string;
  preface: string;
  status: "open" | "done";
}

/**
 * Extract date from filename like "2026-02-06-list-scrollable.md"
 */
function extractDate(filename: string): string {
  const match = filename.match(/^(\d{4}-\d{2}-\d{2})/);
  return match ? match[1] : "";
}

/**
 * Extract slug from filename like "2026-02-06-list-scrollable.md"
 */
function extractSlug(filename: string): string {
  const match = filename.match(/^\d{4}-\d{2}-\d{2}-(.+)\.md$/);
  return match ? match[1] : "";
}

/**
 * Extract H1 title from markdown content
 */
function extractTitle(content: string): string {
  const match = content.match(/^#\s+(.+)$/m);
  return match ? match[1].trim() : "Untitled";
}

/**
 * Extract first ## section (Preface) from markdown content.
 * Returns the full text until the next ## section or end of file.
 */
function extractPreface(content: string): string {
  // Find first ## section
  const match = content.match(/^##\s+Preface\s*\n([\s\S]*?)(?=\n##\s|\Z)/m);
  return match ? match[1].trim() : "";
}

/**
 * Read all plan files from a directory
 */
function readPlansFromDir(dirPath: string, status: "open" | "done"): PlanData[] {
  if (!fs.existsSync(dirPath)) {
    console.warn(`Directory not found: ${dirPath}`);
    return [];
  }

  const files = fs.readdirSync(dirPath).filter((f) => f.endsWith(".md"));

  return files
    .map((filename) => {
      const filePath = path.join(dirPath, filename);
      const content = fs.readFileSync(filePath, "utf-8");

      return {
        date: extractDate(filename),
        slug: extractSlug(filename),
        title: extractTitle(content),
        preface: extractPreface(content),
        status,
      };
    })
    .filter((plan) => plan.date && plan.slug && plan.preface); // Skip invalid plans
}

/**
 * Main execution
 */
function main() {
  const projectRoot = path.resolve(process.cwd(), "..");
  const openDir = path.join(projectRoot, ".claude", "plans", "open");
  const doneDir = path.join(projectRoot, ".claude", "plans", "done");

  // Read all plans
  const openPlans = readPlansFromDir(openDir, "open");
  const donePlans = readPlansFromDir(doneDir, "done");

  // Sort by date (newest first)
  const sortByDateDesc = (a: PlanData, b: PlanData) =>
    new Date(b.date).getTime() - new Date(a.date).getTime();

  openPlans.sort(sortByDateDesc);
  donePlans.sort(sortByDateDesc);

  // Build output with all plans
  const output = {
    generated: new Date().toISOString(),
    open: openPlans.map(({ date, slug, title, preface }) => ({
      date,
      slug,
      title,
      preface,
    })),
    done: donePlans.map(({ date, slug, title, preface }) => ({
      date,
      slug,
      title,
      preface,
    })),
  };

  // Ensure output directory exists
  const outputDir = path.join(process.cwd(), "public", "data");
  fs.mkdirSync(outputDir, { recursive: true });

  // Write JSON
  const outputPath = path.join(outputDir, "plans.json");
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));

  console.log(
    `✓ Generated plans.json (${openPlans.length} open, ${donePlans.length} done)`
  );
  console.log(`  Location: ${outputPath}`);
}

main();
