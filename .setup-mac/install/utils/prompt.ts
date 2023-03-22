import { colors } from "https://deno.land/x/cliffy@v0.25.6/ansi/colors.ts";
import { exec } from "https://deno.land/x/exec/mod.ts";

import { Confirm } from "https://deno.land/x/cliffy@v0.25.7/prompt/mod.ts";

// Define theme colors.
export const error = (str: string) => console.error(colors.bold.red(str));
export const warn = (str: string) => console.log(colors.bold.yellow(str));
export const info = (str: string) => console.log(colors.bold.blue(str));
export const success = (str: string) => console.log(colors.bold.green(str));

export async function confirmStep(desc: string) {
  return await Confirm.prompt(`Continue to ${desc}`);
}

export async function checkStatus(code: number, type: string) {
  if (code !== 0) {
    error(`An error occurred during ${type}.`);
    if (await confirmStep("next step?")) {
      return;
    }
    Deno.exit(0);
  }
  success(`Completed: ${type}.`);
}

export async function promptSudo() {
  info("We might need your sudo password to install/configure");
  await exec(`sudo -v`); // validates the sudo password and caches it for 5 minutes
  await exec(`sudo -n`); // non-interactive – avoids propmpting for sudo again
  info("ℹ️  Sudo password set. You will not be asked again for 5 minutes.");
}
