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

## Conventions

**Target bash 3.2.** Stock macOS ships bash 3.2.57. No associative arrays, no
`mapfile`, no `${var^^}`, no `&>>`. Guard bash 4+ features behind
`[ "${BASH_VERSINFO[0]}" -ge 4 ]`, as `shell/interactive.sh` does.

**Both platforms, every time.** `uname -s` gives `darwin` or `linux`; the
result is in `$OS` after sourcing `lib/common.sh` and `$_DOTFILES_OS` in shell
config. Never hardcode a path that exists on only one platform — Homebrew is
`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel, and
`/home/linuxbrew/.linuxbrew` on Linux. Detect, do not assume.

**Login vs interactive is the organising principle.** Anything inherited by
child processes (`PATH`, exported vars) goes in `shell/env.sh`. Anything that
is per-shell state (aliases, functions, prompt, completion, `shopt`) goes in
`shell/interactive.sh`, `aliases.sh` or `functions.sh`. Putting an alias in
`env.sh` silently does nothing useful; putting a slow lookup in
`interactive.sh` costs time on every new tab.

**Keep `shell/env.sh` quiet and fast.** It runs on every login. No output to
stdout — it corrupts `scp` and `rsync`. Nothing slow without a guard.

**Guard every source.** `[ -r "$f" ] && . "$f"`. A missing optional file must
never break shell startup.

**Comments explain why, not what.** The existing files are the reference for
tone and density; match them.

## Testing a change

```bash
bash -n <file>              # syntax check every shell file you touch
./install.sh --dry-run      # confirm the plan
dot validate                # read-only, exits 2 on error
bash -lc 'echo ok'          # login shell still works
bash -c  'echo ok'          # non-interactive still silent
```

The last two matter: a stray `echo` or a syntax error in a sourced file will
pass `bash -n` and still break real sessions.

## Adding a file

Put it in the relevant directory, add `<repo-path> <target>` to
`dotfiles.conf`, then `dot link --dry-run`. Files in `bin/` are linked
automatically and need no manifest entry.
