import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/routing/app_router.dart';
import '../../../books/presentation/providers/book_providers.dart';
import '../../../reader/domain/entities/reading_progress.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _readingModeLabel(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.light:
        return 'Light';
      case ReadingMode.dark:
        return 'Dark';
      case ReadingMode.sepia:
        return 'Sepia';
    }
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus riwayat baca?'),
        content: const Text(
          'Halaman terakhir, persentase, dan waktu baca semua buku akan '
          'di-reset ke 0. Buku, bookmark, dan notes tidak akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(settingsProvider.notifier).clearReadingHistory();
    ref.invalidate(bookLibraryProvider);
    ref.invalidate(statisticsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat baca berhasil dihapus.')),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref.read(backupRepositoryProvider).createBackupBytes();
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup',
        fileName: 'bookreader_backup.zip',
        bytes: Uint8List.fromList(bytes),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath != null
                ? 'Backup tersimpan.'
                : 'Backup dibatalkan.',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat backup: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'Ini akan MENIMPA seluruh data saat ini (buku, progress, '
          'bookmark, notes, settings) dengan isi file backup yang dipilih. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null) return;

    final picked = result.files.single;
    final bytes = picked.bytes ??
        (picked.path != null ? await File(picked.path!).readAsBytes() : null);
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membaca file backup.')),
        );
      }
      return;
    }

    try {
      await ref.read(backupRepositoryProvider).restoreFromBytes(bytes);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup berhasil di-import.')),
      );
      // Data sudah berubah total (bahkan mungkin database sebelumnya
      // sudah tidak relevan sama sekali), jadi paling aman kembali ke
      // Home dengan stack navigasi bersih daripada mengandalkan
      // invalidate satu-satu provider.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (settings) {
          return ListView(
            children: [
              const _SectionHeader('Tampilan'),
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Berlaku untuk seluruh aplikasi'),
                value: settings.darkMode,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).setDarkMode(value),
              ),
              ListTile(
                title: const Text('Default reading mode'),
                subtitle: Text(_readingModeLabel(settings.defaultReadingMode)),
                trailing: SegmentedButton<ReadingMode>(
                  segments: const [
                    ButtonSegment(
                      value: ReadingMode.light,
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ReadingMode.dark,
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ReadingMode.sepia,
                      label: Text('Sepia'),
                    ),
                  ],
                  selected: {settings.defaultReadingMode},
                  onSelectionChanged: (selection) => ref
                      .read(settingsProvider.notifier)
                      .setDefaultReadingMode(selection.first),
                ),
              ),
              ListTile(
                title: const Text('Font size'),
                subtitle: Text('${settings.fontSize.toStringAsFixed(0)} pt'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Slider(
                  min: 12,
                  max: 24,
                  divisions: 12,
                  value: settings.fontSize.clamp(12, 24),
                  label: settings.fontSize.toStringAsFixed(0),
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).setFontSize(value),
                ),
              ),
              const Divider(),
              const _SectionHeader('Data'),
              ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: const Text('Clear reading history'),
                subtitle: const Text('Reset halaman terakhir & waktu baca'),
                onTap: () => _confirmClearHistory(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Backup database'),
                subtitle: const Text('Export ke bookreader_backup.zip'),
                onTap: () => _exportBackup(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Import backup'),
                subtitle: const Text('Timpa data saat ini dari file .zip'),
                onTap: () => _importBackup(context, ref),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}