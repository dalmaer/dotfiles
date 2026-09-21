# Interactive zsh: options, history, completion, keys, prompt.
# The zsh counterpart of bash-interactive.sh. Runs in every interactive shell.

# --- Options ------------------------------------------------------------
setopt AUTO_CD               # a bare directory name cds into it
setopt INTERACTIVE_COMMENTS  # allow # comments at the prompt, as bash does
setopt NO_BEEP
# An unmatched glob passes through literally, as in bash. zsh's default is to
# refuse the whole command, which breaks `curl http://host/?q=1` and friends.
setopt NO_NOMATCH

# --- History ------------------------------------------------------------
# macOS /etc/zshrc sets HISTSIZE=2000 SAVEHIST=1000 just before this runs, so
# these must be set here rather than relying on the exports in env.sh.
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # timestamps, like HISTTIMEFORMAT in bash
setopt SHARE_HISTORY          # every tab sees every other tab's commands
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE      # a leading space keeps a command out, as in bash
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # !! expands into the line rather than running

# --- Completion ---------------------------------------------------------
typeset -U path fpath          # no duplicate entries
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit
compinit -i   # -i: skip insecure directories quietly instead of prompting
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu select

# --- Keys ---------------------------------------------------------------
# zsh switches to vi keys when $EDITOR or $VISUAL mentions "vi", and env.sh
# sets EDITOR=vim. Without this line Ctrl-A, Ctrl-E and Ctrl-R stop working.
bindkey -e

# Up and Down search history for what is already typed.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search

# --- Prompt -------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  autoload -Uz vcs_info
  zstyle ':vcs_info:git:*' formats ' (%b)'
  precmd_functions+=(vcs_info)
  setopt PROMPT_SUBST
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f
$ '
fi

# --- Version managers ---------------------------------------------------
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell zsh)"
