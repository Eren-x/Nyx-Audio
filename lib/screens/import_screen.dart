import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../models/track.dart';
import '../services/spotify_service.dart';
import '../theme/nyx_theme.dart';
import '../widgets/shared_widgets.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});
  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _spotify = SpotifyService();
  bool _isSpotifyAuthed = false;
  bool _importing = false;
  int _importDone = 0;
  int _importTotal = 0;
  String _importStatus = '';

  @override
  void initState() {
    super.initState();
    _checkSpotify();
  }

  Future<void> _checkSpotify() async {
    final auth = await _spotify.isAuthenticated;
    if (mounted) setState(() => _isSpotifyAuthed = auth);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Import', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text('Migrate from Spotify or bring in your history',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),

        // Spotify import
        _ImportCard(
          title: 'Spotify library import',
          description:
              'Connect your Spotify account once. Nyx pulls all your liked songs and playlists, then matches and downloads each one as FLAC.',
          trailing: _isSpotifyAuthed
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const NyxPill('Connected', style: NyxPillStyle.green),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _importing ? null : _runSpotifyImport,
                    child: const Text('Import now'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await _spotify.logout();
                      setState(() => _isSpotifyAuthed = false);
                    },
                    child: const Text('Disconnect'),
                  ),
                ])
              : ElevatedButton(
                  onPressed: () async {
                    await _spotify.launchAuth();
                    await Future.delayed(const Duration(seconds: 2));
                    await _checkSpotify();
                  },
                  child: const Text('Connect Spotify'),
                ),
        ),

        // Import progress
        if (_importing) ...[
          const SizedBox(height: 12),
          NyxCard(
            borderColor: NyxColors.borderBright,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(_importStatus,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                            _importTotal > 0
                                ? '$_importDone / $_importTotal'
                                : '...',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                  const SizedBox(height: 6),
                  NyxProgressBar(
                    value: _importTotal > 0
                        ? _importDone / _importTotal
                        : 0,
                  ),
                ]),
          ),
        ],

        const SizedBox(height: 12),

        // Spotify history JSON
        _ImportCard(
          title: 'Spotify listening history',
          description:
              'Download your data from Spotify\'s privacy page (it\'s a ZIP with StreamingHistory JSON files). Drop the JSON here and Nyx absorbs your play counts.',
          trailing: OutlinedButton.icon(
            onPressed: _importHistory,
            icon: const Icon(Icons.upload_file_rounded, size: 15),
            label: const Text('Import history JSON'),
          ),
        ),

        const SizedBox(height: 12),

        // Android sync
        _ImportCard(
          title: 'Android companion app',
          description:
              'Your Android Nyx app connects over Wi-Fi. Songs and playlists you queue on your phone appear here automatically when on the same network.',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            const NyxPill('Wi-Fi sync ready',
                style: NyxPillStyle.purple),
          ]),
        ),
      ]),
    );
  }

  Future<void> _runSpotifyImport() async {
    setState(() {
      _importing = true;
      _importDone = 0;
      _importTotal = 0;
      _importStatus = 'Fetching liked songs…';
    });

    try {
      final liked = await _spotify.getLikedSongs(
          onProgress: (done, total) {
        if (mounted) setState(() {
          _importDone = done;
          _importTotal = total;
          _importStatus = 'Fetching liked songs… $done / $total';
        });
      });

      setState(() => _importStatus = 'Fetching playlists…');
      final playlists = await _spotify.getPlaylists();

      // Import liked songs
      await ref.read(tracksProvider.notifier).addTracks(liked);

      // Import each playlist
      for (final pl in playlists) {
        final plName = pl['name'] as String? ?? 'Playlist';
        setState(() => _importStatus = 'Importing "$plName"…');
        final plTracks = await _spotify.getPlaylistTracks(
            pl['id'] as String);
        await ref.read(tracksProvider.notifier).addTracks(plTracks);

        final playlist = Playlist(
          name: plName,
          spotifyId: pl['id'] as String?,
          source: 'spotify',
          trackIds: plTracks.map((t) => t.id).toList(),
        );
        await ref
            .read(playlistsProvider.notifier)
            .addPlaylist(playlist);
      }

      if (mounted) {
        setState(() {
          _importing = false;
          _importStatus = 'Import complete!';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Imported ${liked.length} liked songs and ${playlists.length} playlists'),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importing = false;
          _importStatus = 'Import failed: $e';
        });
      }
    }
  }

  Future<void> _importHistory() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      final content =
          await File(result.files.single.path!).readAsString();
      final history = _spotify.parseHistoryJson(content);
      final counts = _spotify.extractPlayCounts(history);

      // Update play counts in DB
      int updated = 0;
      final allTracks = ref.read(tracksProvider);
      for (final track in allTracks) {
        final key =
            '${track.artist}::${track.title}'.toLowerCase();
        final count = counts[key];
        if (count != null && count > 0) {
          updated++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'History imported: $updated tracks matched with play counts'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to parse history JSON')));
      }
    }
  }
}

class _ImportCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget trailing;

  const _ImportCard({
    required this.title,
    required this.description,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NyxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: NyxColors.primaryText)),
        const SizedBox(height: 4),
        Text(description,
            style: const TextStyle(
                fontSize: 11,
                color: NyxColors.textMuted,
                height: 1.5)),
        const SizedBox(height: 12),
        trailing,
      ]),
    );
  }
}
