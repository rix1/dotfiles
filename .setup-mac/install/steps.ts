import { Checkbox } from "https://deno.land/x/cliffy@v0.25.7/prompt/checkbox.ts";
import { nanoid } from "https://deno.land/x/nanoid/mod.ts";

import { installBrew, installBrewApps } from "./install-scripts/brew.ts";
import { installFish } from "./install-scripts/fish.ts";
import { installFonts } from "./install-scripts/fonts.ts";
import { setupMac } from "./install-scripts/macos.ts";

import { installFishApps } from "./install-scripts/fish.ts";
import { humanizeTime } from "./utils/time.ts";

const MINUTE = 60; // seconds

export const steps = {
  [nanoid()]: {
    name: "Set MacOS defaults",
    timeEstimate: 10,
    fn: setupMac,
  },
  [nanoid()]: {
    name: "Install brew",
    timeEstimate: MINUTE * 2,
    fn: installBrew,
  },
  [nanoid()]: {
    name: "Install command line software (Brew)",
    timeEstimate: MINUTE * 5,
    fn: () => installBrewApps("./requirements/brew.txt"),
  },
  [nanoid()]: {
    name: "Install useful software (Brew cask)",
    timeEstimate: MINUTE * 4,
    fn: () => installBrewApps("./requirements/cask.txt"),
  },
  [nanoid()]: {
    name: "Install Fish shell",
    timeEstimate: MINUTE * 2,
    fn: installFish,
  },
  [nanoid()]: {
    name: "Install Fish plugins (Fisher)",
    timeEstimate: MINUTE,
    fn: () => installFishApps("./requirements/fish.txt"),
  },
  [nanoid()]: {
    name: "Install fonts",
    timeEstimate: 10,
    fn: installFonts,
  },
};

export const stepIds = Object.keys(steps);

export async function selectSteps() {
  const selectedSteps: string[] = await Checkbox.prompt({
    message: "Select steps",
    options: stepIds.map((id) => ({
      name: `${steps[id].name}. (ETA ${humanizeTime(steps[id].timeEstimate)})`,
      value: id,
    })),
  });
  return selectedSteps;
}
