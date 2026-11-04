# Changelog

### v1.1.0 (2026-11-04)
* **Installer:** one line installs devmagic: `curl -fsSL https://webtimeless.cloud/devmagic-cli.sh | bash` downloads the newest release, checks it against its `.sha256`, and runs its `install.sh`, with your terminal for its questions and sudo
* **Installer:** `get.sh --version v1.1.0` installs a given release, and `--dry-run` shows what would be downloaded and run without changing anything
* **Repo:** releases: every `vX.Y.Z` tag builds `devmagic-X.Y.Z.tar.gz` and its checksum and publishes them with `get.sh` as a GitHub release, its notes from this file
* **Repo:** the version lives in `VERSION`, read by the Makefile and the `.deb` build
* **Repo:** agent rules and skills: `AGENTS.md`, `.cursor/rules/`, `.cursor/skills/`

### v1.0.0 (2025-10-14)
* **CLI:** certificates from a local CA (`-ci`, `-c`), an Apache SSL vhost and hosts line (`-cf`), and WordPress with its database (`-w`, `-dbn`, `-t`)
* **CLI:** imports a database dump (`-dbf`) and clones a main repo (`-cr`) or several (`-pr`) into the site
* **CLI:** a setup wizard (`--wizard`), a config wizard (`--config-wizard`) and removal of a site with its database, vhost, hosts line and certificate (`--remove`, `--remove-wizard`)
* **Installer:** `install.sh` installs system-wide, and `make deb` builds a Debian package
