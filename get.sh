#!/usr/bin/env bash
# Installs devmagic from its newest release, or the one given with --version: downloads the
# release package and its checksum, checks it, unpacks it in a temporary folder and runs its
# install.sh, which installs the devmagic command for the whole system and asks for sudo when
# it needs it. Run it as your own user, not root.
#
#   curl -fsSL https://webtimeless.cloud/devmagic-cli.sh | bash
#   bash get.sh [--version v1.1.0] [--repo owner/name] [--dry-run]
#
# --dry-run downloads and checks the package, then stops before install.sh.
set -euo pipefail

SLUG="${DEVMAGIC_REPO:-PetyoLazarov92/devmagic}"
# Where release files are downloaded from; tests point it at a local folder (file://).
BASE="${DEVMAGIC_DOWNLOAD_BASE:-}"
VERSION=""
DRY_RUN=0
TAG_RE='^v[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,6}$'

step() { printf '==> %s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --version) VERSION="${2:?--version needs a release, like v1.1.0}"; shift ;;
    --repo) SLUG="${2:?--repo needs owner/name}"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) sed -n '2,10p' "${BASH_SOURCE[0]:-get.sh}" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

if [[ ! "$SLUG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*/[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]]; then
  die "not a repository: $SLUG (like owner/name)"
fi
if [[ -n "$VERSION" && ! "$VERSION" =~ $TAG_RE ]]; then
  die "not a release: $VERSION (like v1.1.0)"
fi
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  die "run this as your own user, not root: install.sh asks for sudo when it needs it"
fi
for cmd in curl tar sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd is needed (sudo apt install $cmd)"
done

# The newest release: GitHub redirects releases/latest to the newest release's tag page.
if [[ -z "$VERSION" ]]; then
  [[ -z "$BASE" ]] || die "--version is needed with DEVMAGIC_DOWNLOAD_BASE"
  latest="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$SLUG/releases/latest")" ||
    die "cannot reach github.com/$SLUG"
  VERSION="${latest##*/}"
  [[ "$VERSION" =~ $TAG_RE ]] || die "github.com/$SLUG has no release yet"
fi

v="${VERSION#v}"
pkg="devmagic-$v.tar.gz"
BASE="${BASE:-https://github.com/$SLUG/releases/download/$VERSION}"
step "devmagic $VERSION from $SLUG"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

step "Downloading $pkg"
curl -fsSL -o "$tmp/$pkg" "$BASE/$pkg" || die "cannot download $BASE/$pkg"
curl -fsSL -o "$tmp/$pkg.sha256" "$BASE/$pkg.sha256" || die "cannot download $BASE/$pkg.sha256"

step "Checking it against $pkg.sha256"
(cd "$tmp" && sha256sum --check --quiet --strict "$pkg.sha256") ||
  die "$pkg does not match its checksum; nothing was installed"

tar -xzf "$tmp/$pkg" -C "$tmp"
dir="$tmp/devmagic-$v"
[[ -f "$dir/install.sh" ]] || die "$pkg has no install.sh"

if ((DRY_RUN)); then
  step "Dry run: $pkg checks out; install.sh would run now"
  exit 0
fi

step "Running install.sh"
cd "$dir"
# Piped into bash, stdin is this script: give install.sh the terminal for its questions.
if [[ -t 0 ]]; then
  bash install.sh
elif { : </dev/tty; } 2>/dev/null; then
  bash install.sh </dev/tty
else
  die "install.sh asks questions and needs a terminal; download get.sh and run it with bash"
fi
