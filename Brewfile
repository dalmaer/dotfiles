# Every machine gets these: install.sh runs `brew bundle` on this file, then on
# ~/Brewfile.local (this machine's own extras, never committed). Both only ever
# add; nothing here uninstalls. Upgrades are nightly-update.sh's job.
#
# This repo is public: anything listed here says what you use.

# --- Shell -------------------------------------------------------------
brew "starship"
brew "zsh-completions"
brew "fnm"                 # Node versions; corepack comes with each Node
brew "tmux"
brew "mosh"

# --- Everyday tools ----------------------------------------------------
brew "gh"
brew "git-filter-repo"
brew "git-lfs"             # gitconfig sets up the lfs filter
brew "ripgrep"
brew "tree"
brew "ffmpeg"
brew "age"
brew "uv"                  # Python versions, venvs and tools
brew "iperf3"              # network speed between machines (iperf3 -s / -c)

# --- Runtimes ----------------------------------------------------------
brew "bun"

# --- Apps (macOS) ------------------------------------------------------
# An app already in /Applications is adopted (brew bundle passes --adopt):
# Homebrew takes it over and keeps the copy that is there. All of these update
# themselves, so adopting skips the version match, and `brew upgrade --cask`
# leaves them alone unless asked with --greedy.
if OS.mac?
  cask "tailscale-app"
  cask "gcloud-cli"

  tap "spacefarm-digital/tap"
  cask "spacefarm-digital/tap/sunlight"   # Apple Silicon only; Sparkle updates it

  cask "1password"
  cask "1password-cli"     # `op`, for filling secrets.env from the vault
  cask "google-chrome"
  cask "visual-studio-code"
  cask "warp"
  cask "github"            # GitHub Desktop
  cask "claude"
  cask "chatgpt"
  cask "conductor"
  cask "antigravity"
  cask "repo-prompt"
  cask "linear"
  cask "obsidian"
  cask "evernote"
  cask "discord"
  cask "signal"
  cask "wispr-flow"
  cask "monologue"
  cask "istat-menus"

  # Not here: zoom, expressvpn, guitar-pro, qfinder-pro. Their casks run a .pkg
  # installer that asks for an admin password, which the 3am job cannot give,
  # so they would fail every night. Install them by hand (or put them in
  # ~/Brewfile.local and run `brew bundle` once while at the keyboard).

  # --- Mac App Store ---------------------------------------------------
  # Needs `mas` and an App Store sign-in. Installs only; the App Store updates them.
  brew "mas"
  mas "Xcode", id: 497799835
  mas "Developer", id: 640199958
  mas "Slack", id: 803453959
  mas "Todoist", id: 585829637
  mas "WhatsApp", id: 310633997
  mas "Keynote", id: 409183694
  mas "Numbers", id: 409203825
  mas "Pages", id: 409201541
  mas "GarageBand", id: 682658836
  mas "iMovie", id: 408981434
end

# --- Global npm --------------------------------------------------------
# install.sh installs these with npm itself, not brew bundle (see why there).
# Claude Code is not here: it installs and updates itself (~/.local/bin/claude).
npm "@openai/codex"
