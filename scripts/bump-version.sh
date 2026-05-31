#!/usr/bin/env bash
# Bumps hamta version (semver), commits, and tags the release.
# Usage: ./scripts/bump-version.sh [patch|minor|major]
set -euo pipefail

BUMP="${1:-patch}"
VERSION_FILE="bin/hamta"
VERSION_PATTERN='^VERSION="([0-9]+\.[0-9]+\.[0-9]+)"$'

usage() {
    echo "Usage: $0 [patch|minor|major|current]" >&2
}

current_version() {
    local version_line
    version_line="$(grep -E "$VERSION_PATTERN" "$VERSION_FILE")"
    version_line="${version_line#VERSION=\"}"
    printf '%s\n' "${version_line%\"}"
}

if [[ "$BUMP" == "current" ]]; then
    current_version
    exit 0
fi

if [[ "$BUMP" != "patch" && "$BUMP" != "minor" && "$BUMP" != "major" ]]; then
    usage
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree has uncommitted changes; commit or stash them before bumping a version." >&2
    exit 1
fi

current="$(current_version)"
IFS='.' read -r major minor patch <<< "$current"

case "$BUMP" in
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    patch)
        patch=$((patch + 1))
        ;;
esac

next="${major}.${minor}.${patch}"

if git rev-parse -q --verify "refs/tags/${next}" >/dev/null; then
    echo "Tag ${next} already exists." >&2
    exit 1
fi

perl -0pi -e "s/^VERSION=\"\Q${current}\E\"$/VERSION=\"${next}\"/m" "$VERSION_FILE"

git add "$VERSION_FILE"
git commit -m "chore: bump version to ${next}"
git tag -a "$next" -m "$next"

echo "Bumped hamta ${current} -> ${next} (${BUMP})"
echo "Created commit and tag ${next}"
echo "Next: git push --follow-tags, then update andrewmmc/homebrew-tap for ${next}."
