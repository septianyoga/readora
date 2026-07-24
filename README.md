![Readora Banner](screenshots/banner.png)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.35-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Platform](https://img.shields.io/badge/Android-12%2B-green?logo=android)
![Material](https://img.shields.io/badge/Material%203-UI-purple)
![Offline](https://img.shields.io/badge/Offline-First-orange)
![License](https://img.shields.io/badge/License-MIT-brightgreen)

</div>

# 📚 Readora

> **Read. Remember. Continue.**

<p align="center"> Readora is a modern offline ebook reader built with Flutter that transforms PDF reading into a comfortable and intelligent experience. Organize your personal library, continue exactly where you left off, monitor your reading habits through beautiful analytics, and enjoy a distraction-free reading experience — all without an internet connection. </p>

---

## ✨ Features

### 📚 Smart Library

* Import unlimited PDF books
* Beautiful library management
* Book detail page
* Reading progress tracking
* Continue reading instantly

### 📖 Premium Reading Experience

* Smooth page transition
* Automatic last-page history
* Bookmark important pages
* Comfortable reading interface
* Dark mode ready

### 📊 Reading Analytics

* Total Books
* Pages Read
* Reading Time
* Reading Streak
* Daily / Weekly / Monthly / Yearly statistics
* Reading activity trend
* Reading calendar
* Reading goals
* Top books
* Reading habits
* Reading achievements

### 🔒 Offline First

* No account required
* No internet connection required
* Local storage
* Privacy friendly

---

## 📱 Application Preview

| Splash Screen                                  | Library                                         |
| ---------------------------------------------- | ----------------------------------------------- |
| <img src="screenshots/splash.png" width="260"> | <img src="screenshots/library.png" width="260"> |

| Book Detail                                    | Reading Page                                   |
| ---------------------------------------------- | ---------------------------------------------- |
| <img src="screenshots/detail.png" width="260"> | <img src="screenshots/reader.png" width="260"> |

| Reading Statistics                                 | Settings                                         |
| -------------------------------------------------- | ------------------------------------------------ |
| <img src="screenshots/statistics.png" width="260"> | <img src="screenshots/settings.png" width="260"> |

---

## 🛠 Built With

* Flutter
* Dart
* Riverpod
* SQLite
* File Picker
* PDFX
* FlChart

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── router/
│   └── utils/
│
├── features/
│   ├── backup/
│   ├── bookmarks/
│   ├── books/
│   ├── notes/
│   ├── reader/
│   ├── reading_goal/
│   ├── settings/
│   └── statistics/
│
└── main.dart
```

## 🌟 Why Readora?

Unlike traditional PDF readers, Readora is designed as a personal reading companion rather than just a document viewer.

It remembers your reading journey, tracks your habits, visualizes your progress with beautiful analytics, and helps you build a consistent reading routine.

Whether you're reading programming books, novels, research papers, or self-improvement books, Readora keeps everything organized in one elegant offline experience.

---

## 🚀 Getting Started

### Clone the repository

```bash
git clone https://github.com/septianyoga/readora.git
```

---

### Go to project

```bash
cd readora
```

---

### Install dependencies

```bash
flutter pub get
```

---

### Run the application

```bash
flutter run
```

---

## 📦 Build Release APK

```bash
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Build Android App Bundle

```bash
flutter build appbundle --release
```

AAB output:

```text
build/app/outputs/bundle/release/app-release.aab
```

---

## 📋 Requirements

* Flutter 3.x+
* Dart SDK
* Android Studio / Android SDK
* JDK 17

Verify your environment:

```bash
flutter doctor
```

---

## 🎯 Roadmap

* [ ] EPUB support
* [ ] Reading goals
* [ ] Highlight & notes
* [ ] Full-text search
* [ ] Cloud backup
* [ ] Reading streak
* [ ] Collections
* [ ] Reading timer
* [ ] Custom themes
* [ ] Tablet optimization

---

## 🤝 Contributing

Contributions are welcome.

Feel free to open an Issue or submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

Developed with ❤️ by **Septian Abiyoga**

If you like this project, consider giving it a ⭐ on GitHub.
