#!/usr/bin/env bash
# Shared helpers for install.sh and bin/dot. Sourced, never executed.

# --- Where the repo lives -----------------------------------------------
# Resolve even when invoked through a symlink (~/bin/dot -> repo/bin/dot).
_resolve() {
  local p="$1"
  while [ -L "$p" ]; do
    local t; t="$(readlink "$p")"
    case "$t" in /*) p="$t" ;; *) p="$(dirname "$p")/$t" ;; esac
  done
  printf '%s\n' "$p"
}
DOTFILES="${DOTFILES:-$(cd "$(dirname "$(_resolve "${BASH_SOURCE[0]}")")/.." && pwd)}"
export DOTFILES

# --- Platform detection -------------------------------------------------
case "$(uname -s)" in
  Darwin) OS=darwin ;;
  Linux)  OS=linux  ;;
  *)      OS=unknown ;;
esac
ARCH="$(uname -m)"
export OS ARCH

# --- Output -------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
  C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_BLU=$'\033[34m'
else
  C_RESET=; C_DIM=; C_RED=; C_GRN=; C_YEL=; C_BLU=
fi

info() { printf '%s\n' "  $*"; }
step() { printf '%s\n' "${C_BLU}==>${C_RESET} $*"; }
ok()   { printf '%s\n' "  ${C_GRN}ok${C_RESET}   $*"; }
skip() { printf '%s\n' "  ${C_DIM}skip${C_RESET} $*"; }
warn() { printf '%s\n' "  ${C_YEL}warn${C_RESET} $*" >&2; }
die()  { printf '%s\n' "${C_RED}error${C_RESET} $*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- Symlinking ---------------------------------------------------------
# link <repo-relative-source> <absolute-target>
# Idempotent. Backs up anything real that is already in the way.
# Backups live inside the repo so they sit next to what replaced them.
# .gitignore excludes backup/ -- it must never be committed, since a
# backed-up shell config can carry internal hostnames or exported keys.
BACKUP_DIR="${BACKUP_DIR:-$DOTFILES/backup/$(date +%Y%m%d-%H%M%S)}"

# DRY_RUN=1 makes every mutating helper print what it would do and change
# nothing. run() is the single choke point -- if a helper mutates state, it
# must go through run() or it will lie in dry-run mode.
DRY_RUN="${DRY_RUN:-0}"
REPLACED=""   # newline-separated paths link() moved aside (or would have)
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  %swould%s %s\n' "$C_YEL" "$C_RESET" "$*"
  else
    "$@"
  fi
}

link() {
  local src="$DOTFILES/$1" dst="$2"

  [ -e "$src" ] || { warn "missing source: $1"; return 1; }
  [ "$DRY_RUN" = "1" ] || mkdir -p "$(dirname "$dst")"

  # Already pointing where we want it.
  if [ -L "$dst" ] && [ "$(_resolve "$dst")" = "$(_resolve "$src")" ]; then
    skip "$(_tilde "$dst")"
    return 0
  fi

  # Something real is in the way -- preserve it. Never delete.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      warn "existing $(_tilde "$dst") would be backed up to $(_tilde "$BACKUP_DIR")/"
      REPLACED="${REPLACED}${dst}"$'\n'
    else
      # Keep the path relative to $HOME, so ~/.ssh/config and ~/.config/config
      # cannot overwrite each other inside one backup dir.
      local rel="${dst#$HOME/}"
      case "$rel" in /*) rel="$(basename "$dst")" ;; esac
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$dst" "$BACKUP_DIR/$rel"
      warn "backed up $(_tilde "$dst") -> $(_tilde "$BACKUP_DIR")/$rel"
      REPLACED="${REPLACED}${BACKUP_DIR}/${rel}"$'\n'
    fi
  fi

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %swould%s link %s -> %s\n' "$C_YEL" "$C_RESET" "$(_tilde "$dst")" "$1"
  else
    ln -s "$src" "$dst"
    ok "$(_tilde "$dst") -> $1"
  fi
}

_tilde() { local t='~'; printf '%s\n' "${1/#$HOME/$t}"; }

# ensure_local <path> <heredoc-body>
# Creates a gitignored local-override file if absent. Never overwrites.
ensure_local() {
  local dst="$1"; shift
  if [ -e "$dst" ]; then
    skip "$(_tilde "$dst") (exists)"
  elif [ "$DRY_RUN" = "1" ]; then
    printf '  %swould%s create %s\n' "$C_YEL" "$C_RESET" "$(_tilde "$dst")"
  else
    mkdir -p "$(dirname "$dst")"
    printf '%s\n' "$*" > "$dst"
    chmod 600 "$dst"
    ok "created $(_tilde "$dst")"
  fi
}
