# Dion's MacBook Pro M1. Sourced from env.sh when the lowercased short
# hostname matches this file's name. Same rules as env.sh: PATH and exports
# only, no output.

# Homebrew's 3.12 libexec holds only the unversioned python and pip, so those
# are 3.12 while python3 and pip3 come from the python.org 3.11 framework. The
# tools pip3 installed live there too. (Interactively, aliases.sh points
# python at python3.)
path_prepend "/Library/Frameworks/Python.framework/Versions/3.11/bin"
path_prepend "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/python@3.12/libexec/bin"
