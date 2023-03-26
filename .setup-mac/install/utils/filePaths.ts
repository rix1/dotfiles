import dir from "https://deno.land/x/dir/mod.ts";
import { join } from "https://deno.land/std@0.116.0/path/mod.ts";

export function getRequirementsPath(fileName: string): string {
  const homeDirectory = dir("home");
  if (!homeDirectory) {
    throw new Error("Could not resolve $HOME");
  }

  const filePath = join(
    homeDirectory,
    ".setup-mac",
    "install",
    "requirements",
    fileName
  );
  return filePath;
}
