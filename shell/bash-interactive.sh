# Interactive bash: shell options, completion, prompt.
# The bash counterpart of zsh-interactive.zsh. Runs in every interactive shell.

# --- Shell options ------------------------------------------------------
shopt -s checkwinsize          # keep $LINES/$COLUMNS right after a resize
shopt -s cdspell               # fix small typos in `cd` targets
shopt -s no_empty_cmd_completion

# histappend needs bash 3+; the rest need bash 4+ (Linux, or brew bash on Mac).
shopt -s histappend
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
  shopt -s globstar            # ** matches across directories
  shopt -s autocd              # `cd` is optional for a bare directory
  shopt -s dirspell
  shopt -s checkjobs
fi

# Write history after every command, so parallel tabs do not clobber one another.
case "$PROMPT_COMMAND" in
  *history\ -a*) ;;
  *) PROMPT_COMMAND="history -a;${PROMPT_COMMAND:-}" ;;
esac

# --- Completion ---------------------------------------------------------
# Loaded per-shell, so it belongs here rather than in env.sh.
if ! shopt -oq posix; then
  for _c in \
    /opt/homebrew/etc/profile.d/bash_completion.sh \
    /usr/local/etc/profile.d/bash_completion.sh \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
  do
    [ -r "$_c" ] && { . "$_c"; break; }
  done
  unset _c
fi

# --- Prompt -------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
else
  # Readable fallback: user@host, cwd, git branch.
  _git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ (/;s/$/)/'
  }
  PS1='\[\033[32m\]\u@\h\[\033[0m\] \[\033[34m\]\w\[\033[33m\]$(_git_branch)\[\033[0m\]\n$ '
fi

# --- Version managers ---------------------------------------------------
# fnm installs a directory-change hook, which is per-shell state.
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell bash)"
