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

## Coordinate project agents without duplicate work

For machine-wide routing, check the private locator at
`~/.config/home/project.json` when present, then read the project guide it
names. The locator is local inventory, not permission or proof of availability.
Keep machine names, private paths and session records out of these public dotfiles.

Resolve the exact project, machine, provider and existing task before starting.
Plates records durable goals, phase claims and evidence; GitHub records commits,
reviews and CI; Rex reports terminal sessions and presence. None substitutes for
the others. An unread or unreachable source is unknown, never free or idle.

Each active worker needs a stable unique `PLATES_SESSION` and explicit provider.
Use the private project's identity wrapper where available, or set the variables
on every command. Do not reuse a parent's identity for parallel children or create
a fresh identity for each command. Separate concurrent writers into worktrees,
claim before building, and stop when another worker owns the claim.

A handoff retains the exact task, scope, approvals, branch, commit, checks,
uncertain effects and next action. Verify the old writer stopped before the new
one starts. Claim tokens and attach receipts are checkout-local; a token alone
cannot transfer ownership across machines. Never steal a live claim or treat a
lost dispatch reply as permission to launch a duplicate. Respect the project's
review, integration and installation checks, and keep unverified routes disabled.

## Name each project's home session the same way

Every project in the fleet has one long-lived Claude desktop session that the
person steers from their phone. Title it `🏠 [project] Home Remote Control`,
with the project's name in lowercase inside the brackets, e.g.
`🏠 [plates] Home Remote Control`. Other home sessions follow the same form
(`🏠 [ledger] Home Capture`). When you create one, use that title and turn
Remote Control on for it.
