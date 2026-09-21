# Linux environment. Sourced from env.sh for login shells.

# --- Homebrew (optional on Linux) ---------------------------------------
for _brew in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    export HOMEBREW_PREFIX="$("$_brew" --prefix)"
    break
  fi
done
unset _brew

# --- Google Cloud SDK ---------------------------------------------------
# Shell-specific: path.bash.inc relies on $BASH_SOURCE, which zsh leaves empty.
_gc_sh=bash; [ -n "${ZSH_VERSION:-}" ] && _gc_sh=zsh
for _gc in \
  "$HOME/google-cloud-sdk" \
  /usr/share/google-cloud-sdk \
  /usr/lib/google-cloud-sdk \
  "${HOMEBREW_PREFIX:-/nonexistent}/share/google-cloud-sdk"
do
  [ -r "$_gc/path.$_gc_sh.inc" ] && { . "$_gc/path.$_gc_sh.inc"; break; }
done
unset _gc _gc_sh

# --- Linux desktop integration ------------------------------------------
export BROWSER="${BROWSER:-xdg-open}"
