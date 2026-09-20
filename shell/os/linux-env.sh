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
for _gc in \
  "$HOME/google-cloud-sdk/path.bash.inc" \
  /usr/share/google-cloud-sdk/path.bash.inc \
  /usr/lib/google-cloud-sdk/path.bash.inc \
  "${HOMEBREW_PREFIX:-/nonexistent}/share/google-cloud-sdk/path.bash.inc"
do
  [ -r "$_gc" ] && { . "$_gc"; break; }
done
unset _gc

# --- Linux desktop integration ------------------------------------------
export BROWSER="${BROWSER:-xdg-open}"
