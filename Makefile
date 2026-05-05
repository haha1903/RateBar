APP_NAME := RateBar
SCHEME := RateBar
APP_BUNDLE := $(APP_NAME).app

# Single source of truth for version (must match project.yml MARKETING_VERSION).
VERSION := 0.1.1

# Build output (xcodebuild -derivedDataPath build).
BUILD_DERIVED := build
BUILD_PRODUCT_DIR := $(BUILD_DERIVED)/Build/Products/Release
BUILT_APP := $(BUILD_PRODUCT_DIR)/$(APP_BUNDLE)

# Distribution signing identity (Developer ID Application).
# Override in Makefile.local if you want a different one.
RELEASE_SIGN_ID ?= Developer ID Application: Hai Chang (5B858997A3)
DEVELOPMENT_TEAM ?= 5B858997A3

# Notarization keychain profile (created via `xcrun notarytool store-credentials`).
NOTARY_PROFILE ?= RateBar-Notary

# GitHub repo for releases (used by `make publish`).
RELEASE_REPO ?= haha1903/RateBar

# Homebrew tap repo (local clone or remote URL handled in scripts/update-cask.sh).
TAP_REPO ?= haha1903/homebrew-voiceinput
CASK_NAME ?= ratebar

# Release artifact paths.
DIST_DIR := dist
RELEASE_ZIP := $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip

-include Makefile.local

.PHONY: gen build clean run release-build notarize release-zip release verify-release publish bump-cask dist-clean

# --- Dev build (ad-hoc) ----------------------------------------------------

gen:
	@command -v xcodegen >/dev/null || { echo "❌ xcodegen not found. brew install xcodegen"; exit 1; }
	xcodegen generate

build: gen
	xcodebuild -scheme $(SCHEME) \
	  -destination "platform=macOS,arch=$$(uname -m)" \
	  -configuration Debug \
	  -derivedDataPath $(BUILD_DERIVED) \
	  build

run: release-build-only
	open $(BUILT_APP)

clean:
	rm -rf $(BUILD_DERIVED) $(DIST_DIR)

# --- Release pipeline ------------------------------------------------------

# Build Release with Developer ID signing + hardened runtime + secure timestamp.
# Overrides project.yml's ad-hoc CODE_SIGN_IDENTITY="-".
release-build: gen
	@echo "🔨 Building release with Developer ID signing..."
	xcodebuild -scheme $(SCHEME) \
	  -destination "platform=macOS,arch=$$(uname -m)" \
	  -configuration Release \
	  -derivedDataPath $(BUILD_DERIVED) \
	  CODE_SIGN_STYLE=Manual \
	  CODE_SIGN_IDENTITY="$(RELEASE_SIGN_ID)" \
	  DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) \
	  ENABLE_HARDENED_RUNTIME=YES \
	  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
	  OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
	  clean build
	@echo "🔍 Verifying signature..."
	codesign --verify --deep --strict --verbose=2 $(BUILT_APP)
	@echo "✅ Release-built $(BUILT_APP) (signed: $(RELEASE_SIGN_ID))"

# Submit to Apple's notary service, wait, then staple.
notarize: release-build
	@mkdir -p $(DIST_DIR)
	@echo "📦 Zipping for notarization..."
	ditto -c -k --keepParent $(BUILT_APP) $(DIST_DIR)/$(APP_NAME)-notary.zip
	@echo "☁️  Submitting to Apple notary service (a few minutes)..."
	xcrun notarytool submit $(DIST_DIR)/$(APP_NAME)-notary.zip \
	  --keychain-profile "$(NOTARY_PROFILE)" \
	  --wait
	@echo "📎 Stapling notarization ticket to $(BUILT_APP)..."
	xcrun stapler staple $(BUILT_APP)
	xcrun stapler validate $(BUILT_APP)
	@rm -f $(DIST_DIR)/$(APP_NAME)-notary.zip
	@echo "✅ Notarized and stapled $(BUILT_APP)"

# Final user-facing zip (notarized + stapled .app inside).
release-zip: notarize
	@mkdir -p $(DIST_DIR)
	rm -f $(RELEASE_ZIP)
	ditto -c -k --keepParent $(BUILT_APP) $(RELEASE_ZIP)
	@echo "📦 Created $(RELEASE_ZIP)"
	@echo "SHA256:"
	@shasum -a 256 $(RELEASE_ZIP)

# Independently verify the built/notarized .app passes Gatekeeper.
verify-release:
	@echo "🔍 codesign verify..."
	codesign --verify --deep --strict --verbose=2 $(BUILT_APP)
	@echo "🔍 spctl assess (Gatekeeper simulation)..."
	spctl --assess --type execute --verbose=2 $(BUILT_APP)
	@echo "🔍 stapler validate..."
	xcrun stapler validate $(BUILT_APP)
	@echo "✅ All verification checks passed"

# One-shot: build + notarize + zip + verify.
release: release-zip verify-release
	@echo ""
	@echo "🚀 Release artifact ready: $(RELEASE_ZIP)"
	@echo "Next steps:"
	@echo "  make publish           # tag + gh release create + bump cask"

# Tag, push, create GitHub Release with the zip, bump cask in tap repo.
publish:
	@if [ ! -f $(RELEASE_ZIP) ]; then echo "❌ $(RELEASE_ZIP) missing. Run: make release"; exit 1; fi
	@if ! git diff-index --quiet HEAD --; then echo "❌ working tree dirty, commit first"; exit 1; fi
	@echo "🏷  Tagging v$(VERSION)..."
	git tag -a v$(VERSION) -m "Release v$(VERSION)" || true
	git push origin v$(VERSION)
	@echo "📤 Creating GitHub release on $(RELEASE_REPO)..."
	gh release create v$(VERSION) $(RELEASE_ZIP) \
	  --repo $(RELEASE_REPO) \
	  --title "v$(VERSION)" \
	  --generate-notes
	@$(MAKE) bump-cask

# Update the cask in the tap repo with new version + sha256.
bump-cask:
	@SHA=$$(shasum -a 256 $(RELEASE_ZIP) | awk '{print $$1}'); \
	  echo "🍺 Bumping cask $(CASK_NAME) → $(VERSION) (sha256 $$SHA)"; \
	  bash scripts/update-cask.sh "$(TAP_REPO)" "$(CASK_NAME)" "$(VERSION)" "$$SHA"

dist-clean:
	rm -rf $(DIST_DIR)
