---
name: wt-release
description: Ship a change in devmagic by bumping VERSION and the README badge, adding a CHANGELOG.md entry in the repository format, updating the docs the change affects, and checking the scripts. Use after implementing a feature or fix, or when the user asks to release, bump the version, update the changelog, or finish a change.
---

# WT Release

Run this after the code change is complete. Work through the checklist in order.

```
- [ ] 1. Decide the bump (see versioning rule: patch, minor, major)
- [ ] 2. VERSION
- [ ] 3. README.md badge on line 3
- [ ] 4. CHANGELOG.md entry at the top
- [ ] 5. Docs: README sections and AGENTS.md, if the change affects them
- [ ] 6. Verify
- [ ] 7. Names review
- [ ] 8. Suggest the commit message (wt-commit-message)
- [ ] 9. Tag and push the release, only when the user asks
```

## 4. Changelog entry

```markdown
### v1.2.0 (2026-11-04)
* **CLI:** `-dbf` imports a `.sql.gz` dump as well as a `.sql` one
```

`### vX.Y.Z (YYYY-MM-DD)` with today's ISO date, `*` bullets, a bolded area
ending with a colon, present tense, what the user notices. Once per session:
if this session already added an entry, extend it instead of adding another.

## 6. Verify

```bash
make test
make lint                 # needs shellcheck
bash get.sh --dry-run     # when get.sh changed
```

Report what ran and what passed; if something could not run (shellcheck not
installed), say so. The release workflow runs the same checks on GitHub.

## 7. Names review

Examples use made-up names only. Before the commit, compare the repository
with the site names on this machine; they are read at that moment and never
written into the repository:

```bash
names=$( { ls /var/www; grep -hoE 'Server(Name|Alias).*' /etc/apache2/sites-available/*.conf; } \
  | grep -oE '[A-Za-z0-9-]{4,}' | tr 'A-Z' 'a-z' | sort -u )
for w in $names; do git grep -qiF "$w" -- . && echo "$w"; done
```

Generic words (`local`, `test`, `devmagic`) are fine. Any hit that names a
client, project, company or person gets a made-up name, and the review runs
again.

## 9. Tag and push

Only when the user asks to release: tag the release commit with an annotated
tag that matches `VERSION`, and push it only when they ask. The push starts
`release.yml`, which builds the package and publishes the GitHub release, so
it is public at once.

```bash
git tag -a v1.2.0 -m "v1.2.0"
git push origin master v1.2.0   # only when asked
```
