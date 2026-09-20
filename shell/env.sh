# Exported environment and PATH. Sourced once per login shell; children inherit
# it. Safe to source twice -- the guard below makes the second time a no-op.

[ -n "${_DOTFILES_ENV_LOADED:-}" ] && return 0

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

case "$(uname -s)" in
  Darwin) _DOTFILES_OS=darwin ;;
  Linux)  _DOTFILES_OS=linux  ;;
  *)      _DOTFILES_OS=unknown ;;
esac
export _DOTFILES_OS

# Prepend to PATH only if the directory exists and is not already there.
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) return 0 ;; esac
  PATH="$1:$PATH"
}
path_append() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) return 0 ;; esac
  PATH="$PATH:$1"
}

# --- XDG ----------------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- Locale -------------------------------------------------------------
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"

# --- Editor and pager ---------------------------------------------------
if [ -z "${EDITOR:-}" ]; then
  for _e in nvim vim vi nano; do
    command -v "$_e" >/dev/null 2>&1 && { export EDITOR="$_e"; break; }
  done
  unset _e
fi
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--FRXi}"   # quit-if-one-screen, keep colors, smart-case

# --- History (exported so every shell agrees) ---------------------------
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE='ls:ll:cd:pwd:exit:clear:history'
export HISTTIMEFORMAT='%F %T  '

# --- Per-OS environment (Homebrew, system paths) ------------------------
[ -r "$DOTFILES/shell/os/${_DOTFILES_OS}-env.sh" ] \
  && . "$DOTFILES/shell/os/${_DOTFILES_OS}-env.sh"

# --- Language toolchains ------------------------------------------------
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
path_prepend "$BUN_INSTALL/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/go/bin"

# --- Our own scripts win over everything --------------------------------
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"

export PATH

# --- Secrets ------------------------------------------------------------
# API keys live in ~/.config/secrets.env (mode 600, never committed anywhere).
# See README for the expected shape.
[ -r "$HOME/.config/secrets.env" ] && . "$HOME/.config/secrets.env"

# --- Machine-specific environment, never committed ----------------------
[ -r "$HOME/.env.local" ] && . "$HOME/.env.local"

export _DOTFILES_ENV_LOADED=1
