# Barcode Billing

Flutter barcode billing app with Firebase Authentication, Provider state
management, cart billing, bill history, and light/dark UI.

## Run the app

Use the nested Flutter project folder:

```powershell
cd D:\barcodescanner\barcode
flutter pub get
flutter run
```

On Windows, Flutter plugins may ask for Developer Mode so desktop plugin
symlinks can be created. Enable it from Windows Settings if `flutter pub get`
prints the Developer Mode message.

## Firebase Authentication

Android is configured with `android/app/google-services.json` for Firebase
project `barcode-scanner-f32fe`. Email/password auth and Google auth must also
be enabled in the Firebase Console.

The app still accepts Firebase settings from Dart defines, which is useful for
web builds or for overriding the checked-in Android project values.

Example web run:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=your_api_key `
  --dart-define=FIREBASE_APP_ID=your_app_id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id `
  --dart-define=FIREBASE_PROJECT_ID=your_project_id `
  --dart-define=FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
```

For Android Google sign-in, make sure the Firebase Android app uses package
`com.example.barcode` and has this machine/app's SHA fingerprints registered.
