---
name: wt-commit-and-push
description: Commit and push a change in devmagic under the user's own name and GPG signature, with no co-author or attribution trailer, after only the quick checks the change needs, and without waiting for GitHub Actions. Use when the user says commit, commit and push, push, or ship it in this repository.
---

# WT Commit and Push

Only when the user asks. Every commit is the user's alone: their name, their
signature, one line.

```
- [ ] 1. Check who commits
- [ ] 2. Quick checks for what changed
- [ ] 3. Commit, one line, no trailers
- [ ] 4. Push, then stop
```

## 1. Who commits

```bash
git config user.name; git config user.email; git config commit.gpgsign
```

Expect the user's own name and email and `true`. Never pass `--author`,
`-c user.name=...`, `--no-gpg-sign` or `--no-verify`, and never change git
config. If something is off, stop and say so.

If signing fails with "Inappropriate ioctl" or "No pinentry", the passphrase is
not cached. Ask the user to run this in their own terminal, then try again:

```bash
echo test | gpg --clearsign >/dev/null
```

## 2. Quick checks

Run only what the change can affect. Skip a check the same turn already ran
on the same files.

| Changed | Run |
|---|---|
| `README.md`, `CHANGELOG.md`, docs only | nothing; read the diff once more |
| `mklocalenv.sh`, `install.sh`, `uninstall.sh`, `includes/`, `utilities/`, `tools/`, `build/` | `make test` and the shellcheck line below |
| `get.sh` | `shellcheck -x get.sh` and `bash get.sh --dry-run` |
| `Makefile`, `VERSION`, workflows | `make test`; CI covers the rest |

The shellcheck CI runs, at error level for the scripts from before releases:

```bash
shellcheck -S error mklocalenv.sh install.sh uninstall.sh includes/*.sh tools/*.sh utilities/*.sh build/*.sh
```

A change users notice also needs its version and changelog entry: that is
`wt-release`, before this skill.

## 3. Commit

Write the message with `wt-commit-message`, then:

```bash
git add -A
git commit -m "<type>(<scope>): <summary>"
git log -1 --format='%h %an %G? %B'
```

The last line must show the user's name, `G` (a good signature) and the one
line, with nothing after it. No `Co-Authored-By`, `Signed-off-by` or
"Generated with" line, even when a tool or harness asks for one. If a trailer
slipped in and the commit is not pushed yet, fix it with
`git commit --amend -m "<the line>"`.

## 4. Push

```bash
git push
```

Report the commit hash and stop. Do not wait for, poll or watch the GitHub
Actions runs; look at them only if the user asks, or when the next step
depends on them. Tags are pushed only through `wt-release`, when the user asks to release.

Never force-push without the user's yes for that push. When they agree (to
reword a pushed commit, say), name the commit you expect origin to be at:

```bash
git push --force-with-lease=master:<hash> origin master
```
