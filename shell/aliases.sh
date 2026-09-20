# Aliases. Not inherited by child processes, so this is sourced per shell.
# Work- or machine-specific aliases belong in ~/.shell.local instead.

# --- Listing ------------------------------------------------------------
if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'          # GNU coreutils (Linux, brew coreutils)
else
  alias ls='ls -G'                    # BSD ls (stock macOS)
fi
alias ll='ls -lh'
alias la='ls -lAh'
alias l='ls -CF'

# --- Safety -------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# --- Navigation ---------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# --- Grep ---------------------------------------------------------------
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# --- Git ----------------------------------------------------------------
# Kept thin on purpose: the real aliases live in ~/.gitconfig, where they also
# work from editors, scripts, and other shells.
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git lg'

# --- Misc ---------------------------------------------------------------
alias path='printf "%s\n" $PATH | tr ":" "\n"'
alias reload='exec "$SHELL" -l'
alias now='date "+%Y-%m-%d %H:%M:%S"'
