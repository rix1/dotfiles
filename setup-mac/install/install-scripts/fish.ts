import { Checkbox } from "https://deno.land/x/cliffy@v0.25.7/prompt/checkbox.ts";
import { Confirm } from "https://deno.land/x/cliffy@v0.25.7/prompt/confirm.ts";
import { exec, OutputMode } from "https://deno.land/x/exec@0.0.5/mod.ts";
import { resolvePath } from "../utils/filePaths.ts";
import { checkStatus, info, success, warn } from "../utils/prompt.ts";

export async function installFish() {
  const previousInstallation = await exec("which fish", {
    output: OutputMode.Capture,
  });

  if (previousInstallation.status.success) {
    success("Fish already installed, setting shell...");
    // Add fish shell to /etc/shells
    await exec("sudo echo /opt/homebrew/bin/fish >> /etc/shells");
    success("✅ Added Fish to /etc/shells");

    await exec("chsh -s $(which fish)");
    success("✅ Changed shell to Fish");
    return;
  } else {
    warn("Installing Fish");

    const command = await exec("brew install fish", {
      output: OutputMode.StdOut,
    });

    await checkStatus(command.status.code, "Fish installation 🐟");

    // Add fish shell to /etc/shells
    await exec("sudo echo /opt/homebrew/bin/fish >> /etc/shells");
    success("✅ Added Fish to /etc/shells");

    await exec("chsh -s $(which fish)");
    success("✅ Changed shell to Fish");
  }
}

export async function installFishApps(sourcePath: string) {
  info("First installing Fisher. You can choose plugins once complete.");

  const res = await exec(
    `bash -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher`,
    { output: OutputMode.StdOut }
  );

  await checkStatus(res.status.code, "Fisher installation");

  const file = await Deno.readTextFile(sourcePath);
  const input = file.trim().split("\n");

  const apps = await Checkbox.prompt({
    message: "What Fish plugins do you wish to install?",
    options: input,
  });

  if (
    !(await Confirm.prompt(`Will install ${apps.length} plugins. Continue?`))
  ) {
    info("Will not install any Fish plugins");
    return;
  }

  const fisherPlugins = await exec(`fisher install ${apps.join(" ")}`);

  await checkStatus(fisherPlugins.status.code, "Fisher plugins");
}
