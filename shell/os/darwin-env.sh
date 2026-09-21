# macOS environment. Sourced from env.sh for login shells.

# --- Homebrew -----------------------------------------------------------
# Apple Silicon installs to /opt/homebrew, Intel to /usr/local.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    export HOMEBREW_PREFIX="$("$_brew" --prefix)"
    break
  fi
done
unset _brew

# Prefer GNU coreutils if installed, so scripts behave like they do on Linux.
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  path_prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
  path_prepend "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin"
fi

# --- Google Cloud SDK ---------------------------------------------------
# Shell-specific: path.bash.inc finds itself via $BASH_SOURCE, which is empty
# in zsh, so sourcing it from zsh silently puts the wrong directory on PATH.
_gc_sh=bash; [ -n "${ZSH_VERSION:-}" ] && _gc_sh=zsh
_gc="${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/path.$_gc_sh.inc"
[ -r "$_gc" ] && . "$_gc"
unset _gc _gc_sh

# --- macOS oddities -----------------------------------------------------
export BASH_SILENCE_DEPRECATION_WARNING=1   # /bin/bash is 3.2 and macOS nags
export COPYFILE_DISABLE=1                   # keep ._ files out of tarballs

# --- Vercel AI Gateway --------------------------------------------------
# Reads the token from the login keychain rather than storing it on disk.
# Only export it if the lookup actually succeeded -- an empty value here would
# override subscription auth with a broken credential.
if [ -x /usr/bin/security ]; then
  _vercel_tok="$(/usr/bin/security find-generic-password \
    -s 'Vercel AI Gateway' -a 'vercel-ai-gateway' -w 2>/dev/null)" || true
  [ -n "$_vercel_tok" ] && export ANTHROPIC_AUTH_TOKEN="$_vercel_tok"
  unset _vercel_tok
fi
