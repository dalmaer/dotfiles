#!/usr/bin/env bash
# install.sh -- first-run setup on a new machine.
#
#   ./install.sh              link everything, create local-override stubs
#   ./install.sh --dry-run    show exactly what would happen, change nothing
#   ./install.sh --no-stubs   link only; do not create ~/.*.local files
#
# Idempotent: safe to run repeatedly. Never deletes anything -- any real file
# already sitting at a target path is moved to backup/<timestamp>/ inside the
# repo, keeping its path relative to $HOME. Backups are gitignored.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES
. "$DOTFILES/lib/common.sh"

DRY_RUN=0
STUBS=1
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --no-stubs)   STUBS=0 ;;
    -h|--help)    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            die "unknown option: $arg (try --help)" ;;
  esac
done
export DRY_RUN

echo
printf '%s\n' "${C_BLU}dotfiles${C_RESET}  $(_tilde "$DOTFILES")  [$OS/$ARCH]"
[ "$DRY_RUN" = "1" ] && printf '%s\n' "${C_YEL}dry run -- nothing will be created, moved, or removed${C_RESET}"
echo

# ---------------------------------------------------------- prerequisites --
step "Checking prerequisites"
have git || die "git is required but not installed"
ok "git $(git --version | awk '{print $3}')"
have gh && ok "gh $(gh --version | head -1 | awk '{print $3}')" \
         || warn "gh not installed -- needed for the git credential helper"
if [ "$OS" = "unknown" ]; then
  warn "unrecognised platform $(uname -s) -- OS-specific config will be skipped"
fi

# ------------------------------------------------------------ directories --
step "Creating directories"
for d in "$HOME/bin" "$HOME/.local/bin" "$HOME/.config" "$HOME/.ssh/sockets"; do
  if [ -d "$d" ]; then
    skip "$(_tilde "$d")"
  elif [ "$DRY_RUN" = "1" ]; then
    printf '  %swould%s create %s\n' "$C_YEL" "$C_RESET" "$(_tilde "$d")"
  else
    mkdir -p "$d"; ok "$(_tilde "$d")"
  fi
done
[ -d "$HOME/.ssh" ] && run chmod 700 "$HOME/.ssh"

# ----------------------------------------------------------------- links --
# Bash reads only the FIRST of ~/.bash_profile, ~/.bash_login, ~/.profile.
# If .bash_profile does not exist yet, linking it silently stops login shells
# reading the other two -- the only change here that is not a file move.
if [ ! -e "$HOME/.bash_profile" ] && [ ! -L "$HOME/.bash_profile" ]; then
  for f in .bash_login .profile; do
    if [ -f "$HOME/$f" ]; then
      step "Heads up: ~/$f"
      warn "bash login shells read ~/$f today. Once ~/.bash_profile exists they"
      info "       stop reading it. It is left in place (sh and some desktops still"
      info "       read it), but anything bash needs from it belongs in ~/.env.local."
      REVIEW_EXTRA="${REVIEW_EXTRA:-}$HOME/$f"$'\n'
    fi
  done
fi

step "Linking config into \$HOME"
while read -r src dst; do
  case "$src" in ''|\#*) continue ;; esac
  if should_skip "$src"; then skip "$src (listed in ~/.dotfiles.skip)"; continue; fi
  link "$src" "${dst/#\~/$HOME}"
done < "$DOTFILES/dotfiles.conf"

step "Linking scripts into ~/bin"
for f in "$DOTFILES"/bin/*; do
  [ -f "$f" ] || continue
  if should_skip "bin/$(basename "$f")"; then skip "bin/$(basename "$f") (listed in ~/.dotfiles.skip)"; continue; fi
  [ "$DRY_RUN" = "1" ] || chmod +x "$f"
  link "bin/$(basename "$f")" "$HOME/bin/$(basename "$f")"
done

# --------------------------------------------------- local override stubs --
# These are the files that never get committed. Each is created once, with a
# header explaining what belongs in it, and is never touched again.
if [ "$STUBS" = "1" ]; then
step "Creating local-override stubs (never committed)"

ensure_local "$HOME/.shell.local" \
'# ~/.shell.local -- INTERACTIVE, this machine only. Never committed.
#
# Sourced at the end of ~/.bashrc, so it wins over everything in the repo.
# This is the right home for anything that should not be public:
#   - work aliases and functions
#   - internal hostnames
#   - per-machine experiments you are not ready to commit
#
# Aliases and functions are not inherited by child processes, which is why
# they belong here rather than in ~/.env.local.
#
# Example:
#   alias deploy-staging='\''ssh deploy@staging.internal'\''
#   work-tunnel() { ssh -L 8080:localhost:8080 jumpbox.internal -q; }
'

ensure_local "$HOME/.env.local" \
'# ~/.env.local -- LOGIN environment, this machine only. Never committed.
#
# Sourced near the end of shell/env.sh, before PATH is exported. Use it for
# exported variables and PATH entries that exist only on this machine.
# Everything here IS inherited by child processes.
#
# path_prepend and path_append are available and skip directories that do not
# exist, so it is safe to list paths unconditionally.
#
# Example:
#   path_prepend "$HOME/.toolbox/bin"
#   export COMPANY_REGISTRY=https://registry.internal
'

ensure_local "$HOME/.gitconfig.local" \
'# ~/.gitconfig.local -- git overrides, this machine only. Never committed.
#
# Included at the END of ~/.gitconfig, and git takes the last value it sees,
# so anything here overrides the managed config.
#
# Example:
#   [user]
#   	email = you@work.example.com
#   [url "ssh://git@internal.example.com/"]
#   	insteadOf = https://internal.example.com/
'

ensure_local "$HOME/.ssh/config.local" \
'# ~/.ssh/config.local -- ssh hosts, this machine only. Never committed.
#
# Included at the TOP of ~/.ssh/config. ssh uses the first value it finds for
# any keyword, so entries here override the managed defaults.
# Internal hostnames belong here, not in the public repo.
#
# Example:
#   Host jump
#   	HostName jumpbox.internal.example.com
#   	User myuser
#   	ForwardAgent yes
'
fi

# ---------------------------------------------------------------- secrets --
step "Secrets"
SF="$HOME/.config/secrets.env"
if [ -e "$SF" ]; then
  MODE="$(stat -f '%Lp' "$SF" 2>/dev/null || stat -c '%a' "$SF" 2>/dev/null)"
  if [ "$MODE" = "600" ]; then ok "$(_tilde "$SF") (mode 600)"
  else warn "$(_tilde "$SF") is mode $MODE -- run: chmod 600 $(_tilde "$SF")"; fi
else
  info "No $(_tilde "$SF") on this machine."
  info "API keys go there, one 'export KEY=value' per line, mode 600."
  info "It is never committed and never synced -- copy it across by hand."
fi

# ---------------------------------------------------------------- review --
# Replaced files are kept, not deleted -- but anything in them that is not in
# the repo stops taking effect. Point at exactly what to read.
review_cmd() {
  local f="$1" base; base="$(basename "$f")"
  if [ -f "/etc/skel/$base" ]; then
    printf '    diff /etc/skel/%s %s    # your additions over the distro default\n' "$base" "$(_tilde "$f")"
  else
    printf '    cat %s\n' "$(_tilde "$f")"
  fi
}
ALL_REVIEW="${REPLACED}${REVIEW_EXTRA:-}"
if [ -n "$ALL_REVIEW" ]; then
  echo
  if [ "$DRY_RUN" = "1" ]; then
    step "Review before applying"
    info "These stop taking effect. Move anything you still need into a .local file"
    info "(see README, \"Local override files\"):"
  else
    step "Review what was replaced"
    info "Backed up, not deleted -- but no longer read. Move anything you still"
    info "need into a .local file (see README, \"Local override files\"):"
  fi
  printf '%s' "$ALL_REVIEW" | while IFS= read -r f; do
    [ -n "$f" ] && review_cmd "$f"
  done
fi

echo
if [ "$DRY_RUN" = "1" ]; then
  printf '%s\n' "${C_YEL}Dry run complete -- nothing was changed.${C_RESET}"
  printf '%s\n' "Run ${C_BLU}./install.sh${C_RESET} to apply."
else
  printf '%s\n' "${C_GRN}Done.${C_RESET}"
  [ -d "$BACKUP_DIR" ] && printf '%s\n' "  Replaced files were backed up to $(_tilde "$BACKUP_DIR")/"
  echo
  printf '%s\n' "Next:"
  printf '%s\n' "  1. exec \$SHELL -l          reload the shell"
  printf '%s\n' "  2. dot validate            check everything landed"
  printf '%s\n' "  3. edit ~/.shell.local     add this machine's private bits"
fi
echo
