---
name: wt-commit-message
description: Write commit messages for devmagic in the repository's exact format, a lowercase conventional prefix with a scope and an imperative summary, subject line only. Use when committing changes, when the user asks for a commit message, or when finishing a change in this repository.
---

# WT Commit Message

## Format

```
<type>(<scope>): <lowercase imperative summary>
```

Subject line only. **No body, no footer, no version suffix, no trailing period,
no emoji, no issue reference, no em dash, no attribution trailers.**

- **type**: `feat`, `fix`, `chore`, `refactor`, `docs`
- **scope**: `cli`, `certs`, `vhosts`, `wordpress`, `wizard`, `installer`,
  `get`, `release`, `deb`, `ci`, `agents`, `docs`, `readme`. Prefer an
  existing scope over inventing one.
- **summary**: imperative mood, lowercase, no article at the start. Says what
  the change does, not how.

## Multiple concerns

Join with `; `, each with its own type and scope. Two or three clauses at most;
if it needs more, split the change.

```
feat(get): add a one-line installer that checks the release checksum; feat(release): publish a package for every version tag
```

## Examples

Input: a flag to import a gzipped dump
```
feat(wordpress): import a .sql.gz dump with -dbf
```

Input: the hosts line was added twice on a rerun
```
fix(vhosts): add the hosts line only when it is missing
```

## Rules

- Suggest the message; commit only when explicitly asked.
- Do not run `git add`/`git commit` as part of another task.
- Pass the message with `-m` on a single line.

## Names

Examples in code, comments, docs, the changelog and commit messages use
made-up names only: `local.acme.test`, `shop.localhost`,
`git@github.com:acme/site.git`, a person like Alex Morgan.
