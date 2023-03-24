import { join } from "https://deno.land/std@0.116.0/path/mod.ts";

export function resolvePath(filePath: string): string {
  const currentWorkingDirectory = Deno.cwd();
  console.log(join(currentWorkingDirectory, filePath));

  return join(currentWorkingDirectory, filePath);
}
