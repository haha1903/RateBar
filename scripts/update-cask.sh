#!/usr/bin/env bash
# Update (or create) a Homebrew Cask file in a tap repo, commit, and push.
#
# Usage: scripts/update-cask.sh <tap-repo> <cask-name> <version> <sha256>
#   tap-repo:   "user/homebrew-tap-name" (e.g. haha1903/homebrew-voiceinput)
#   cask-name:  "ratebar"
#   version:    "0.1.0"
#   sha256:     hex digest of the release zip

set -euo pipefail

TAP_REPO="${1:?tap repo required, e.g. haha1903/homebrew-voiceinput}"
CASK_NAME="${2:?cask name required, e.g. ratebar}"
VERSION="${3:?version required}"
SHA256="${4:?sha256 required}"

WORK="${TMPDIR:-/tmp}/tap-${CASK_NAME}-$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

echo "📥 Cloning $TAP_REPO into $WORK..."
gh repo clone "$TAP_REPO" "$WORK/tap" -- --quiet
cd "$WORK/tap"

CASK_FILE="Casks/${CASK_NAME}.rb"

if [[ -f "$CASK_FILE" ]]; then
  echo "✏️  Updating existing $CASK_FILE..."
  # Replace version "..." and sha256 "..." lines (first match each).
  sed -i.bak -E "s/^(  version )\".*\"/\\1\"${VERSION}\"/" "$CASK_FILE"
  sed -i.bak -E "s/^(  sha256 )\".*\"/\\1\"${SHA256}\"/" "$CASK_FILE"
  rm -f "${CASK_FILE}.bak"
else
  echo "📝 Creating new $CASK_FILE..."
  mkdir -p Casks
  cat > "$CASK_FILE" <<EOF
cask "${CASK_NAME}" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/haha1903/RateBar/releases/download/v#{version}/RateBar-#{version}.zip"
  name "RateBar"
  desc "macOS menu bar exchange-rate utility (AUD → CNY/USD/JPY/EUR)"
  homepage "https://github.com/haha1903/RateBar"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :tahoe"

  app "RateBar.app"

  zap trash: [
    "~/Library/Preferences/com.peter.ratebar.plist",
    "~/Library/Saved Application State/com.peter.ratebar.savedState",
  ]
end
EOF
fi

if git diff --quiet; then
  echo "ℹ️  No cask changes — already at v${VERSION}."
  exit 0
fi

git add "$CASK_FILE"
git -c user.email="cask-bot@local" -c user.name="cask-bot" \
  commit -m "${CASK_NAME}: v${VERSION}"
git push origin HEAD
echo "✅ Pushed cask update to $TAP_REPO."
