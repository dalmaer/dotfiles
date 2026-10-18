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
brew "ripgrep"
brew "tree"
brew "ffmpeg"

# --- Runtimes ----------------------------------------------------------
brew "bun"

# --- Apps (macOS) ------------------------------------------------------
if OS.mac?
  cask "tailscale-app"
  cask "gcloud-cli"
end

# --- Global npm --------------------------------------------------------
# Claude Code is not here: it installs and updates itself (~/.local/bin/claude).
npm "@openai/codex"
