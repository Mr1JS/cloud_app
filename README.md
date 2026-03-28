# Cloud Storage App

A simple cloud storage app built with Flutter and Supabase. Upload files, take photos, and access them from anywhere.

**Name:** Jatin Saroay  
**Course:** Konzepte der Android-Programmierung - AI1276 (WiSe25/26)

## Features

- Sign up and login with email/password or Google account
- Upload multiple files at once (mobile: native picker, web: drag & drop)
- Take photos with your camera and upload them directly
- Preview images, PDFs, and text/code files in the app
- Download and share files
- Organize files in custom folders
- Search through your files and folders
- Profile picture customization (camera, gallery, or drag & drop on web)
- Storage overview showing file type breakdown (images, docs, videos, other)
- Recent uploads sidebar showing your last 3 files
- Unique filename resolution (no accidental overwrites)
- Adaptive layout for mobile and web
- Dark mode support (follows system theme)
- 50 MB per-file upload limit with user feedback

## What I Used

**Main stuff:**
- Flutter for the UI
- Supabase for backend (auth and storage)
- GetX for state management and navigation

**Packages:**
- `supabase_flutter` — Supabase client (auth + storage)
- `google_sign_in` — native Google login on Android/iOS
- `flutter_dotenv` — loading environment variables from `.env`
- `camera` — in-app camera for taking photos
- `file_picker` — selecting files from device (mobile)
- `flutter_dropzone` — drag & drop file uploads (web only)
- `dotted_border` — styled drop zone border
- `syncfusion_flutter_pdfviewer` — PDF preview
- `share_plus` — sharing file public links
- `download` — downloading files on web (blob download)
- `file_saver` — native save-as dialog for downloading files on mobile
- `path_provider` — resolving temp directory on mobile
- `open_file` — opening downloaded files with the system app
- `get` — GetX state management
- `primer_progress_bar` — storage type visualization bar
- `http` — checking if profile image URL exists

## Setup

### Requirements
- Flutter 3.10 or newer
- A Supabase account (free tier works)
- Google Cloud project (for Google login)

### 1. Clone & Install

```bash
git clone https://github.com/Mr1JS/cloud_app
cd cloud_app
flutter pub get
```

### 2. Environment Variables

Create `assets/.env`:
```env
url=YOUR_SUPABASE_PROJECT_URL
anonKey=YOUR_SUPABASE_ANON_KEY
webClientId=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
iosClientId=YOUR_IOS_CLIENT_ID.apps.googleusercontent.com
androidClientId=YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com
```

Make sure `assets/.env` is listed in `pubspec.yaml` under `flutter > assets`.

### 3. Supabase Setup

In your Supabase project:
- Create a storage bucket called `userdata` (make it public)
- Enable **Email** and **Google** auth providers
- Configure RLS policies on the `userdata` bucket so users can only access their own files (path prefix: `userId/`)

### 4. Google Sign-In

**Web:** Add your app's origin and redirect URL to the OAuth credentials in Google Cloud Console and to Supabase's redirect URL allowlist.

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Cloud App needs camera access to take and upload photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cloud App needs photo library access to select photos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Cloud App requests microphone access as required by the camera plugin.</string>
<!-- Google Sign-in Section -->
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>{YOUR_GOOGLE_CLOUD_IOS_CLIENT_ID}</string>
			</array>
		</dict>
	</array>
<!-- End of the Google Sign-in Section -->
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>UIFileSharingEnabled</key>
<true/>
```

### 5. PDF Viewer (Web only)

In `web/index.html`, add this inside the `<body>` tag before `</body>`:
```html
<!-- PDF.js (required for Syncfusion PDF viewer on web) -->
<script type="module" async="">
  import * as pdfjsLib from 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.9.155/pdf.min.mjs';
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.9.155/pdf.worker.min.mjs";
</script>
```

> Without this, PDF preview will silently fail on web.

### 6. Run

```bash
flutter run -d chrome --web-hostname localhost  # web
flutter run -d ios                              # iOS
flutter run -d android                          # Android
```

## Project Structure

```
lib/
├── main.dart                        # Entry point, auth stream, routing
├── Screens/
│   ├── Auth/
│	│   ├── login_page.dart          # Login screen
│	│   ├── signup_page.dart         # Signup screen
│	│	├── Utils/
│	│	│   └── validators.dart		 # Shared form validators
│	│   ├── Widgets/
│	│   │   └── login_signup_page.dart   # Shared login/signup form widget
│   │   └── PasswordReset/
│   │       ├── forgot_password_page.dart	# Enter email, request OTP
│   │       ├── verify_otp_page.dart		# Enter 6-digit OTP
│   │       └── reset_password_page.dart	# Set new password
│   ├── Camera/
│   │   └── camera_screen.dart       # In-app camera (mobile + web)
│   └── Home/
│       ├── home_page.dart           # Root home screen + upload dialog
│       ├── mobile_body.dart         # Mobile layout wrapper
│       ├── web_body.dart            # Web layout wrapper
│       ├── Controller/
│       │   └── home_controller.dart # GetX controller (files, auth, dialogs)
│       └── Widgets/
│           ├── avatar_widget.dart   # Profile avatar with edit button
│           ├── drag_and_drop_widget.dart # Web drag & drop (flutter_dropzone)
│           ├── file_item.dart       # FileItem model with type helpers
│           ├── file_system_manager.dart  # Tree builder + search expansion
│           ├── home_shared_ui.dart  # Shared UI (drawer, file list, search)
│           ├── preview_dialog.dart  # Image / PDF / text file preview
│           ├── profile_dialog.dart  # User profile popup
│           ├── search_bar.dart      # Search controller wrapper
│           └── storage_bar_delegate.dart # Sliver header delegate
├── Services/
│   ├── auth_service.dart            # Email + Google auth via Supabase
│   └── storage_service.dart         # Upload, download, list, URL helpers
└── Themes/
    └── ui_theme.dart                # Material 3 light/dark themes
```

## How It Works

On launch, `main.dart` listens to Supabase's auth state stream. If no session exists the user sees the login page; once authenticated they land on the home screen.

Files are stored in Supabase under `userId/folder/filename`, so each user only sees their own files. The `FileSystemManager` builds a virtual folder tree from the flat list returned by Supabase and handles search-triggered folder expansion automatically.

The upload dialog lets you queue multiple files before uploading — you can mix files picked from the device, drag & dropped on web, and photos taken with the camera. Before uploading, `resolveUniqueFilename` checks for name collisions and appends a counter if needed.

The sidebar shows a storage type breakdown (via `primer_progress_bar`) and your three most recent uploads. The layout switches between a drawer-based mobile view and a persistent side-panel web view at 700 px width.

## Security

- **Row Level Security (RLS):** Configure in Supabase so each user can only read/write under their own `userId/` prefix
- **Environment variables:** Never commit `assets/.env` — add it to `.gitignore`
- **Google OAuth:** Client secrets stay in Google Cloud; only client IDs are in the app
- **File paths:** The `userId` prefix in every storage path prevents cross-user access

## Troubleshooting
 
**Google Sign-In not working on Web:**
- Check that your redirect URL is added in both Supabase Dashboard and Google Cloud Console
- Verify `webClientId` in `assets/.env` is correct
- Ensure the browser allows popups from localhost
 
**Camera not working:**
- iOS: confirm `Info.plist` has all three permission keys above
- Android: confirm `minSdkVersion` is 21+
- Web: must run on `https://` or `localhost`
 
**Files not uploading:**
- Confirm the Supabase bucket is named exactly `userdata`
- Check that the bucket is public or that RLS policies allow uploads
- Files over 50 MB are silently skipped with a snackbar — check file size
 
**Download not working on mobile:**
- iOS: confirm `Info.plist` has `LSSupportsOpeningDocumentsInPlace` and `UIFileSharingEnabled` set to `true`
- The native save-as dialog (via `file_saver`) opens automatically — no extra permissions needed
- On web, files download directly to the browser's default download location

**PDF preview not working on web:**
- Make sure the PDF.js script is added to `web/index.html` inside `<body>` (see step 4)
- Check browser console for `pdfjsLib` errors
- Must use the exact version (`4.9.155`) that matches your `syncfusion_flutter_pdfviewer` version
 
 
```bash
flutter clean && flutter pub get
flutter --version   # requires 3.10+
```
 
## License
 
Created for educational purposes as part of the "Konzepte der Android-Programmierung" course.
 
## Acknowledgments
 
- [Flutter](https://flutter.dev/) — UI framework
- [Supabase](https://supabase.com/) — Backend & storage
- [GetX](https://pub.dev/packages/get) — State management
- [Syncfusion](https://www.syncfusion.com/flutter-widgets) — PDF Viewer
- [flutter_dropzone](https://pub.dev/packages/flutter_dropzone) — Web drag & drop