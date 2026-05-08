import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';
import '../theme/nyx_theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Text(text.toUpperCase(), style: NyxText.sectionLabel),
        if (trailing != null) ...[const Spacer(), trailing!],
      ]),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  const StatCard(
      {super.key, required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NyxColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NyxColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: NyxText.sectionLabel),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NyxColors.primaryText,
            )),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: NyxText.trackArtist),
        ],
      ]),
    );
  }
}

class NyxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  const NyxCard(
      {super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NyxColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: borderColor ?? NyxColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

class TrackRow extends StatelessWidget {
  final Track track;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final bool showStatus;

  const TrackRow({
    super.key,
    required this.track,
    this.index,
    this.onTap,
    this.onAdd,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(children: [
          if (index != null) ...[
            SizedBox(
              width: 24,
              child: Text(
                '${index! + 1}',
                style: const TextStyle(
                    fontSize: 12, color: NyxColors.textGhost),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: track.albumArtUrl != null
                ? CachedNetworkImage(
                    imageUrl: track.albumArtUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _artPlaceholder(),
                    errorWidget: (_, __, ___) => _artPlaceholder(),
                  )
                : _artPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Title + artist
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(track.title,
                      style: NyxText.trackTitle,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    [track.artist, if (track.album != null) track.album!]
                        .join(' · '),
                    style: NyxText.trackArtist,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
          const SizedBox(width: 8),
          if (showStatus) _statusPill(),
          if (onAdd != null) ...[
            const SizedBox(width: 8),
            _addButton(),
          ],
        ]),
      ),
    );
  }

  Widget _artPlaceholder() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: NyxColors.primaryDim,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note_rounded,
            size: 16, color: NyxColors.primaryText),
      );

  Widget _statusPill() {
    switch (track.syncStatus) {
      case SyncStatus.synced:
        return const NyxPill('Synced', style: NyxPillStyle.green);
      case SyncStatus.notSynced:
        switch (track.downloadStatus) {
          case DownloadStatus.downloading:
            return const NyxPill('Downloading', style: NyxPillStyle.purple);
          case DownloadStatus.downloaded:
            return const NyxPill('Pending', style: NyxPillStyle.gray);
          case DownloadStatus.failed:
            return const NyxPill('Failed', style: NyxPillStyle.red);
          case DownloadStatus.pending:
            return const NyxPill('Queued', style: NyxPillStyle.gray);
        }
      case SyncStatus.pending:
        return const NyxPill('Pending', style: NyxPillStyle.gray);
    }
  }

  Widget _addButton() => OutlinedButton(
        onPressed: onAdd,
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child:
            const Text('+ Add', style: TextStyle(fontSize: 11)),
      );
}

class NyxProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  const NyxProgressBar({super.key, required this.value, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: NyxColors.primaryDim,
        valueColor:
            const AlwaysStoppedAnimation<Color>(NyxColors.primary),
      ),
    );
  }
}

class NyxDivider extends StatelessWidget {
  const NyxDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(color: NyxColors.border, thickness: 0.5, height: 1);
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 40, color: NyxColors.textGhost),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NyxColors.textSecondary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: NyxText.trackArtist, textAlign: TextAlign.center),
      ]),
    );
  }
}
