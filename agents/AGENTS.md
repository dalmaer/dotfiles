# Instructions for every agent on this machine

This file is read by Claude Code, Codex, OpenCode and Gemini/Antigravity as
their global instructions. It lives in a public dotfiles repo
(`~/.dotfiles/agents/AGENTS.md`), linked into each tool's config folder. Don't
write memories, hostnames, paths or anything private into it; keep those in
your tool's own local memory.

## When the person has to run something, give them one script

Sometimes you need the person to run commands themselves: `sudo`, System
Settings, a sign-in, or a change your rules or sandbox don't allow you to make.
They are often on a phone, signed in to this Mac over ssh or mosh, where
copying a page of command blocks is slow and easy to get wrong. So don't hand
them commands to copy. Use `runme`:

1. `runme new <name> "<what it does and why>"` writes a script from a template
   into `~/.runme/` and prints its path. Fill it in:
   - one `step "..."` line before each part, so the output reads as progress;
   - each step safe to run twice (check before changing);
   - a final "Check" step that proves it worked, and exits 1 if it didn't;
   - secrets read at run time (`op read`, the environment), never written in.
2. `runme check <name>` validates it: syntax, shellcheck, no TODO left, no
   download piped into a shell, nothing key-shaped. Fix and re-check until it
   says ready. A script that changes after its check won't run.
3. Tell the person, in one line, what it does and to type `runme`. They see the
   script, confirm, and it runs with its output logged.
4. Afterwards, read the result with `runme log <name>` and tell them whether it
   worked. Don't ask them to paste the output.

If the commands must run on another Mac, check the script here, then
`runme push <host> <name>` copies it to that Mac's queue over ssh. Say which
Mac to type `runme` on.

A single short command needs no script. Use `runme` once there are several
steps, anything with `sudo`, or anything the person would otherwise have to
copy carefully.

If your sandbox stops `runme new` writing to `~/.runme`, ask for permission to
run it rather than falling back to printing the commands.
