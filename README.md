# dotfiles

Shell (bash and zsh), git, ssh and `~/bin` config for macOS and Linux. One
repo, one `install.sh`, one `dot` command to keep machines in step.

Nothing private lives here. Work hostnames, API keys and per-machine paths go
in local override files that are never committed — see
[Local override files](#local-override-files).

## Bootstrap a new machine

```bash
git clone https://github.com/dalmaer/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --dry-run     # see exactly what it would do
./install.sh               # do it
exec $SHELL -l             # reload
dot validate               # confirm
```

The repo must live at `~/.dotfiles`: the shell rc files look for it there.
Cloned anywhere else, every link would install correctly and then nothing
would load, so `install.sh` refuses.

`install.sh` is idempotent and never deletes. Any real file already sitting at
a target path is moved to `backup/<timestamp>/` inside the repo before the
symlink goes in, keeping its path relative to `$HOME` — so `~/.ssh/config`
lands at `backup/<timestamp>/.ssh/config` and cannot collide with another file
of the same name. `dot backups` lists them.

`backup/` is gitignored. It has to be: a backed-up shell config can contain
internal hostnames or exported keys, and this repo is public. `dot validate`
fails if anything under `backup/` is ever tracked.

## Layout

```
install.sh            first-run setup; --dry-run to preview
dotfiles.conf         manifest: repo path -> target path
lib/common.sh         shared helpers (os detection, linking, dry-run)
bin/                  everything here is linked into ~/bin
  dot                 the CLI
  mkscript            scaffold a new ~/bin script
  ports               what is listening, on either OS
shell/
  env.sh              exported env + PATH  (login; shared by both shells)
  aliases.sh          aliases              (shared)
  functions.sh        functions            (shared)
  bash_profile        -> ~/.bash_profile   bash login shells
  bashrc              -> ~/.bashrc         bash interactive shells
  bash-interactive.sh shopt, completion, prompt for bash
  zprofile            -> ~/.zprofile       zsh login shells
  zshrc               -> ~/.zshrc          zsh interactive shells
  zsh-interactive.zsh setopt, completion, keys, prompt for zsh
  os/
    darwin-env.sh     darwin-interactive.sh
    linux-env.sh      linux-interactive.sh
git/                  gitconfig, gitignore_global
ssh/                  config (includes config.local first)
config/               starship.toml
```

## How the shell files fit together

Both bash and zsh are supported, and both files sets are linked on every
machine, so whichever shell you start gets the same environment. `env.sh`,
`aliases.sh`, `functions.sh` and the `os/` files are shared and must run in
both; each shell has its own entry points and its own `*-interactive` file.

### bash

Bash reads `~/.bash_profile` for **login** shells and `~/.bashrc` for
**interactive non-login** shells, and it does *not* read `.bashrc` for login
shells. macOS terminals open login shells; Linux terminals usually open
non-login ones. That difference is the whole reason for the split.

```
login shell                      non-login interactive shell
  .bash_profile                    .bashrc
    └ env.sh                         ├ env.sh (via guard, if not already run)
    └ .bashrc                        ├ bash-interactive.sh
        ├ bash-interactive.sh        ├ aliases.sh
        ├ aliases.sh                 ├ functions.sh
        ├ functions.sh               ├ os/<os>-interactive.sh
        ├ os/<os>-interactive.sh     └ ~/.shell.local
        └ ~/.shell.local
```

Both paths converge, so a login shell and a plain `bash` behave identically.

### zsh

zsh reads `~/.zprofile` for login shells and then `~/.zshrc` for every
interactive shell, login or not, so no hand-off is needed.

```
login shell                      non-login interactive shell
  .zprofile                        .zshrc
    └ env.sh                         ├ env.sh (via guard, if not already run)
  .zshrc                             ├ zsh-interactive.zsh
    ├ zsh-interactive.zsh            ├ aliases.sh
    ├ aliases.sh                     ├ functions.sh
    ├ functions.sh                   ├ os/<os>-interactive.sh
    ├ os/<os>-interactive.sh         └ ~/.shell.local
    └ ~/.shell.local
```

`env.sh` is loaded from `.zprofile`, not `.zshenv`, on purpose. On macOS,
`/etc/zprofile` runs `path_helper` *after* `.zshenv` and rebuilds `PATH` with
the system directories first, so anything prepended in `.zshenv` ends up
behind `/usr/bin`. `dot validate` warns if `~/.zshenv` sets `PATH`.

The dividing line for **where to put something** is inheritance:

| Kind of thing | Inherited by children? | Goes in |
|---|---|---|
| `PATH`, exported vars | yes | `shell/env.sh` |
| Aliases, functions | no | `shell/aliases.sh`, `functions.sh` (shared) |
| Prompt, completion, shell options | no | `shell/bash-interactive.sh` or `zsh-interactive.zsh` |

`env.sh` sets `_DOTFILES_ENV_LOADED` so it is a no-op the second time, which
is what lets both entry points source it safely.

## Local override files

These five files are **never committed** and never synced. `install.sh`
creates the first four as documented stubs; you fill them in per machine.

| File | Loaded by | Wins because | Put here |
|---|---|---|---|
| `~/.shell.local` | `.bashrc` / `.zshrc`, last | sourced last | Work aliases and functions, internal hostnames, per-machine experiments. Read by both shells, so keep it portable or branch on `$ZSH_VERSION` |
| `~/.env.local` | `env.sh`, before `export PATH` | later assignment | Exported vars and `PATH` entries specific to this machine |
| `~/.gitconfig.local` | `[include]` at end of `.gitconfig` | git takes the **last** value | A different `user.email`, `insteadOf` URL rewrites, proxies |
| `~/.ssh/config.local` | `Include` at top of `.ssh/config` | ssh takes the **first** value | Internal hosts, jump boxes, `ForwardAgent` |
| `~/.config/secrets.env` | `env.sh` | — | API keys, mode `600`. Copy by hand; never sync it |

Two helpers are in scope inside `~/.env.local`: `path_prepend` and
`path_append`. Both skip directories that do not exist, so you can list paths
unconditionally.

`~/.config/secrets.env` must contain only comments and `KEY=value` /
`export KEY=value` lines. Any other line is executed as a command when the
file is sourced. `dot validate` checks for this.

## Opting out on one machine

`~/.dotfiles.skip` lists repo-relative paths this machine must not link, one
per line:

```
ssh/config
```

This exists for files that **another tool on the box writes to**. Corp tooling
that appends to `~/.ssh/config`, for instance, would be writing into the repo
once that path is a symlink — and `dot sync` commits with `git add -A` and
pushes to a public remote. Skipping the entry leaves the real file alone.

`install.sh` and `dot link` honour the list, and `dot validate` prints what is
being skipped so it never becomes invisible.

As a backstop, `dot sync` scans staged changes for credential-shaped strings
and refuses to commit if it finds one.

## The `dot` command

| Command | What it does |
|---|---|
| `dot validate` | Read-only health check. Changes nothing. Exit 0 clean, 1 warnings, 2 errors |
| `dot sync` | Pull, commit local changes, push, relink |
| `dot status` | Repo status |
| `dot link [--dry-run]` | Recreate symlinks |
| `dot pull` / `dot push` | Halves of sync |
| `dot edit` | Open the repo in `$EDITOR` |
| `dot backups` | List `install.sh` backups and what is in them |
| `dot cd` | Print the repo path (`cd "$(dot cd)"`) |

Typical loop: change something, `dot sync` here, `dot sync` on the other box.

`dot validate` is safe to run anywhere at any time — it only reads. It is the
right first move on a machine you have not touched in a while.

## Adding things

**A new dotfile.** Put it in the repo under the relevant directory, add a line
to `dotfiles.conf`, run `dot link --dry-run`, then `dot link`.

**A new `~/bin` script.** `mkscript myscript "what it does"` creates it in
`bin/`, links it into `~/bin`, and opens it. Or drop a file in `bin/` and run
`dot link` — everything in `bin/` is linked automatically, no manifest entry
needed.

**Something OS-specific.** Add it to `shell/os/darwin-*.sh` or
`shell/os/linux-*.sh`, choosing `-env` or `-interactive` by the inheritance
rule above.

## Never committed

`.gitignore` covers `*.local`, `secrets.env` and `.npmrc`. `dot validate`
independently checks that none of them are tracked and greps the repo for
key-shaped strings, so a mistake shows up rather than sitting there quietly.

`~/.npmrc` is excluded deliberately: it holds registry auth tokens. Copy it
between machines by hand, as with `secrets.env`.
