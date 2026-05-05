APP_NAME := RateBar
SCHEME := RateBar
APP_BUNDLE := $(APP_NAME).app

# Single source of truth for version (must match project.yml MARKETING_VERSION).
# CI overrides this from the pushed tag (e.g. `make release VERSION=0.1.2`).
VERSION := 0.1.2

# Build output (xcodebuild -derivedDataPath build).
BUILD_DERIVED := build
BUILD_PRODUCT_DIR := $(BUILD_DERIVED)/Build/Products/Release
BUILT_APP := $(BUILD_PRODUCT_DIR)/$(APP_BUNDLE)

# Distribution signing identity (Developer ID Application).
# Override in Makefile.local (or via env in CI) if needed.
RELEASE_SIGN_ID ?= Developer ID Application: Hai Chang (5B858997A3)
DEVELOPMENT_TEAM ?= 5B858997A3

# Notarization keychain profile (created via `xcrun notarytool store-credentials`).
# CI creates this profile in a temporary keychain on the runner.
NOTARY_PROFILE ?= RateBar-Notary

# Release artifact paths.
DIST_DIR := dist
RELEASE_ZIP := $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip

-include Makefile.local

.PHONY: gen build clean run release-build notarize release-zip release verify-release dist-clean

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

run: build
	open $(BUILD_DERIVED)/Build/Products/Debug/$(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DERIVED) $(DIST_DIR)

# --- Release pipeline ------------------------------------------------------
#
# Releases are produced by .github/workflows/release.yml on tag push.
# Targets below are also runnable locally for diagnosing build/sign/notarize
# issues, but the canonical artifacts come from CI.

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

# One-shot: build + notarize + zip + verify. CI calls this with VERSION=<tag>.
release: release-zip verify-release
	@echo ""
	@echo "🚀 Release artifact ready: $(RELEASE_ZIP)"
	@echo "GitHub release + cask bump are handled by .github/workflows/release.yml."
	@echo "To publish: bump VERSION here + project.yml, commit, then push a v\$$(VERSION) tag."

dist-clean:
	rm -rf $(DIST_DIR)
