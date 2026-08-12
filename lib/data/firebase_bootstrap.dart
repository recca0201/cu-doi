import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';
import '../firebase_options_emulator.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult._(this.enabled, this.emulator);
  const FirebaseBootstrapResult.guest() : this._(false, false);
  const FirebaseBootstrapResult.connected({required bool emulator})
    : this._(true, emulator);
  final bool enabled;
  final bool emulator;
}

class FirebaseBootstrap {
  static const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const bool enableProduction = bool.fromEnvironment(
    'ENABLE_FIREBASE_PRODUCTION',
  );
  static Future<FirebaseBootstrapResult> initialize() async {
    if (!useEmulator && !enableProduction) {
      return const FirebaseBootstrapResult.guest();
    }
    if (enableProduction && !useEmulator) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      return const FirebaseBootstrapResult.connected(emulator: false);
    }
    await Firebase.initializeApp(options: emulatorFirebaseOptions);
    FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    await FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
    FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
    return const FirebaseBootstrapResult.connected(emulator: true);
  }
}
