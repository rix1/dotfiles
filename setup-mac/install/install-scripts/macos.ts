import { checkStatus, info, success } from "../utils/prompt.ts";

/**
 * Inspired by https://gist.github.com/DAddYE/2108403
 */

export async function setupMac() {
  for (const step of steps) {
    for (const cmd of step.cmd) {
      const command = Deno.run({ cmd: cmd.split(" ") });
      const { code } = await command.status();
      await checkStatus(code, step.name);
    }
  }
  info("Defaults set. Killing all affected applications...");

  const apps = "Finder Dock SystemUIServer";
  for (const app of apps.split(" ")) {
    const command = Deno.run({ cmd: ["killall", app] });
    const { code } = await command.status();
    await checkStatus(code, `Killing ${app}`);
  }

  success(
    "Completed configuring MacOS defaults. You might have to restart your computer for everything to take effect"
  );
}

const steps = [
  {
    name: "✅ Finder: Set column view for as default for all finder windows",
    cmd: ["defaults write com.apple.finder FXPreferredViewStyle Clmv"],
  },
  {
    name: "✅ Finder: Use current directory as default search scope in Finder",
    cmd: [
      `defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"`,
    ],
  },
  {
    name: "✅ Finder: Show all filename extensions in Finder",
    cmd: ["defaults write NSGlobalDomain AppleShowAllExtensions -bool true"],
  },
  {
    name: "✅ Finder: Show Path bar in Finder",
    cmd: ["defaults write com.apple.finder ShowPathbar -bool true"],
  },
  {
    name: "✅ Finder: Show Status bar in Finder",
    cmd: ["defaults write com.apple.finder ShowStatusBar -bool true"],
  },
  {
    name: "✅ Finder: Allow text selection in Quick Look",
    cmd: ["defaults write com.apple.finder QLEnableTextSelection -bool true"],
  },
  {
    name: "✅ Finder: Disable the warning when changing a file extension",
    cmd: [
      "defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false",
    ],
  },
  {
    name: "✅ System: Require password immediately after sleep or screen saver begins",
    cmd: [
      "defaults write com.apple.screensaver askForPassword -int 1",
      "defaults write com.apple.screensaver askForPasswordDelay -int 0",
    ],
  },
  {
    name: "✅ System: Show remaining battery time and percentage",
    cmd: [
      'defaults write com.apple.menuextra.battery ShowPercent -string "YES"',
      'defaults write com.apple.menuextra.battery ShowTime -string "YES"',
    ],
  },
  {
    name: "✅ System: Expand save panel by default",
    cmd: [
      "defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true",
    ],
  },
  {
    name: "✅ Dock: Automatically hide and show the Dock",
    cmd: ["defaults write com.apple.dock autohide -bool true"],
  },
  {
    name: "✅ Dock: Set the icon size of the Dock to 36 pixels",
    cmd: ["defaults write com.apple.dock tilesize -int 36"],
  },
  {
    name: "✅ Dock: Wipe all (default) app icons from the Dock",
    cmd: ["defaults write com.apple.dock persistent-apps -array"],
  },
  {
    name: "✅ Dock: Remove the auto-hiding Dock delay",
    cmd: ["defaults write com.apple.dock autohide-delay -float 0"],
  },
  {
    name: "✅ Trackpad: Enable tap to click on Trackpad and login screen",
    cmd: [
      "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true",
      "defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1",
      "defaults write com.apple.mouse.tapBehaviour -int 1",
    ],
  },
  {
    name: "✅ Trackpad: Blazingly fast trackpad",
    cmd: ["defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3"],
  },

  {
    name: "✅ Trackpad: Disable Natural Scroll Direction",
    cmd: [
      "defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
    ],
  },
  {
    name: "✅ Keyboard: Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)",
    cmd: ["defaults write NSGlobalDomain AppleKeyboardUIMode -int 3"],
  },
  {
    name: "✅ Keyboard: Automatically illuminate built-in MacBook keyboard in low light",
    cmd: ["defaults write com.apple.BezelServices kDim -bool true"],
  },
  {
    name: "✅ Keyboard: Turn off keyboard illumination when computer is not used for 5 minutes",
    cmd: ["defaults write com.apple.BezelServices kDimTime -int 300"],
  },
  {
    name: "✅ Keyboard: Disable auto-correct",
    cmd: [
      "defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false",
    ],
  },
  {
    name: "✅ Keyboard: Disable press-and-hold for keys in favor of key repeat",
    cmd: ["defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false"],
  },
  {
    name: "✅ Keyboard: Make key repeat blazingly fast",
    cmd: [
      "defaults write NSGlobalDomain InitialKeyRepeat -int 15",
      "defaults write NSGlobalDomain KeyRepeat -int 1",
    ],
  },
];
