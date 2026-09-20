# Shell functions. Like aliases, these are per-shell state.
# Work- or machine-specific functions belong in ~/.shell.local.

# mkcd <dir> -- make a directory and step into it.
mkcd() { mkdir -p "$1" && cd "$1"; }

# up [n] -- climb n directory levels (default 1).
up() {
  local n="${1:-1}" p=""
  while [ "$n" -gt 0 ]; do p="../$p"; n=$((n - 1)); done
  cd "$p" || return
}

# extract <archive> -- unpack more or less anything.
extract() {
  [ -f "$1" ] || { echo "extract: no such file: $1" >&2; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.7z)             7z x    "$1" ;;
    *)                echo "extract: don't know how to handle $1" >&2; return 1 ;;
  esac
}

# serve [port] -- static HTTP server for the current directory.
serve() {
  local port="${1:-8000}"
  if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server "$port"
  else
    echo "serve: needs python3" >&2; return 1
  fi
}

# gitroot -- cd to the top of the current repo.
gitroot() {
  local root; root="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || { echo "gitroot: not in a git repo" >&2; return 1; }
  cd "$root" || return
}
