#!/bin/bash
# ──────────────────────────────────────────────
#  Nyx Audio — setup & build script (macOS)
# ──────────────────────────────────────────────

set -e
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "  ╔═══════════════════════════╗"
echo "  ║      NYX AUDIO SETUP      ║"
echo "  ╚═══════════════════════════╝"
echo -e "${NC}"

# ── 1. Check for Flutter ───────────────────────
if ! command -v flutter &>/dev/null; then
  echo "Flutter not found. Installing via Homebrew…"
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Please install from https://brew.sh then re-run."
    exit 1
  fi
  brew install --cask flutter
  echo -e "${GREEN}✓ Flutter installed${NC}"
else
  echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"
fi

# ── 2. Check for yt-dlp ───────────────────────
if ! command -v yt-dlp &>/dev/null; then
  echo "Installing yt-dlp…"
  brew install yt-dlp
  echo -e "${GREEN}✓ yt-dlp installed${NC}"
else
  echo -e "${GREEN}✓ yt-dlp found${NC}"
fi

# ── 3. Flutter doctor check ──────────────────
echo ""
echo "Running flutter doctor…"
flutter doctor --android-licenses 2>/dev/null || true
flutter doctor

# ── 4. Enable macOS desktop ──────────────────
flutter config --enable-macos-desktop

# ── 5. Get packages ──────────────────────────
echo ""
echo "Fetching packages…"
flutter pub get
echo -e "${GREEN}✓ Packages fetched${NC}"

# ── 6. Build macOS app ───────────────────────
echo ""
echo "Building Nyx Audio for macOS…"
flutter build macos --release

echo ""
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Build complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo ""
echo "Your app is at:"
echo "  build/macos/Build/Products/Release/nyx_audio.app"
echo ""
echo "To run in development mode:"
echo "  flutter run -d macos"
echo ""
echo -e "${PURPLE}Remember to add your API keys in:${NC}"
echo "  lib/services/lastfm_service.dart  → _apiKey"
echo "  lib/services/spotify_service.dart → _clientId"
