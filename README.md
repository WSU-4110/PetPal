# PetPal

PetPal is a cross-platform Flutter application designed to help pet owners manage their pets' profiles, appointments, and activities. This repository contains the base Flutter project with backend structure and SQLite integration prepared for further development.

---

## Features (Planned)
- Create and manage multiple pet profiles.  
- Log health records, appointments, and exercise.  
- Connect with veterinarians, groomers, and trainers.  
- Local storage support using SQLite for offline access.  
- Extensible backend structure for integration with APIs and cloud services.  

---

## Getting Started

Follow these steps to set up and run the project on your system.

### 1. Prerequisites
- Install **Flutter SDK**: [Flutter installation guide](https://docs.flutter.dev/get-started/install)  
- Install **Git**: [Git installation](https://git-scm.com/downloads)  
- Install an IDE (recommended: [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio))  
- Make sure you have either:
  - **Android Studio + Emulator** (for Android testing)  
  - **Xcode** (for iOS testing on macOS only)  
  - Or connect a physical device via USB  

Verify installation with:
```bash
flutter doctor
```
### 2. Clone the Repository
```bash
git clone https://github.com/WSU-4110/PetPal.git
cd petpal
```
### 3. Install Dependencies
```bash
Run this inside the project folder:
flutter pub get
```
4. Run the App
On Android (Emulator or Device)
- Start Android Studio Emulator, or plug in your Android device with USB debugging enabled.
- Run:
```bash
flutter run
```
On iOS (Mac only)
- Install Xcode from the Mac App Store.
- Set up CocoaPods (if not already):
```bash
sudo gem install cocoapods
```
- Run:
```bash
flutter run
```
On Windows/Linux (Desktop)
Enable desktop support:
```bash
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```
Then run:
```bash
flutter run -d windows   # for Windows
flutter run -d linux     # for Linux
```

---

### Project Structure
```bash
petpal/
│-- lib/                # Main Dart source files
│   │-- main.dart       # App entry point
│   │-- backend/        # Backend services & SQLite setup
│   │-- ui/             # Frontend UI code
│
│-- pubspec.yaml        # Project configuration & dependencies
│-- android/            # Android-specific files
│-- ios/                # iOS-specific files
│-- web/                # Web support
│-- test/               # Unit & widget tests
```

---

### Contribution Guidelines
Work on feature branches, not directly on main.
Use clear commit messages.
Submit pull requests for review before merging.

---

### Helpful Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/)
