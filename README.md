# Smart Reader 📚

A beautiful, feature-rich document reader app built with Flutter. Smart Reader provides an intelligent reading experience with PDF support, bookmarks, reading progress tracking, and a premium UI.

## ✨ Features

- **📖 Multi-format Support** – Read PDFs, text files, and markdown documents
- **🔖 Smart Bookmarks** – Save pages with notes for quick reference
- **📊 Reading Stats** – Track your reading progress and streaks
- **🎨 Customizable Reader** – Adjust font size, line spacing, and choose from 4 reader themes (Dark, Light, Sepia, AMOLED)
- **🌙 Dark/Light Mode** – Full theme support with gorgeous UI
- **📁 Library Management** – Organize documents with categories, favorites, and search
- **🔍 Smart Search** – Find documents instantly by title or author
- **✨ Smooth Animations** – Polished micro-animations throughout the app

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/     # App-wide constants
│   ├── theme/         # Colors & theme configuration
│   └── utils/         # Database helper & utilities
├── models/            # Data models (Document, Bookmark, ReadingStats)
├── providers/         # State management (Theme, Document, ReaderSettings)
├── screens/
│   ├── splash/        # Animated splash screen
│   ├── onboarding/    # 3-page onboarding flow
│   ├── home/          # Dashboard with stats & recent docs
│   ├── library/       # Document library with grid/list views
│   ├── reader/        # PDF & text reader with settings
│   ├── search/        # Real-time document search
│   ├── bookmarks/     # Bookmark management
│   └── settings/      # App settings & preferences
└── widgets/           # Reusable UI components
```

## 🛠️ Tech Stack

- **Flutter 3.38.6** with Material 3
- **Provider** for state management
- **SQLite** (sqflite) for local persistence
- **Syncfusion PDF Viewer** for PDF rendering
- **Google Fonts** for Poppins typography
- **Flutter Animate** for smooth animations
- **SharedPreferences** for settings persistence

## 🚀 Getting Started

```bash
# Clone the repository
git clone <repo-url>

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 Screenshots

Coming soon...

## 📄 License

This project is open source and available under the MIT License.
