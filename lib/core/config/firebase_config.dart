import 'package:firebase_core/firebase_core.dart';

// Sau flutterfire configure, truyền DefaultFirebaseOptions.currentPlatform
// từ firebase_options.dart vào Firebase.initializeApp trong bootstrap.dart.
FirebaseOptions get emulatorFirebaseOptions => const FirebaseOptions(
  apiKey: 'demo-key',
  appId: '1:123456789:android:demo',
  messagingSenderId: '123456789',
  projectId: 'demo-tutorlink',
);
