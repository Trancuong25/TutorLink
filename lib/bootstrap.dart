import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/firebase_config.dart';
import 'core/widgets/status_page.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    const emulator = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    // Android thật dùng google-services.json do người phát triển tự cấu hình.
    await Firebase.initializeApp(
      options: emulator ? emulatorFirebaseOptions : null,
    );
    if (emulator) {
      final host = dotenv.env['EMULATOR_HOST'] ?? '10.0.2.2';
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    }
    runApp(const ProviderScope(child: TutorLinkApp()));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: buildAppTheme(),
        home: StatusPage(
          title: 'Chưa kết nối được Firebase',
          message: 'Kiểm tra cấu hình Firebase và tệp .env theo README, sau đó thử lại.',
          actions: [
            FilledButton(onPressed: bootstrap, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
