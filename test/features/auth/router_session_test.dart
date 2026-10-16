import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tutorlink/app/app.dart';
import 'package:tutorlink/features/auth/domain/entities/app_user.dart';
import 'package:tutorlink/features/auth/domain/repositories/auth_repository.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('router phản ứng với khóa và mở khóa từ Firestore', (
    tester,
  ) async {
    final profiles = StreamController<AppUser?>();
    addTearDown(profiles.close);
    final repo = MockAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          identityProvider.overrideWith(
            (ref) =>
                Stream.value(const AuthIdentity('u', 'u@example.com', true)),
          ),
          profileProvider('u').overrideWith((ref) => profiles.stream),
        ],
        child: const TutorLinkApp(),
      ),
    );
    await tester.pump();
    const profile = AppUser(
      uid: 'u',
      email: 'u@example.com',
      displayName: 'An',
      role: UserRole.learner,
      isLocked: false,
    );
    profiles.add(profile);
    await tester.pumpAndSettle();
    expect(find.text('Xin chào, An'), findsOneWidget);
    profiles.add(
      const AppUser(
        uid: 'u',
        email: 'u@example.com',
        displayName: 'An',
        role: UserRole.learner,
        isLocked: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản đã bị khóa'), findsOneWidget);
    expect(find.text('Xin chào, An'), findsNothing);
    profiles.add(profile);
    await tester.pumpAndSettle();
    expect(find.text('Xin chào, An'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
