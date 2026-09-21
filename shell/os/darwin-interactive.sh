# macOS interactive shell: aliases and completion.

alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO  && killall Finder'
alias o='open'
alias oo='open .'

# Strip the quarantine bit from a downloaded file.
unquarantine() { xattr -d com.apple.quarantine "$@" 2>/dev/null || true; }

# gcloud completion is per-shell state, so it lives here, not in *-env.sh.
# The zsh variant needs compinit, which zsh-interactive.zsh has already run.
_gc_sh=bash; [ -n "${ZSH_VERSION:-}" ] && _gc_sh=zsh
_gc="${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.$_gc_sh.inc"
[ -r "$_gc" ] && . "$_gc"
unset _gc _gc_sh
