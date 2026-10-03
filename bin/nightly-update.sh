#!/usr/bin/env bash
# nightly-update.sh -- update Homebrew and everything it installed.
#
# Run at 3am by launchd (launchd/com.dion.nightly-update.plist, installed by
# install.sh / `dot link` on macOS); if the Mac is asleep then, it runs on
# wake. Safe to run by hand. Log: ~/Library/Logs/nightly-update.log
#
# To update more tools, add them at the bottom -- no reload needed, launchd
# runs whatever this file says next time.

set -uo pipefail

# launchd starts jobs with a bare PATH, so find brew rather than assume it:
# /opt/homebrew on Apple Silicon, /usr/local on Intel, linuxbrew on Linux.
brew=""
for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$b" ] && { brew="$b"; break; }
done
[ -n "$brew" ] || { echo "nightly-update: no Homebrew found, nothing to do"; exit 0; }
eval "$("$brew" shellenv)"

export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1   # `brew update` runs explicitly below

echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

brew update
brew upgrade --formula          # all formulae (gh included); `brew upgrade gh ...` to limit it
brew upgrade --cask || true     # casks may need a password; logged, not fatal
brew cleanup --prune=30

# Add other tools here, e.g.:
# npm update -g
# rustup update

echo "===== done $(date '+%H:%M:%S') ====="
