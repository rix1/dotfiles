import {
  Confirm,
  Input,
} from "https://deno.land/x/cliffy@v0.25.7/prompt/mod.ts";
import { selectSteps, steps } from "./steps.ts";
import { info, success } from "./utils/prompt.ts";
import { sumTime } from "./utils/time.ts";

let email: string, name: string;

// await promptSudo();
await initialize();

// await selectSteps();

async function initialize() {
  email = await Input.prompt({
    message: "Enter your email",
    default: email ?? "rikardeide@gmail.com",
  });

  name = await Input.prompt({
    message: "Enter your name",
    default: name ?? "Rikard Eide",
  });

  if (
    !(await Confirm.prompt(
      "We'll use this info for configuring Git. Is everything correct?"
    ))
  ) {
    await initialize();
  }

  info("\nAll set! Now what can I do for you today?");

  const stepsToDo = await selectSteps();
  // returns a list of IDs to do. Next print total time.

  info(
    `\nPerfect, I will do ${
      stepsToDo.length
    } jobs for you. Total ETA is ${sumTime(
      stepsToDo.map((id) => steps[id].timeEstimate)
    )}`
  );

  if (!(await Confirm.prompt("Ready to roll?"))) {
    info("Exiting...");

    Deno.exit(0);
  }

  for (let i = 0; i < stepsToDo.length; i++) {
    const stepId = stepsToDo[i];
    await steps[stepId].fn();
  }
  success(
    "🎉 Congrats! We're done setting up your machine. Now go build something 🎉"
  );
}
