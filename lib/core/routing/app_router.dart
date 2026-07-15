import 'package:flutter/material.dart';

import '../../features/bookmarks/presentation/screens/bookmark_list_screen.dart';
import '../../features/books/presentation/screens/book_detail_screen.dart';
import '../../features/books/presentation/screens/home_shell.dart';
import '../../features/books/presentation/screens/splash_screen.dart';
import '../../features/notes/presentation/screens/notes_screen.dart';
import '../../features/reader/presentation/screens/reader_screen_loader.dart';

/// Nama-nama route aplikasi. Sengaja disentralisasi di satu tempat
/// supaya tidak ada "magic string" tersebar di berbagai screen.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const bookDetail = '/book-detail';
  static const reader = '/reader';
  static const bookmarkList = '/bookmarks';
  static const notes = '/notes';

  // Route berikut akan diaktifkan pada phase selanjutnya:
  // static const statistics = '/statistics';
  // static const settings = '/settings';
}

/// Argumen untuk route [AppRoutes.reader].
class ReaderScreenArgs {
  final String bookId;
  final int startPage;

  const ReaderScreenArgs({required this.bookId, required this.startPage});
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeShell());
      case AppRoutes.bookDetail:
        final bookId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: bookId),
        );
      case AppRoutes.bookmarkList:
        final bookId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BookmarkListScreen(bookId: bookId),
        );
      case AppRoutes.notes:
        final bookId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => NotesScreen(bookId: bookId),
        );
      case AppRoutes.reader:
        final args = settings.arguments as ReaderScreenArgs;
        return MaterialPageRoute(
          builder: (_) => ReaderScreenLoader(
            bookId: args.bookId,
            startPage: args.startPage,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }
}