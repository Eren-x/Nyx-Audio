import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../models/track.dart';
import '../theme/nyx_theme.dart';
import '../widgets/shared_widgets.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() =>
      _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();
  String _lastSearchedArtist = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Discover',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text('Powered by Last.fm · search any song, artist or album',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search for music...',
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: NyxColors.textMuted),
            ),
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
            style: const TextStyle(fontSize: 13, color: NyxColors.primaryText),
          ),
        ]),
      ),
      Expanded(
        child: results.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: NyxColors.primary, strokeWidth: 2)),
          error: (e, _) => Center(
              child: Text('Search failed',
                  style: Theme.of(context).textTheme.bodySmall)),
          data: (tracks) => tracks.isEmpty
              ? _emptyState()
              : _resultsList(tracks),
        ),
      ),
    ]);
  }

  Widget _emptyState() {
    final query = ref.watch(searchQueryProvider);
    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Search for any music',
        subtitle: 'Songs, artists, albums — all powered by Last.fm',
      );
    }
    return const EmptyState(
      icon: Icons.music_off_rounded,
      title: 'No results found',
      subtitle: 'Try a different search term',
    );
  }

  Widget _resultsList(List<LastFmTrack> tracks) {
    // Get unique artists for the similar section
    final artists = tracks.map((t) => t.artist).toSet().take(1).toList();
    final firstArtist = artists.isNotEmpty ? artists.first : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const SectionLabel('Top results'),
        ...tracks.map((t) => TrackRow(
              track: t.toTrack(),
              showStatus: false,
              onAdd: () => _addToLibrary(t),
            )),
        if (firstArtist.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionLabel(
              'Similar artists to $firstArtist'),
          _SimilarArtists(artist: firstArtist),
        ],
      ],
    );
  }

  Future<void> _addToLibrary(LastFmTrack lfm) async {
    final track = lfm.toTrack();
    await ref.read(tracksProvider.notifier).addTrack(track);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('"${lfm.name}" added to library · downloading…'),
      ));
    }
  }
}

class _SimilarArtists extends ConsumerWidget {
  final String artist;
  const _SimilarArtists({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(similarArtistsProvider(artist));
    return similar.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (names) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: names
            .map((n) => GestureDetector(
                  onTap: () {
                    ref.read(searchQueryProvider.notifier).state = n;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: NyxColors.primaryDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: NyxColors.borderBright, width: 0.5),
                    ),
                    child: Text(n,
                        style: const TextStyle(
                            fontSize: 12,
                            color: NyxColors.primaryText)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
