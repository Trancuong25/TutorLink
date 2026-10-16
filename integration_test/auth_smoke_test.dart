import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tutorlink/bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('khởi động với Firebase Emulator và mở quên mật khẩu', (
    tester,
  ) async {
    await bootstrap();
    // Chờ hữu hạn vì stream Firebase có thể giữ frame đang hoạt động.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byKey(const Key('email')).evaluate().isNotEmpty) break;
    }
    expect(find.text('TutorLink'), findsOneWidget);
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi liên kết đặt lại'), findsOneWidget);
  });
}
