# AGENTS.md

Notes for AI agents working in this repo. Humans: `README.md` is the one you
want.

## What this repo is

Dotfiles for macOS and Linux, symlinked into `$HOME` by `install.sh`. The
files here are **live config on the user's machine** — a bad edit breaks their
shell on next login, on every machine they sync to. Treat changes accordingly.

## Hard rules

1. **Never commit a secret.** Not an API key, not a token, not a private
   hostname. `~/.config/secrets.env` and `~/.npmrc` are off limits: both hold
   live credentials. `.gitignore` covers `*.local`, `secrets.env` and
   `.npmrc`, and `dot validate` greps tracked files for key-shaped strings.
   If you need a value at runtime, read it from the environment.

2. **Nothing internal goes in this repo.** It is public. Work hostnames, corp
   paths, internal registries and anything resembling them belong in the local
   override files (`~/.shell.local`, `~/.env.local`, `~/.gitconfig.local`,
   `~/.ssh/config.local`), which are never committed.

3. **Never delete a user file.** `install.sh` moves anything in the way to
   `backup/<timestamp>/` inside the repo, keeping the path relative to `$HOME`
   so two files with the same basename cannot collide. Any new code that
   replaces a file must do the same. `backup/` is gitignored and must stay
   that way: a backed-up shell config can carry internal hostnames or exported
   keys, and this repo is public. `dot validate` is strictly read-only.

4. **Preview before applying.** `./install.sh --dry-run` and
   `dot link --dry-run` must show every change and make none. If you add a
   mutating step, route it through `run()` in `lib/common.sh` or dry-run will
   silently lie.

5. **Respect `~/.dotfiles.skip`.** It lists repo-relative paths a given
   machine must not link, for files some other tool writes to. Any new code
   that links or inspects manifest entries must call `should_skip` first, or
   it will fight that tool and push its writes to a public remote.

## Conventions

**Shared shell files must run in bash 3.2 *and* zsh 5.** `env.sh`,
`aliases.sh`, `functions.sh` and everything in `shell/os/` are sourced by both
shells. Stock macOS ships bash 3.2.57: no associative arrays, no `mapfile`, no
`${var^^}`, no `&>>`. And zsh differs in ways that parse cleanly and then
misbehave:

- Unmatched globs are an error in zsh by default (`zsh-interactive.zsh` turns
  that off interactively, but shared files are also sourced before it runs).
  Avoid bare globs in shared files.
- Anything that locates itself with `$BASH_SOURCE` breaks under zsh, where it
  is empty. gcloud's `path.bash.inc` is the example in this repo: branch on
  `$ZSH_VERSION` and source the shell's own variant.
- `zsh -n` passing proves nothing about behaviour. Test in a real shell.

Bash-only features go in `bash-interactive.sh`, guarded behind
`[ "${BASH_VERSINFO[0]}" -ge 4 ]` where they need bash 4+. zsh-only features
go in `zsh-interactive.zsh`. `bin/` scripts use `#!/usr/bin/env bash` and must
still run on bash 3.2.

**PATH belongs in `.zprofile`, never `.zshenv`.** On macOS `/etc/zprofile`
runs `path_helper` after `.zshenv` and puts system directories first.

**The repo lives at `~/.dotfiles`.** The rc files find it there. `install.sh`
refuses to run from anywhere else, because the failure is otherwise silent.

**Both platforms, every time.** `uname -s` gives `darwin` or `linux`; the
result is in `$OS` after sourcing `lib/common.sh` and `$_DOTFILES_OS` in shell
config. Never hardcode a path that exists on only one platform — Homebrew is
`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel, and
`/home/linuxbrew/.linuxbrew` on Linux. Detect, do not assume.

**Login vs interactive is the organising principle.** Anything inherited by
child processes (`PATH`, exported vars) goes in `shell/env.sh`. Anything that
is per-shell state (aliases, functions, prompt, completion, `shopt`) goes in
`aliases.sh` or `functions.sh` (shared), or `bash-interactive.sh` /
`zsh-interactive.zsh` (shell-specific). Putting an alias in `env.sh` silently
does nothing useful; putting a slow lookup in an interactive file costs time
on every new tab.

**Keep `shell/env.sh` quiet and fast.** It runs on every login. No output to
stdout — it corrupts `scp` and `rsync`. Nothing slow without a guard.

**Guard every source.** `[ -r "$f" ] && . "$f"`. A missing optional file must
never break shell startup.

**Comments explain why, not what.** The existing files are the reference for
tone and density; match them.

## Testing a change

```bash
bash -n <file>; zsh -n <file>   # syntax, in both shells for shared files
./install.sh --dry-run          # confirm the plan
dot validate                    # read-only, exits 2 on error
bash -lic 'type ll'             # bash login shell loads everything
zsh  -lic 'type ll'             # zsh login shell loads everything
bash -c 'echo ok'; zsh -c 'echo ok'   # scripts stay silent
```

Syntax checks are not enough: a sourced file can parse and still load nothing
or print to stdout. To test without touching the real `$HOME`, install into a
scratch directory with a `.dotfiles` symlink back to the repo, then start a
shell with `env -i HOME=<scratch> ... zsh -l -i -c '...'`. `zsh -o
sourcetrace` prints every file zsh reads, which is the fastest way to find out
why something did not load.

## Adding a file

Put it in the relevant directory, add `<repo-path> <target>` to
`dotfiles.conf`, then `dot link --dry-run`. Files in `bin/` are linked
automatically and need no manifest entry.
