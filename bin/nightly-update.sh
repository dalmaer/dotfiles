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

# launchd doesn't read shell/env.sh either. Without this, brew looks for its
# tap-trust list in ~/.homebrew instead of ~/.config/homebrew, where
# `brew trust` saved it from a shell, and skips every third-party tap.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1   # `brew update` runs explicitly below

echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

brew update
brew upgrade --formula          # all formulae (gh included); `brew upgrade gh ...` to limit it
brew upgrade --cask || true     # casks may need a password; logged, not fatal
brew cleanup --prune=30

# Pick up anything newly added to the shared or local Brewfile. Installs only;
# never upgrades (done above) or removes.
#
# npm lines are held back, as in install.sh: brew bundle runs npm with a PATH
# that only has the `node` formula's bin, so on a Mac whose node comes from
# fnm or node@22 every npm entry fails with "env: node: No such file".
npm_pkgs=""
for bf in "$HOME/.dotfiles/Brewfile" "$HOME/Brewfile.local"; do
  [ -r "$bf" ] || continue
  { grep -v -E '^[[:space:]]*npm[[:space:]]' "$bf" || true; } | brew bundle install --no-upgrade --file=-
  npm_pkgs="$npm_pkgs $(sed -n -E 's/^[[:space:]]*npm[[:space:]]+"([^"]+)".*/\1/p' "$bf")"
done
npm_pkgs="$(echo $npm_pkgs)"   # unquoted on purpose: collapses whitespace

# launchd's PATH has no fnm shims, so ask fnm for its default node when there
# is no npm on PATH after `brew shellenv`.
npm_cmd=""
if command -v npm >/dev/null 2>&1; then
  npm_cmd="npm"
elif command -v fnm >/dev/null 2>&1; then
  npm_cmd="fnm exec --using=default -- npm"
fi
for pkg in $npm_pkgs; do
  if [ -z "$npm_cmd" ]; then
    echo "nightly-update: no node or npm found, skipped npm packages: $npm_pkgs"
    break
  fi
  # Only the Brewfiles' packages: globals installed some other way are left alone.
  # `install @latest`, not `npm update -g`: update also tries to rewrite npm's
  # own files, which Homebrew's node keeps read-only (EACCES on npm/npmrc).
  $npm_cmd install -g "$pkg@latest" >/dev/null || echo "nightly-update: npm install -g $pkg@latest failed"
done

# Claude Code's native install updates itself only when it starts, so a Mac
# where nobody ran `claude` today would fall behind.
if [ -x "$HOME/.local/bin/claude" ]; then
  "$HOME/.local/bin/claude" update || echo "nightly-update: claude update failed"
fi

# Add other tools here, e.g.:
# rustup update

# This machine's own nightly steps, kept outside this public repo: every
# executable in ~/.config/nightly-update.d runs last, in name order, with the
# PATH set up above. One failing is logged and does not stop the others.
hooks="$HOME/.config/nightly-update.d"
if [ -d "$hooks" ]; then
  for hook in "$hooks"/*; do
    [ -f "$hook" ] && [ -x "$hook" ] || continue
    echo "--- $(basename "$hook")"
    "$hook"
    rc=$?
    [ "$rc" = 0 ] || echo "nightly-update: $(basename "$hook") failed (exit $rc)"
  done
fi

echo "===== done $(date '+%H:%M:%S') ====="
