# BookReader — Phase 1

Personal offline PDF reader (mirip Kindle), dibangun dengan Flutter.
Semua data tersimpan lokal di device, tanpa backend.

## Apa yang sudah dikerjakan di Phase 1

1. Struktur project dengan clean architecture (core/ + features/,
   masing-masing fitur punya domain/, data/, presentation/).
2. pubspec.yaml — dependency yang dipakai Phase 1 (Riverpod, sqflite,
   path_provider, file_picker, pdfx, dll).
3. Database schema (lib/core/database/database_helper.dart) — kelima
   tabel (books, reading_progress, bookmarks, notes, settings) sudah
   dibuat dari awal supaya tidak perlu migrasi versi database di phase
   berikutnya. Yang benar-benar dipakai fiturnya baru books.
4. Routing (lib/core/routing/app_router.dart) — Splash lalu Home.
5. Library screen — grid buku, search, sort (terakhir dibaca, terbaru
   ditambahkan, judul), tombol plus untuk import PDF, empty state, dan
   swipe-to-refresh.

## Keputusan teknis

- State management: Riverpod (bukan Bloc). Untuk aplikasi single-user,
  offline-first seperti ini, Riverpod memberi boilerplate yang jauh
  lebih sedikit dibanding Bloc untuk hasil yang sama, sambil tetap
  testable dan scalable, jadi lebih maintainable untuk konteks project
  ini.
- Local database: sqflite (bukan drift). Query di app ini relatif
  sederhana (CRUD per tabel), jadi raw SQL yang dibungkus repository
  pattern sudah cukup jelas dan mudah dirawat tanpa overhead code
  generation dari drift.
- Repository pattern: presentation memanggil domain (interface), domain
  diimplementasikan oleh data (implementasi + datasource). Widget/provider
  tidak pernah menyentuh SQLite atau file system secara langsung.

## Alur import PDF (sudah berfungsi end-to-end)

1. User tekan tombol plus di Library screen, file_picker membuka file
   explorer dengan filter .pdf.
2. BookRepositoryImpl.importBook():
   - copy PDF ke ApplicationDocumentsDirectory/books/uuid.pdf
   - baca jumlah halaman via pdfx
   - render halaman pertama jadi thumbnail PNG ke covers/uuid.png
   - judul default diambil dari nama file
   - simpan row baru ke tabel books
3. bookLibraryProvider otomatis refresh, buku baru langsung muncul di grid.

## Menjalankan project

```bash
flutter pub get
flutter run
```

Project ini ditarget Android dulu, tapi karena semua dependency yang
dipakai (sqflite, path_provider, file_picker, pdfx) sudah cross-platform,
struktur ini siap dikembangkan ke iOS tanpa perubahan arsitektur.

## Struktur folder

```
lib/
  core/
    database/        DatabaseHelper (SQLite schema)
    di/               Riverpod providers (dependency injection)
    routing/          AppRoutes + AppRouter
    theme/            Material 3 theme
  features/
    books/
      domain/
        entities/     Book (entity), BookSortOption
        repositories/ BookRepository (interface)
      data/
        models/       BookModel (SQLite row <-> entity)
        datasources/  BookLocalDataSource (file IO + raw SQL)
        repositories/ BookRepositoryImpl
      presentation/
        providers/    bookLibraryProvider, search & sort state
        screens/      SplashScreen, HomeShell, LibraryScreen
        widgets/      BookCard
  shared/
    widgets/          ComingSoonPlaceholder (tab Statistics & Settings)
  main.dart
```

## Phase 2 — PDF Reader & save last page

Ditambahkan pada phase ini:

1. **Fitur `reader`** (domain/data/presentation terpisah, sama seperti
   fitur `books`) — mengelola tabel `reading_progress`.
2. **Book Detail screen** — cover, judul, jumlah halaman, progress bar.
   Menampilkan tombol **Continue Reading** (lanjut dari halaman terakhir)
   dan **Start From Beginning** kalau sudah ada progress; kalau belum
   pernah dibuka, tombolnya jadi **Start Reading**. Ini menggantikan
   dialog "Continue reading from page X?" di spesifikasi — datanya sama,
   hanya tampil sebagai layar penuh, bukan dialog, supaya info buku dan
   pilihan lanjut/mulai-ulang ada dalam satu tempat.
3. **PDF Reader screen** (`pdfx`) —
   - swipe kiri/kanan ganti halaman, dengan transisi geser otomatis dari
     `PdfView` (page-curl belum ada, dicatat sebagai item Phase 5 karena
     butuh custom page-transition renderer)
   - page indicator `214 / 464` mengambang di bawah
   - auto-save `current_page` & `percentage` ke `reading_progress` setiap
     pindah halaman
   - reading mode **light / sepia / dark** lewat `ColorFiltered` (ubah
     warna hasil render PDF; dipilih dari icon brightness di toolbar)
   - toolbar dengan icon Bookmark, Table of Contents, Search — ketiganya
     tampil sesuai spesifikasi tapi masih placeholder ("akan tersedia di
     Phase 3") karena baru diimplementasikan penuh di Phase 3
   - reading time diakumulasi ke `total_read_time` setiap keluar dari
     reader (dipakai nanti di Statistics, Phase 4)
4. Library screen sekarang menampilkan progress asli (bukan lagi selalu
   0%) berkat progress digabung dari tabel `reading_progress` di level
   repository (satu query batch per buku, bukan N+1).

### Alur lengkap Phase 2

Library → tap buku → Book Detail (lihat progress) → Continue Reading /
Start From Beginning / Start Reading → Reader screen (baca, auto-save
tiap ganti halaman) → kembali → Library & Book Detail otomatis refresh
progress terbaru.

### Catatan teknis

- `font_size` di tabel `settings` sengaja belum dipakai di Reader,
  karena PDF dirender sebagai gambar per halaman (bukan teks yang bisa
  di-reflow), jadi ukuran font tidak relevan untuk isi PDF itu sendiri.
  Pengaturan ini baru masuk akal untuk UI aplikasi secara umum, akan
  ditangani di Setting screen (Phase 4).
- Semua percobaan API `pdfx` (PdfController, PdfView, render thumbnail)
  sudah dicek ulang terhadap dokumentasi resmi paket ini.

## Fix sebelum Phase 3

Ada bug di `importBook()`: judul buku sempat diambil dari nama file hasil
*copy* (`<uuid>.pdf`) alih-alih nama file PDF asli yang dipilih user —
akibatnya search jadi tidak berguna karena judul selalu berupa random
string. Sudah diperbaiki: judul sekarang diambil dari nama file asli
(underscore/dash diganti spasi supaya rapi), sementara file fisik di
storage tetap dinamai UUID (supaya tidak bentrok antar file).

## Phase 3 — Bookmark & Notes

Ditambahkan pada phase ini:

1. **Fitur `bookmarks`** (domain/data/presentation terpisah) — mengelola
   tabel `bookmarks`.
   - Icon bookmark di toolbar Reader sekarang **fungsional**: tap untuk
     menandai halaman yang sedang dibuka, tap lagi untuk menghapusnya
     (toggle). Icon berubah isi/outline sesuai status, dan ada snackbar
     konfirmasi.
   - **Bookmark List screen** (dibuka dari tombol "Bookmarks" di Book
     Detail) — daftar halaman yang di-bookmark, tap salah satu untuk
     langsung membuka reader di halaman itu, ada tombol hapus per item.
2. **Fitur `notes`** (domain/data/presentation terpisah) — mengelola
   tabel `notes`.
   - **Notes screen** (dibuka dari tombol "Notes" di Book Detail) —
     daftar catatan per halaman, tombol **+** untuk menambah catatan baru
     (input nomor halaman + isi catatan, tervalidasi terhadap jumlah
     halaman buku), tap catatan untuk edit, ada tombol hapus per item.
3. Book Detail sekarang menampilkan jumlah bookmark & notes langsung di
   tombolnya, contoh: `Bookmarks (3)`.

### Kenapa Notes tidak ada di toolbar Reader

Spesifikasi awal hanya mencantumkan Bookmark, Table of Contents, Search
Text, dan Settings di toolbar Reader — Notes tidak disebutkan di sana.
Karena menambah catatan butuh input teks yang agak panjang (kurang pas
sebagai aksi sekali-tap di toolbar), fitur ini saya taruh di Notes
screen lewat Book Detail, konsisten dengan bagaimana Book Detail Screen
sudah punya tombol "Notes" di spesifikasi. Kalau kamu mau tombol
tambah-note cepat langsung dari Reader (misal via halaman yang sedang
dibuka), tinggal bilang — bisa ditambahkan.

### Catatan lain

- Table of Contents dan Search Text di toolbar Reader masih placeholder
  ("belum tersedia") — dua ini di luar cakupan Phase 1–3 pada development
  plan awal dan belum dijadwalkan ke phase manapun. Kabari saya kalau mau
  dimasukkan ke salah satu phase berikutnya.

## Phase 4 — Statistics, Settings, Backup

Ditambahkan pada phase ini:

1. **Fitur `statistics`** — agregasi dari tabel `books` + `reading_progress`:
   - **Total books** — jumlah baris di tabel `books`
   - **Pages read** — jumlah `current_page` seluruh buku
   - **Reading time** — akumulasi `total_read_time` (format otomatis jadi
     "X jam Y menit")
   - **Reading streak** — jumlah hari berturut-turut ada aktivitas baca
     (dihitung mundur dari hari ini berdasarkan `last_opened_at`; kalau
     hari ini belum baca tapi kemarin masih ada, streak dianggap belum
     putus supaya tidak balik ke 0 di pagi hari)
2. **Fitur `settings`** — baris tunggal di tabel `settings`:
   - **Dark mode** — langsung mengubah `themeMode` seluruh aplikasi
   - **Default reading mode** — jadi nilai awal reading mode setiap kali
     buka Reader (bisa di-override sementara lewat toolbar reader tanpa
     mengubah default globalnya)
   - **Font size** — diterapkan sebagai `TextScaler` di level
     `MaterialApp` (skala relatif terhadap baseline 16pt), jadi
     memengaruhi ukuran teks UI aplikasi secara keseluruhan
   - **Clear reading history** — hapus semua baris `reading_progress`
     (reset halaman terakhir & waktu baca semua buku; buku, bookmark,
     dan notes tidak ikut terhapus)
   - **Backup database** — trigger export (lihat fitur `backup`)
3. **Fitur `backup`** — export/import `bookreader_backup.zip`:
   - Export: tutup koneksi DB → baca file `bookreader.db` mentah → zip
     jadi `database.sqlite` di dalam `bookreader_backup.zip` → buka lagi
     koneksi DB → user pilih lokasi simpan lewat `file_picker`
   - Import: user pilih file `.zip` → dikonfirmasi dulu (destructive,
     menimpa semua data) → extract `database.sqlite` dari zip → timpa
     file `bookreader.db` → buka ulang koneksi → kembali ke Home dengan
     stack navigasi bersih

### Keputusan & catatan teknis

- **Isi backup**: karena seluruh metadata buku, bookmark, notes, progress,
  dan settings sudah ada di **satu file SQLite** yang sama, backup cukup
  berisi `database.sqlite` saja — otomatis sudah mencakup semuanya sesuai
  spesifikasi ("database.sqlite, metadata buku, bookmark, notes"). File
  PDF & cover asli **tidak** ikut di-backup (supaya ukuran zip tetap
  kecil); kalau kamu mau backup penuh termasuk PDF, saya bisa tambahkan
  opsional itu.
- **Kolom baru**: `default_reading_mode` ditambahkan ke tabel `settings`
  di `database_helper.dart`. Skema awal Phase 1 tidak mencantumkan kolom
  ini padahal Setting screen di spesifikasi butuh field itu — karena app
  belum pernah rilis (masih versi 1), saya tambahkan langsung tanpa perlu
  migrasi.
- **Font size untuk PDF**: seperti dicatat di Phase 2, ukuran font tidak
  memengaruhi isi PDF (dirender sebagai gambar per halaman) — jadi
  setting ini murni untuk ukuran teks UI aplikasi (judul buku, tombol,
  dsb), bukan isi bacaan.
- Dependency baru: **`archive`** (untuk zip/unzip backup).

## Bug fix: overflow saat font size diperbesar

**Laporan**: kartu di Statistics ("Total books", "Pages read", dst)
menampilkan overflow merah "BOTTOM OVERFLOWED BY 1.1 PIXELS" begitu
font size di Setting dinaikkan di atas 16pt.

**Akar masalah**: `GridView` di Statistics & Library dulu pakai
`childAspectRatio` **tetap**. Waktu font size diperbesar (setting ini
diterapkan sebagai `TextScaler` global di `main.dart`), teks di dalam
card butuh tinggi lebih, tapi tinggi sel grid tidak ikut menyesuaikan —
jadi konten "kejepit" dan overflow di sisi bawah.

**Fix** (berlaku di seluruh rentang slider 12–24pt):
1. `childAspectRatio` di **Statistics** dan **Library** sekarang dihitung
   ulang berdasarkan skala teks aktif (`MediaQuery.textScalerOf(context)`),
   jadi sel grid otomatis lebih tinggi saat font diperbesar.
2. Teks di `_StatCard` dan `BookCard` dibungkus `FittedBox(fit:
   BoxFit.scaleDown)` sebagai lapis pengaman kedua — kalau di kombinasi
   device/font tertentu masih kurang, teks itu mengecil otomatis alih-alih
   overflow.
3. Audit menyeluruh nemu **satu bug sejenis lagi** yang belum dilaporkan:
   `SegmentedButton` (Default reading mode) di Setting screen ada di
   `trailing` sebuah `ListTile` yang sempit — di font besar berisiko
   overflow **horizontal**. Dipindah jadi baris penuh di bawah `ListTile`
   (pola sama seperti Font Size), dan dibungkus scroll horizontal sebagai
   pengaman ekstra.
4. Tombol Bookmarks/Notes di Book Detail diganti dari `Row` ke `Wrap`,
   supaya kalau label memanjang di font besar dia pindah baris, bukan
   overflow ke samping.

Sudah dicek: tidak ada lagi `Spacer()` atau `childAspectRatio` statis di
codebase yang berisiko sama.

## Phase 5 — UI polish & animasi

1. **Hero animation** — cover buku bertransisi mulus dari `BookCard` di
   Library ke Book Detail (tag `book-cover-<id>` dipakai di kedua sisi).
2. **Staggered fade-in** (`StaggeredFadeIn`) — item di grid Library
   muncul satu-satu dengan fade + slide-up ringan saat data selesai
   dimuat, bukan muncul serentak.
3. **Splash screen** — logo muncul dengan scale + fade (`Curves.easeOutBack`)
   alih-alih langsung tampil statis.
4. **Progress bar animasi** — `LinearProgressIndicator` di Book Detail
   mengisi dengan animasi (`TweenAnimationBuilder`) alih-alih langsung
   loncat ke nilai akhir.
5. **Reader immersive mode** — tap di halaman PDF untuk
   sembunyikan/tampilkan toolbar & page indicator (mirip Kindle/Google
   Play Books), dengan animasi slide + fade halus, dan `IgnorePointer`
   supaya tap di baliknya tetap tembus ke halaman.
6. **Bookmark icon animasi** — icon bookmark di toolbar reader
   bertransisi dengan scale (`AnimatedSwitcher`) saat toggle, bukan
   langsung berubah.
7. **Transisi antar halaman** — seluruh route sekarang pakai custom
   `PageRouteBuilder` (fade + slide tipis dari kanan, ~260ms
   `easeOutCubic`) menggantikan `MaterialPageRoute` default, supaya
   perpindahan antar screen terasa lebih halus dan konsisten.

### Yang sengaja tidak dikerjakan

- **Efek page-curl** di Reader tetap belum ada. `pdfx`'s `PdfView`
  memakai `PageView` di baliknya (sudah dapat "smooth slide transition"
  gratis), tapi efek melengkung seperti membalik kertas fisik butuh
  custom page-transition renderer / shader yang di luar cakupan
  reasonable untuk package PDF viewer existing — akan butuh reader
  custom dari nol kalau mau efek itu benar-benar akurat. Kalau kamu
  tetap mau saya coba (dengan animasi flip/scale yang menyerupai tapi
  bukan curl fisik asli), tinggal bilang.
- **Table of Contents & Search Text** di toolbar Reader masih
  placeholder — tidak pernah masuk scope eksplisit di phase manapun.

## Status akhir

Development plan awal (Phase 1–5) sudah selesai semua, plus bug fix
overflow font size. Kabari saya kalau ada bug lain atau mau lanjut ke
salah satu item yang sengaja belum dikerjakan di atas.