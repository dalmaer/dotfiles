# Linux interactive shell: aliases, clipboard shims, completion.

alias o='xdg-open'
alias oo='xdg-open .'
alias open='xdg-open'

# Give Linux the macOS clipboard verbs so muscle memory and scripts port over.
if command -v wl-copy >/dev/null 2>&1; then          # Wayland
  alias pbcopy='wl-copy'
  alias pbpaste='wl-paste'
elif command -v xclip >/dev/null 2>&1; then          # X11
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
elif command -v xsel >/dev/null 2>&1; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

command -v systemctl >/dev/null 2>&1 && alias sc='systemctl' && alias scu='systemctl --user'

for _gc in \
  "$HOME/google-cloud-sdk/completion.bash.inc" \
  /usr/share/google-cloud-sdk/completion.bash.inc \
  /usr/lib/google-cloud-sdk/completion.bash.inc
do
  [ -r "$_gc" ] && { . "$_gc"; break; }
done
unset _gc
