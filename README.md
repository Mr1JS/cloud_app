# Cloud Storage App

A simple cloud storage app built with Flutter and Supabase. Upload files, take photos, and access them from anywhere.

**Name:** Jatin Saroay  
**Course:** Konzepte der Android-Programmierung - AI1276 (WiSe25/26)

## Features

- Sign up and login with email/password or Google account
- Upload multiple files at once
- Take photos with your camera and upload them directly
- Preview images and PDFs in the app
- Download and share files
- Organize files in folders
- Search through your files
- Profile picture customization
- Storage overview showing what types of files you have
- Works on mobile, web, and desktop
- Dark mode support

## What I Used

**Main stuff:**
- Flutter for the UI
- Supabase for backend (auth and storage)
- GetX for state management

**Important packages:**
- `supabase_flutter` - connects to Supabase
- `google_sign_in` - Google login
- `camera` - camera access for taking photos
- `file_picker` - selecting files from device
- `syncfusion_flutter_pdfviewer` - viewing PDFs
- `share_plus` - sharing files
- `download` - downloading files
- `get` - state management
- `primer_progress_bar` - storage visualization
- `http` - file operations
- `flutter_dotenv` - managing environment variables

## Setup

### What you need:
- Flutter 3.10 or newer
- A Supabase account (free)
- Google Cloud project (for Google login)

### 1. Install

```bash
git clone https://github.com/Mr1JS/cloud_app
cd cloud_app
flutter pub get
```

### 2. Supabase Setup

Create a `.env` file:
```env
url=YOUR_SUPABASE_PROJECT_URL
anonKey=YOUR_SUPABASE_ANON_KEY
```

In your Supabase project:
- Create a storage bucket called `userdata` (make it public)
- Enable Email and Google auth providers

### 3. Google Sign In

Get credentials from Google Cloud Console and update `lib/Services/auth_service.dart`:
```dart
static const String webClientId = 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com';
static const String iosClientId = 'YOUR-IOS-CLIENT-ID.apps.googleusercontent.com';
```

For iOS, add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Cloud App needs camera access to take and upload photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cloud App needs photo library access to select photos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Explanation on why the microphone access is needed.</string>
```

For Android, set `minSdkVersion` to 21 in `android/app/build.gradle`.

### 4. Run

```bash
flutter run -d chrome  # web
flutter run -d ios     # iOS
flutter run -d android # Android
```

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── Screens/
│   ├── Auth/                    # Login and signup screens
│   ├── Camera/                  # Camera screen
│   └── Home/                    # Main app screens
│       ├── Controller/          # Business logic
│       └── Widgets/             # Reusable components
├── Services/
│   ├── auth_service.dart        # Authentication
│   └── storage_service.dart     # File storage
└── Themes/
    └── ui_theme.dart            # Light/dark themes
```

## How It Works

When you open the app, it checks if you're logged in. If not, you see the login page. After logging in (email or Google), you get to the home screen where you can upload files.

Files are stored in Supabase under `userId/folder/filename`, so each user only sees their own files. You can take photos directly in the app or upload existing files. The camera works on both mobile and web.

The app has separate layouts for mobile and web to make the best use of screen space. Everything syncs with Supabase in real-time, so if you log in from another device, your files are there.


## Security

- **Row Level Security (RLS):** Configure in Supabase to restrict file access per user
- **API Keys:** Never commit `.env` file (add to `.gitignore`)
- **Google OAuth:** Client secrets stored securely in Google Cloud
- **File paths:** User ID prefix prevents unauthorized access


## Troubleshooting

### Common Issues

**Google Sign In not working on Web:**
- Check if redirect URLs are configured in Supabase Dashboard
- Verify Web Client ID is correct in `auth_service.dart`
- Ensure browser allows popups

**Camera not working:**
- **iOS:** Check `Info.plist` has camera permissions
- **Android:** Verify `minSdkVersion` is 21+
- **Web:** Must use HTTPS or localhost

**Files not uploading:**
- Check Supabase Storage bucket exists and is named `userdata`
- Verify bucket is public or RLS policies allow upload
- Check network connection

**Build errors:**
- Run `flutter clean && flutter pub get`
- Check Flutter version: `flutter --version` (requires 3.10+)
- Update dependencies: `flutter pub upgrade`


## License

This project is created for educational purposes as part of the "Konzepte der Android-Programmierung" course.


## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Supabase](https://supabase.com/) - Backend infrastructure
- [GetX](https://pub.dev/packages/get) - State management
- [Syncfusion](https://www.syncfusion.com/flutter-widgets) - PDF Viewer

---