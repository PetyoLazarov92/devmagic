# devmagic

The `devmagic` command: Bash scripts that make a local WordPress site on
Ubuntu or Debian in one run, with a certificate from a local CA, an Apache
SSL vhost, a hosts line, a database and WordPress, and that can import a dump,
clone repos into the site, and remove a site again. Its home page is
`https://webtimeless.cloud/devmagic-cli/`; it works next to devmagic-panel.

## Layout

- `mklocalenv.sh`: the entry point, installed as `/usr/local/bin/devmagic` (a
  wrapper) with the code in `/usr/local/share/devmagic`. Parses the flags and
  calls the actions.
- `includes/`: the actions (`mkcertissuer`, `mkcert`, `mkconfig-ssl`,
  `mkwpwebsite`, `gitclone`, `rmwpwebsite`).
- `tools/`: the wizards and the config file (`devmagic-conf.sh`).
- `utilities/`: colours, logging (`devmagic_log_*`) and checks.
- `install.sh`, `uninstall.sh`: install from a checkout or a release folder.
- `get.sh`: the one-line installer. It downloads a release, checks its
  checksum and runs that release's `install.sh`.
- `build/create-deb-package.sh`: the optional `.deb`.
- `VERSION`: the version, read by the Makefile, the deb build and the release
  workflow.
- `.github/workflows/release.yml`: on a `vX.Y.Z` tag, checks the scripts,
  builds `devmagic-X.Y.Z.tar.gz` with its `.sha256` and publishes a GitHub
  release with them and `get.sh`, its notes from `CHANGELOG.md`.

## Commands

```bash
make test             # bash -n on every script
make lint             # shellcheck (sudo apt install shellcheck)
make install          # install from this checkout (bash install.sh)
make deb              # build the .deb
bash get.sh --dry-run # show what the one-line installer would download and run
```

## Rules

1. **Live next to devmagic-panel.** The panel reads what devmagic makes and
   leaves it as it is: sites in `/var/www/<domain>`, vhosts as
   `<domain>-ssl.conf`, certificates in `/etc/ssl/localcerts/<domain>`, and
   hosts lines outside the panel's marked block. Changing where any of these
   go is a breaking change: check the panel's `AGENTS.md` first, and bump the
   major version.
2. **Only released code installs.** `get.sh` installs a release package
   checked against its `.sha256`, never a branch. A release comes only from a
   pushed `vX.Y.Z` tag through `release.yml`.
3. **Version and changelog with every change**, once per session: `VERSION`,
   the README badge and a `CHANGELOG.md` section (see
   `.cursor/rules/versioning.mdc`).
4. **Scripts pass shellcheck.** New and changed code passes `shellcheck -x`
   with no warnings; the existing scripts are held at error level in CI until
   they are cleaned up.
5. **Secrets stay out of argv and logs** in new code: passwords go through the
   environment or stdin, and are never printed. The existing `-dbp` flag is
   kept for compatibility.
6. **Made-up names only.** Examples, tests, comments, docs, the changelog and
   commit messages use made-up names (`local.spellbook.test`, `shop.localhost`,
   `git@github.com:wandworks/site.git`), never a real client, project, company
   or person, including the sites on this machine. The set is shared with
   devmagic-panel and webtimeless.cloud: Spellbook for the main example site,
   Wandworks for the agency and its org, theme and plugins, Alex Morgan and Sam
   Lee for people, and production addresses on the reserved `.example`.
7. **No em dashes anywhere**: output, docs, comments, commit messages. Use a
   comma, a colon, or two sentences.
8. **Respect the user's machine.** `install.sh` never runs as root and asks
   before installing packages; nothing deletes a site's files, database or
   certificate without the user asking for that site.

## Commit messages

`type(scope): lowercase imperative summary` on one line. No body, no trailing
period. Types are `feat`, `fix`, `chore`, `refactor`, `docs`. Join multiple
concerns with `; `. Suggest the message, commit only when asked. See the
`wt-commit-message` skill for scopes.

Every commit is the user's own: their git name and GPG signature, one line,
and **no trailers**: no `Co-Authored-By`, `Signed-off-by` or "Generated with"
line, even when a tool asks for one. Before a commit run only the checks the
change needs; after a push, do not wait for or watch the GitHub Actions runs.
The `wt-commit-and-push` skill has the steps.

## Detail

Conventions live in `.cursor/rules/` (`shell-scripts.mdc`, `versioning.mdc`,
`user-facing-copy.mdc`) and workflows in `.cursor/skills/` (`wt-commit-message`,
`wt-commit-and-push`, `wt-release`), linked from `.claude/skills/`.
