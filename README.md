# PetPal

PetPal is a Flutter application for ios/Android designed to help pet owners manage their pets' profiles, appointments, and activities. This repository contains the base Flutter project with backend structure and SQLite integration prepared for further development.

![image alt](https://github.com/WSU-4110/PetPal/blob/9693d87b89620dd0548ea3a2ea38c571458e90d9/read.jpg)

---

## Features
- Create and manage multiple pet profiles.  
- Log detailed medical records, including medications, vet visits, and diagnoses.  
- Track appointments (vet, grooming, training) with date, time, and purpose.  
- Record daily exercise logs for activity tracking and health insights.  
- Maintain grooming logs and support groomer-specific roles.  
- Set reminders for medications, feeding, grooming, vet visits, and custom tasks.  
- Generate weekly reports and notifications based on activity and logs.   
- Authenticate users with a clean and simple login screen.  
- Use interactive dialogs for adding/editing reminders and medical records.  
- Offer an easy-to-use app drawer for navigation and quick actions.  
- Ensure responsive UI across iOS, Android, macOS, and web platforms.

---

## Getting Started

Follow these steps to set up and run the project on your system.

### 1. Prerequisites
- Install **Flutter SDK**: [Flutter installation guide](https://docs.flutter.dev/get-started/install)  
- Install **Git**: [Git installation](https://git-scm.com/downloads)  
- Install an IDE (recommended: [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio))  
- Make sure you have either:
  - **Android Studio + Emulator** (for Android testing)  
  - **Xcode + Simulator** (for iOS testing on macOS only)  
  - Or connect a **physical device** via **USB**  

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
│
│-- lib/
│   │-- main.dart                      # App entry point
│   │-- main_nav.dart                  # Bottom navigation / main routing
│   │
│   │-- state/
│   │   └─ app_state.dart              # Global state (pets, reminders, records, roles)
│   │
│   │-- models/                        # All data models
│   │   ├─ pet.dart                    # Pet model
│   │   ├─ medical_record.dart         # Pet medical records
│   │   ├─ groom_log.dart              # Grooming logs
│   │   ├─ exercise_log.dart           # Exercise tracking
│   │   ├─ appointment.dart            # Appointments for pets
│   │   ├─ notification.dart           # Notifications & weekly reports
│   │   ├─ reminder.dart               # Reminders
│   │   ├─ pet_access.dart             # Role-based access per pet
│   │   └─ ...                         # Additional models
│   │
│   │-- services/
│   │   └─ db_service.dart             # Local SQLite or Hive database service
│   │
│   │-- ui/                            # All UI screens & widgets
│   │   ├─ home_screen.dart            # Home for default role
│   │   ├─ health_screen.dart          # Pet health overview
│   │   ├─ medical_records.dart        # Medical records page
│   │   ├─ login_page.dart             # Login screen
│   │   ├─ pet_list_screen.dart        # List of pets
│   │   ├─ pet_form_screen.dart        # Add/edit pet form
│   │   ├─ reminder_list_screen.dart   # Reminder list UI
│   │   ├─ add_medical_record_dialog.dart
│   │   ├─ add_reminder_dialog.dart
│   │   ├─ edit_reminder_dialog.dart
│   │   ├─ app_drawer.dart             # Navigation drawer
│   │   └─ ...                         # Additional screens 
│
│-- assets/
│   └─ images/
│       └─ petlogo.png                 # App logo & image assets
│
│-- android/                            # Android platform files
│-- ios/                                # iOS platform files
│-- macos/                              # macOS support
│-- web/                                # Web build support
│-- test/                               # Unit & widget tests
│
│-- pubspec.yaml                        # Dependencies & asset declarations
│-- pubspec.lock                        # Locked dependency versions
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
