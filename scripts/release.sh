#!/usr/bin/env bash
# Release script for pagerduty-cli
# Builds tarballs, creates GitHub release, updates Homebrew tap formula
#
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 0.3.0
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
REPO="jholm117/pagerduty-cli"
TAP_REPO="jholm117/homebrew-tap"
TARGETS="darwin-arm64,darwin-x64"

# Sanity checks
command -v gh >/dev/null || { echo "gh CLI required"; exit 1; }
command -v npx >/dev/null || { echo "npx required"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

# Ensure clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is dirty. Commit or stash changes first."
  exit 1
fi

echo "==> Bumping version to $VERSION"
npm version "$VERSION" --no-git-tag-version

echo "==> Building"
rm -rf lib
npx tsc -b
npx oclif manifest

echo "==> Packing tarballs for $TARGETS"
rm -rf dist tmp
npx oclif pack tarballs -t "$TARGETS"

echo "==> Committing and tagging v$VERSION"
git add package.json package-lock.json 2>/dev/null || git add package.json
git commit -m "release: v$VERSION"
git tag "v$VERSION"
git push origin master --tags

echo "==> Creating GitHub release"
gh release create "v$VERSION" dist/*.tar.gz \
  --repo "$REPO" \
  --title "v$VERSION" \
  --generate-notes

echo "==> Updating Homebrew tap"
SHA_SHORT=$(git rev-parse --short HEAD)

# Get SHA256 hashes from the built tarballs
ARM64_FILE=$(ls dist/pd-v"$VERSION"-*-darwin-arm64.tar.gz)
X64_FILE=$(ls dist/pd-v"$VERSION"-*-darwin-x64.tar.gz)
SHA_ARM64=$(shasum -a 256 "$ARM64_FILE" | awk '{print $1}')
SHA_X64=$(shasum -a 256 "$X64_FILE" | awk '{print $1}')

# Derive tarball filenames (as they appear in the release)
ARM64_NAME=$(basename "$ARM64_FILE")
X64_NAME=$(basename "$X64_FILE")

TAP_DIR=$(mktemp -d)
gh repo clone "$TAP_REPO" "$TAP_DIR"
cat > "$TAP_DIR/Formula/pd.rb" <<FORMULA
class Pd < Formula
  desc "PagerDuty CLI - manage incidents, services, schedules and more"
  homepage "https://github.com/$REPO"
  version "$VERSION"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/$REPO/releases/download/v$VERSION/$ARM64_NAME"
      sha256 "$SHA_ARM64"
    else
      url "https://github.com/$REPO/releases/download/v$VERSION/$X64_NAME"
      sha256 "$SHA_X64"
    end
  end

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/pd"
  end

  test do
    assert_match "pagerduty-cli", shell_output("#{bin}/pd --version")
  end
end
FORMULA

cd "$TAP_DIR"
git add Formula/pd.rb
git commit -m "pd $VERSION"
git push origin main
cd "$ROOT"
rm -rf "$TAP_DIR"

echo "==> Done! Released v$VERSION"
echo "    brew update && brew upgrade pd"
