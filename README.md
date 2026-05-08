# NYX AUDIO 🐱
> Your music, unfettered.

A Spotify-replacement music manager that downloads lossless FLAC and syncs directly to your Snowsky Echo Mini (or any DAP).

---

## What it does

- **Search & discover** music via Last.fm (100M+ tracks, artist bios, similar artists)
- **Download as FLAC** automatically using yt-dlp in the background
- **Sync to your DAP** — plug in the Echo Mini via USB and hit Sync
- **Import from Spotify** — migrates your liked songs, playlists, and listening history
- **Android companion** — manage your library from your phone over Wi-Fi

---

## Quick start (macOS)

### Prerequisites
- macOS 12+ (Apple Silicon recommended)
- Xcode 14+ (install from App Store)
- Homebrew (https://brew.sh)

### 1. Run the setup script
```bash
chmod +x setup.sh
./setup.sh
```
This installs Flutter, yt-dlp, fetches all packages, and builds the app.

### 2. Add your API keys

**Last.fm** (free, takes 30 seconds):
1. Go to https://www.last.fm/api/account/create
2. Copy your API key
3. Paste it into `lib/services/lastfm_service.dart` → `_apiKey`

**Spotify** (for import only, free):
1. Go to https://developer.spotify.com/dashboard
2. Create an app, add `nyxaudio://callback` as a Redirect URI
3. Copy your Client ID
4. Paste it into `lib/services/spotify_service.dart` → `_clientId`

### 3. Run
```bash
flutter run -d macos
```

Or find the built app at:
```
build/macos/Build/Products/Release/nyx_audio.app
```

---

## DAP sync — how it works

1. Plug your Echo Mini in via USB
2. macOS mounts it as a drive under `/Volumes/`
3. Nyx detects it automatically (polls every 3 seconds)
4. Hit **Sync Now** — new tracks copy over, organised by Artist/Album

---

## Spotify migration

1. Go to **Import** tab → Connect Spotify
2. Authenticate in your browser
3. Hit **Import now** — pulls all liked songs + playlists
4. Downloads kick off automatically in the background

For play history:
1. Go to https://www.spotify.com/account/privacy/
2. Request your data → download the ZIP
3. Extract the `StreamingHistory*.json` files
4. Import → **Import history JSON** → select the file

---

## Android companion app

Coming in v1.1 — the Android app will let you browse and queue songs from your phone, syncing to the Mac over Wi-Fi.

---

## Project structure

```
lib/
  main.dart               # Entry point
  theme/
    nyx_theme.dart        # Colors, typography, component styles
  models/
    track.dart            # Track model
    models.dart           # Playlist, SyncLog, LastFmTrack, DapDevice
  services/
    database_service.dart # SQLite — all CRUD
    lastfm_service.dart   # Last.fm API search + metadata
    spotify_service.dart  # Spotify OAuth + library import
    download_service.dart # yt-dlp download queue
    dap_sync_service.dart # USB detection + file sync
    log_service.dart      # Sync log helper
  providers/
    providers.dart        # Riverpod state management
  screens/
    app_shell.dart        # Sidebar navigation shell
    home_screen.dart      # Dashboard
    discover_screen.dart  # Last.fm search
    secondary_screens.dart # Library, Playlists, DAP Sync, Logs
    import_screen.dart    # Spotify migration
  widgets/
    shared_widgets.dart   # TrackRow, StatCard, NyxPill, etc.
    nyx_logo.dart         # Cat face logo (drawn in Canvas)
```

---

## Tech stack

| Layer | Tech |
|-------|------|
| Framework | Flutter 3.16+ |
| State | Riverpod |
| Database | SQLite (sqflite_ffi) |
| Music search | Last.fm API |
| Downloads | yt-dlp subprocess |
| DAP sync | USB mount detection + file copy |
| Spotify import | Spotify Web API (OAuth) |
| Audio playback | just_audio |

---

## License
MIT — build on it, break it, make it yours.
