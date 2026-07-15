import 'package:flutter/material.dart';

/// Hasil yang dikembalikan dialog form note.
class NoteFormResult {
  final int pageNumber;
  final String content;

  const NoteFormResult({required this.pageNumber, required this.content});
}

/// Dialog untuk menambah atau mengedit note.
///
/// - Mode tambah: [initialPage] dan [initialContent] null/kosong,
///   field halaman bisa diedit bebas.
/// - Mode edit: [initialPage] & [initialContent] diisi, field halaman
///   dikunci (note selalu terikat ke halaman aslinya).
Future<NoteFormResult?> showNoteFormDialog(
  BuildContext context, {
  int? initialPage,
  String? initialContent,
  required int totalPages,
}) {
  final pageController = TextEditingController(
    text: initialPage?.toString() ?? '',
  );
  final contentController = TextEditingController(text: initialContent ?? '');
  final formKey = GlobalKey<FormState>();
  final isEditing = initialPage != null;

  return showDialog<NoteFormResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isEditing ? 'Edit Note' : 'Tambah Note'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: pageController,
              enabled: !isEditing,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Halaman'),
              validator: (value) {
                final page = int.tryParse(value ?? '');
                if (page == null || page < 1 || page > totalPages) {
                  return 'Masukkan halaman 1–$totalPages';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contentController,
              maxLines: 4,
              autofocus: !isEditing,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Catatan tidak boleh kosong'
                      : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              NoteFormResult(
                pageNumber: int.parse(pageController.text),
                content: contentController.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}