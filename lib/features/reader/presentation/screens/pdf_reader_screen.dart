import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/di/providers.dart';
import '../../../books/domain/entities/book.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../providers/reader_providers.dart';
import '../widgets/page_indicator.dart';
import '../widgets/reader_toolbar.dart';

/// Filter warna untuk tiap reading mode. `null` berarti tidak ada filter
/// (tampilan asli PDF).
const _sepiaMatrix = <double>[
  0.393, 0.769, 0.189, 0, 0, //
  0.349, 0.686, 0.168, 0, 0, //
  0.272, 0.534, 0.131, 0, 0, //
  0, 0, 0, 1, 0,
];

const _invertMatrix = <double>[
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0,
];

class PdfReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final int startPage;

  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.startPage,
  });

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late final PdfController _controller;
  late int _currentPage;
  late final DateTime _sessionStartedAt;

  // Diambil sekali di initState (saat `ref` masih pasti valid) dan
  // disimpan di sini supaya bisa dipakai lagi di dispose() TANPA
  // menyentuh `ref` lagi. Riverpod tidak mengizinkan `ref.read`/`ref.watch`
  // dipanggil dari dalam dispose() — widget-nya sudah dianggap unmounted
  // di titik itu, jadi kalau tetap dipanggil akan throw sebelum sempat
  // menyimpan apa pun. Ini penyebab bug "reading time selalu 0 menit".
  late final ReadingProgressRepository _progressRepository;

  /// Immersive mode: tap di halaman untuk sembunyikan/tampilkan toolbar
  /// & page indicator, mirip Kindle/Google Play Books, supaya area baca
  /// terasa lebih luas dan minim gangguan.
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    // Layar HP biasanya auto-lock dalam hitungan menit (setting sistem,
    // di luar kontrol app). Untuk halaman panjang yang dibaca tanpa
    // scroll/swipe lama, itu bikin layar mati sendiri padahal masih
    // dibaca. Selama di Reader, wakelock dipaksa aktif supaya layar
    // tetap menyala; otomatis kembali ke perilaku normal begitu keluar
    // dari Reader (lihat dispose()).
    WakelockPlus.enable();
    _progressRepository = ref.read(readingProgressRepositoryProvider);
    _currentPage = widget.startPage.clamp(1, widget.book.totalPages).toInt();
    _sessionStartedAt = DateTime.now();
    _controller = PdfController(
      document: PdfDocument.openFile(widget.book.pdfPath),
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    // Static platform-channel call, tidak menyentuh `ref`/widget tree
    // sama sekali, jadi aman dipanggil fire-and-forget di sini (beda
    // kasus dengan bug ref.read sebelumnya).
    WakelockPlus.disable();
    _saveReadingTime();
    _controller.dispose();
    super.dispose();
  }

  void _saveReadingTime() {
    final now = DateTime.now();
    // Fire-and-forget: layar sudah ditutup, tidak perlu menunggu hasilnya.
    // Dipanggil lewat field `_progressRepository` (bukan `ref.read(...)`)
    // karena ini jalan di dalam dispose().
    _progressRepository.logSession(
      bookId: widget.book.id,
      startedAt: _sessionStartedAt,
      endedAt: now,
      startPage: widget.startPage,
      endPage: _currentPage,
    );
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    ref.read(readingProgressRepositoryProvider).updateCurrentPage(
          bookId: widget.book.id,
          currentPage: page,
          totalPages: widget.book.totalPages,
        );
    // Invalidate supaya Library & Book Detail screen menampilkan progress
    // terbaru ketika user kembali.
    ref.invalidate(bookProgressProvider(widget.book.id));
  }

  List<double>? _colorMatrixFor(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.light:
        return null;
      case ReadingMode.sepia:
        return _sepiaMatrix;
      case ReadingMode.dark:
        return _invertMatrix;
    }
  }

  Color _backgroundColorFor(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.light:
        return Colors.white;
      case ReadingMode.sepia:
        return const Color(0xFFF4ECD8);
      case ReadingMode.dark:
        return Colors.black;
    }
  }

  /// Bungkus toolbar/page-indicator dengan animasi slide + fade saat
  /// muncul/hilang, dan matikan hit-testing-nya saat sedang disembunyikan
  /// supaya tap di baliknya tetap kena ke halaman PDF.
  Widget _animatedChrome({
    required Widget child,
    required bool fromTop,
  }) {
    final hiddenOffset = fromTop ? const Offset(0, -1) : const Offset(0, 1);
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: _chromeVisible ? Offset.zero : hiddenOffset,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _chromeVisible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_chromeVisible,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readingMode = ref.watch(readingModeProvider);
    final matrix = _colorMatrixFor(readingMode);

    Widget pdfView = PdfView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      // Efek transisi halaman: PdfView memakai PageView di baliknya
      // sehingga perpindahan antar halaman sudah smooth-slide secara
      // default. Efek page-curl butuh custom page-transition renderer
      // yang di luar cakupan Phase 2 — dicatat sebagai item Phase 5.
      onPageChanged: _onPageChanged,
    );

    if (matrix != null) {
      pdfView = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: pdfView,
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColorFor(readingMode),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              child: pdfView,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _animatedChrome(
              fromTop: true,
              child: SafeArea(
                bottom: false,
                child: ReaderToolbar(
                  bookId: widget.book.id,
                  bookTitle: widget.book.title,
                  currentPage: _currentPage,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _animatedChrome(
              fromTop: false,
              child: Center(
                child: PageIndicator(
                  currentPage: _currentPage,
                  totalPages: widget.book.totalPages,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}