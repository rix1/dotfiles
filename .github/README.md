# Welcome 👋

This is my personal dotfiles in its current (most likely not final) form. It's
using a git bare repo along with a hand crafted installation CLI.

## What's included?

- [Brew](https://brew.sh/) and Brew cask programs
- [iTerm2](https://iterm2.com/) is still my weapon of choice. Might move to Warp once they improve Fish support.
- [Fish shell](https://fishshell.com/) & [Fisher](https://github.com/jorgebucaran/fisher). Comes with [git aliases](https://github.com/jhillyerd/plugin-git), [fzf](https://github.com/PatrickF1/fzf.fish) for easy search and [z](https://github.com/jethrokuan/z) for jumping around directories.
- [Starship](https://starship.rs/) prompt
- A couple of fonts, some of which from [Nerd Fonts](https://www.nerdfonts.com/)
- Bare repo with no aliases for dotfiles 🎉

![example](https://user-images.githubusercontent.com/2470775/227767097-0907205d-33ee-4566-8a76-22621d1b985b.png)

## Installation and setup instructions

1. Clone the repo in your home root. We're using the `git --bare` repo approach to avoid symlinking all the dotfiles. See this [guide for more details](https://www.ackama.com/what-we-think/the-best-way-to-store-your-dotfiles-a-bare-git-repository-explained/).
   1. `git clone --bare https://github.com/rix1/dotfiles $HOME/.dotfiles`
   2. Make a temporary alias `alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'`. After everything's been set up, you can use the `configure` command to interact with the `.dotfiles` git repo.
   3. `config config --local status.showUntrackedFiles no`
   4. `config checkout`.
   5. Ensure that dotfiles have been added (e.g. `.config/`).
2. Download the `configure-macos` binary from the repo's [release page on Github](https://github.com/rix1/dotfiles/releases) and run it

   ```sh
   chmod -x configure-macos # make it executable
   ./configure-macos
   ```

   This is an interactive prompt that will guide you through configuring sane Mac defaults and install recommended software. See [configuration options below](#customizing-the-default-recommendations). The binary is a standalone compiled version of the `install.ts` Deno script. It will ask for permissions as you go.

   **Important:** The script assumes it can find installation requirements in `$HOME/setup-mac/install/requirements/`. Keep this in mind if you ever change the directory structure @rix1.

3. Set iterm2 theme and fonts.

4. Debug colors, syntax highlighting etc

5. If you are using PGP and have your GPG key stored on Keybase, check out this
   guide: https://blog.scottlowe.org/2017/09/06/using-keybase-gpg-macos/

Sidenote to self: I really recommend authenticating with Github using their CLI (`gh`), this is a lot easier than generating and setting SSH keys.

## Updating your dotfiles

I've added Fish alias to make it easy to update your dotfiles, simply run
`configure` to enter "maintenance mode". This will alias git to make it easier
to work with the bare repo.

### Navigating the configuration

```
$HOME
├── .config/          # Most config should go here
│      ├── fish
│      ├── gh
│      ├── iterm2
│      └── raycast
├── .dotfiles/        # Bare repo - you shouldn't change anything here
├── .gitconfig
├── .github           # Dotfiles README (the one you're currently reading)
│      ├── README.md
│      └── workflows
└── .setup-mac/       # Setup scripts

```

### Customizing the default recommendations

When running the install script, it will ask you which programs you want to install. To edit the list of apps, edit the txt files in the `requirements/` directory:

```
.setup-mac/
└── install
    └── requirements
        ├── brew.txt
        ├── cask.txt
        └── fish.txt

```

### Releasing

I've configured a Github action in `.github/workflows/release.yml`. This workflow triggers on push events with a tag that starts with "v"
(e.g., v1.0.0). It sets up Deno, compiles your Deno app, creates a new
release, and uploads the compiled binary as a release asset.

So to release a new version, simply push a new tag:

```sh
git tag v1.0.0 && git push --tags
```

This will trigger the workflow, and a new release with the compiled binary will be created on the GitHub repository.

## Fonts

- Vscode: Dank Mono, FiraCode Nerd Font, Menlo, Monaco, Courier New, monospace
- iTerm: FiraCode Nerd Font Mono

Note: Only Dank mono is included in this repo. You need to install the others
separately:

- https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode

### Troubleshooting

- Is is something wrong with the fonts? Try `echo \ue0b0 \u00b1 \ue0a0 \u27a6
\u2718 \u26a1 \u2699`. This should look like this ![Icons](../.setup-mac/characters.png)
- The install script should change shell for you, but in case it doesn't here's
  how you do it: `chsh -s $(which fish)`. You might have to add
  `/opt/homebrew/bin/fish` to `/etc/shells` for this to work: `sudo echo
/opt/homebrew/bin/fish >> /etc/shells`.

- For Celery (GDAL really) to work make sure `DYLD_LIBRARY_PATH` is set:
  ```
  ~/Desktop via  v19.3.0 on ☁️  (eu-central-1)
  ❯ echo $DYLD_LIBRARY_PATH
  /opt/homebrew/lib/
  ```
