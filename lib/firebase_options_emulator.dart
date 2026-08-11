import 'package:firebase_core/firebase_core.dart';

/// Non-secret deterministic options used only with Local Emulator Suite.
const FirebaseOptions emulatorFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:1234567890:android:demo',
  messagingSenderId: '1234567890',
  projectId: 'demo-cu-doi',
  storageBucket: 'demo-cu-doi.appspot.com',
);
