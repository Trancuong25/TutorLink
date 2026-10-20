import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/features/auth/domain/entities/app_user.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutorlink/features/home/presentation/pages/home_page.dart';

void main() {
  for (final role in UserRole.values) {
    testWidgets('trang chủ ${role.name} không báo thiếu dữ liệu giả', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            identityProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(home: HomePage(role: role)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(role.label), findsOneWidget);
      expect(find.text('Chưa có dữ liệu'), findsNothing);
    });
  }
}
