import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/track.dart';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Database? _db;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'nyx_audio.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        album_art_url TEXT,
        duration_ms INTEGER,
        file_path TEXT,
        format TEXT,
        sample_rate INTEGER,
        bit_depth INTEGER,
        download_status TEXT NOT NULL DEFAULT 'pending',
        sync_status TEXT NOT NULL DEFAULT 'notSynced',
        source TEXT NOT NULL DEFAULT 'manual',
        spotify_id TEXT,
        lastfm_mbid TEXT,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_played INTEGER,
        added_at INTEGER NOT NULL,
        liked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        spotify_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        details TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_tracks_download_status ON tracks(download_status)');
    await db.execute(
        'CREATE INDEX idx_tracks_sync_status ON tracks(sync_status)');
    await db.execute('CREATE INDEX idx_tracks_artist ON tracks(artist)');
    await db.execute(
        'CREATE INDEX idx_sync_logs_timestamp ON sync_logs(timestamp DESC)');
  }

  // ── Tracks ──────────────────────────────────────────────────────────────

  Future<void> insertTrack(Track track) async {
    final d = await db;
    await d.insert('tracks', track.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTracks(List<Track> tracks) async {
    final d = await db;
    final batch = d.batch();
    for (final t in tracks) {
      batch.insert('tracks', t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateTrack(Track track) async {
    final d = await db;
    await d.update('tracks', track.toMap(),
        where: 'id = ?', whereArgs: [track.id]);
  }

  Future<void> updateTrackStatus(String id, DownloadStatus downloadStatus,
      {SyncStatus? syncStatus, String? filePath}) async {
    final d = await db;
    final updates = <String, dynamic>{
      'download_status': downloadStatus.name,
    };
    if (syncStatus != null) updates['sync_status'] = syncStatus.name;
    if (filePath != null) updates['file_path'] = filePath;
    await d.update('tracks', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTrack(String id) async {
    final d = await db;
    await d.delete('tracks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Track>> getAllTracks() async {
    final d = await db;
    final rows = await d.query('tracks', orderBy: 'added_at DESC');
    return rows.map(Track.fromMap).toList();
  }

  Future<List<Track>> getTracksByStatus(DownloadStatus status) async {
    final d = await db;
    final rows = await d.query('tracks',
        where: 'download_status = ?', whereArgs: [status.name]);
    return rows.map(Track.fromMap).toList();
  }

  Future<List<Track>> getPendingSync() async {
    final d = await db;
    final rows = await d.query('tracks',
        where: "sync_status = 'notSynced' AND download_status = 'downloaded'");
    return rows.map(Track.fromMap).toList();
  }

  Future<int> getTrackCount() async {
    final d = await db;
    final result =
        await d.rawQuery('SELECT COUNT(*) as count FROM tracks');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final d = await db;
    final result = await d.rawQuery(
        "SELECT COUNT(*) as count FROM tracks WHERE sync_status = 'synced'");
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getPendingSyncCount() async {
    final d = await db;
    final result = await d.rawQuery(
        "SELECT COUNT(*) as count FROM tracks WHERE sync_status = 'notSynced' AND download_status = 'downloaded'");
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Track?> getTrackBySpotifyId(String spotifyId) async {
    final d = await db;
    final rows = await d.query('tracks',
        where: 'spotify_id = ?', whereArgs: [spotifyId], limit: 1);
    if (rows.isEmpty) return null;
    return Track.fromMap(rows.first);
  }

  Future<void> incrementPlayCount(String id) async {
    final d = await db;
    await d.rawUpdate('''
      UPDATE tracks SET play_count = play_count + 1, last_played = ?
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, id]);
  }

  Future<void> toggleLiked(String id) async {
    final d = await db;
    await d.rawUpdate(
        'UPDATE tracks SET liked = CASE WHEN liked = 1 THEN 0 ELSE 1 END WHERE id = ?',
        [id]);
  }

  // ── Playlists ────────────────────────────────────────────────────────────

  Future<void> insertPlaylist(Playlist playlist) async {
    final d = await db;
    await d.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final d = await db;
    final rows =
        await d.query('playlists', orderBy: 'updated_at DESC');
    final playlists = rows.map(Playlist.fromMap).toList();
    for (final pl in playlists) {
      final trackRows = await d.query(
        'playlist_tracks',
        columns: ['track_id'],
        where: 'playlist_id = ?',
        whereArgs: [pl.id],
        orderBy: 'position ASC',
      );
      pl.trackIds = trackRows.map((r) => r['track_id'] as String).toList();
    }
    return playlists;
  }

  Future<void> addTrackToPlaylist(
      String playlistId, String trackId) async {
    final d = await db;
    final count = (await d.rawQuery(
            'SELECT COUNT(*) as c FROM playlist_tracks WHERE playlist_id = ?',
            [playlistId])).first['c'] as int? ?? 0;
    await d.insert(
        'playlist_tracks',
        {
          'playlist_id': playlistId,
          'track_id': trackId,
          'position': count
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await d.rawUpdate(
        'UPDATE playlists SET updated_at = ? WHERE id = ?',
        [DateTime.now().millisecondsSinceEpoch, playlistId]);
  }

  Future<void> deletePlaylist(String id) async {
    final d = await db;
    await d.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  // ── Sync Logs ────────────────────────────────────────────────────────────

  Future<void> insertLog(SyncLog log) async {
    final d = await db;
    await d.insert('sync_logs', log.toMap());
  }

  Future<List<SyncLog>> getLogs({int limit = 100}) async {
    final d = await db;
    final rows = await d.query('sync_logs',
        orderBy: 'timestamp DESC', limit: limit);
    return rows.map(SyncLog.fromMap).toList();
  }

  Future<void> clearLogs() async {
    final d = await db;
    await d.delete('sync_logs');
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final d = await db;
    final rows = await d
        .query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await db;
    await d.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    _db?.close();
    _db = null;
  }
}
