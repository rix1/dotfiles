import { exec } from "https://deno.land/x/exec@0.0.5/mod.ts";
import { checkStatus, info } from "../utils/prompt.ts";

export async function installFonts() {
  // =========== Remote fonts ===========
  await exec("brew tap homebrew/cask-fonts");
  const p = Deno.run({
    cmd: "brew install --cask font-fira-mono-nerd-font font-fira-code-nerd-font".split(
      " "
    ),
  });
  const { code: remoteStatusCode } = await p.status();
  await checkStatus(remoteStatusCode, "Remote font installation");

  // =========== Local fonts ===========
  info("Installing local fonts");

  const localCopy = Deno.run({
    cmd: "/bin/bash -c ./fonts/install.sh".split(" "),
  });
  const { code: localStatusCode } = await localCopy.status();
  await checkStatus(localStatusCode, "Local font installation");
}
