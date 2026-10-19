import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/status_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/session_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'route_guards.dart';
import '../../features/tutor_profile/presentation/tutor_editor_page.dart';
import '../../features/tutor_profile/presentation/tutor_detail_page.dart';
import '../../features/tutor_profile/presentation/tutor_directory_page.dart';
import '../../features/location/presentation/location_page.dart';

final sessionProvider = Provider<Session>((ref) {
  final identity = ref.watch(identityProvider);
  if (identity.hasError) return const Session(SessionStatus.error);
  if (identity.isLoading) return const Session(SessionStatus.loading);
  final user = identity.asData?.value;
  if (user == null) return const Session(SessionStatus.signedOut);
  final profile = ref.watch(profileProvider(user.uid));
  if (profile.hasError) return const Session(SessionStatus.error);
  if (profile.isLoading) return const Session(SessionStatus.loading);
  final account = profile.asData?.value;
  if (account == null) return const Session(SessionStatus.missingProfile);
  // Khóa ưu tiên hơn xác thực email và quyền truy cập theo vai trò.
  if (account.isLocked) return Session(SessionStatus.locked, account.role);
  if (!user.emailVerified) return const Session(SessionStatus.unverified);
  return Session(SessionStatus.ready, account.role);
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider, (_, _) => refresh.refresh());
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (_, state) =>
        routeRedirect(ref.read(sessionProvider), state.uri.path),
    routes: [
      GoRoute(
        path: '/tutor/profile',
        builder: (_, _) => const TutorEditorPage(),
      ),
      GoRoute(path: '/tutors', builder: (_, _) => const TutorDirectoryPage()),
      GoRoute(
        path: '/tutors/:uid',
        builder: (_, state) =>
            TutorDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/location',
        builder: (_, _) => LocationPage(
          isTutor: ref.read(sessionProvider).role == UserRole.tutor,
        ),
      ),
      GoRoute(path: '/login', builder: (_, _) => const AuthPage()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const AuthPage(mode: AuthPageMode.register),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const AuthPage(mode: AuthPageMode.forgotPassword),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (_, _) => const AuthPage(mode: AuthPageMode.completeProfile),
      ),
      GoRoute(
        path: '/loading',
        builder: (_, _) => const StatusPage(
          title: 'Đang tải tài khoản',
          message: 'Vui lòng đợi trong giây lát.',
          loading: true,
        ),
      ),
      for (final path in ['/verify-email', '/locked', '/session-error'])
        GoRoute(
          path: path,
          builder: (_, _) => SessionPage(path: path),
        ),
      for (final role in UserRole.values)
        GoRoute(
          path: homePath(role),
          builder: (_, _) => HomePage(role: role),
        ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
