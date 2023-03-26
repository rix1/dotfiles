import { Checkbox } from "https://deno.land/x/cliffy@v0.25.7/prompt/checkbox.ts";
import { Confirm } from "https://deno.land/x/cliffy@v0.25.7/prompt/confirm.ts";
import {
  exec,
  execSequence,
  OutputMode,
} from "https://deno.land/x/exec@0.0.5/mod.ts";
import { resolvePath } from "../utils/filePaths.ts";
import { checkStatus, info, success, warn } from "../utils/prompt.ts";

export async function installBrew() {
  const previousInstallation = await exec("which brew", {
    output: OutputMode.Capture,
  });

  if (previousInstallation.status.success) {
    success("Brew already installed, nothing to do.");
    return;
  } else {
    warn("Installing brew");

    const scriptSrc = await exec(
      "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh",
      { output: OutputMode.Capture }
    );
    const p = Deno.run({ cmd: ["/bin/bash", "-c", scriptSrc.output] });

    const { code } = await p.status();

    checkStatus(code, "Brew installation 🍺");

    await execSequence(
      [
        `(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile`,
        `eval "$(/opt/homebrew/bin/brew shellenv)"`,
      ],
      { output: OutputMode.Capture }
    );

    success("✅ Brew installed and configured");
  }
}

export async function installBrewApps(sourcePath: string) {
  const file = await Deno.readTextFile(resolvePath(sourcePath));
  const input = file.trim().split("\n");

  const apps = await Checkbox.prompt({
    message: "What programs do you wish to install with Brew?",
    options: input,
  });
  if (
    !(await Confirm.prompt(
      `Will install ${apps.length} applications. Continue?`
    ))
  ) {
    info("Will not install any Brew dependencies");
    return;
  }

  const p = Deno.run({ cmd: ["brew", "install", ...apps] });

  const { code } = await p.status();
  checkStatus(
    code,
    `Brew app installation from ${sourcePath.split("/").at(-1)} 🍻`
  );
}
