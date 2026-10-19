import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';

import '../../../../core/errors/auth_error.dart';
import '../../../../core/widgets/status_page.dart';
import '../controllers/auth_providers.dart';

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key, required this.path});
  final String path;
  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  bool _busy = false;
  String? _message;
  Future<void> _run(Future<void> Function() task, [String? message]) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await task();
      if (mounted) setState(() => _message = message);
    } catch (e) {
      if (mounted) setState(() => _message = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(authRepositoryProvider);
    final verify = widget.path == '/verify-email';
    final locked = widget.path == '/locked';
    final uid = ref.watch(identityProvider).asData?.value?.uid;
    final role = uid == null
        ? null
        : ref.watch(profileProvider(uid)).asData?.value?.role;
    return StatusPage(
      title: verify
          ? 'Xác thực email'
          : locked
          ? 'Tài khoản đã bị khóa'
          : 'Không thể tải tài khoản',
      message:
          _message ??
          (verify
              ? 'Mở liên kết trong email xác thực, sau đó nhấn “Tôi đã xác thực”. Bạn có thể gửi lại nếu chưa nhận được thư.'
              : locked
              ? 'Vui lòng liên hệ quản trị viên để được hỗ trợ.'
              : 'Kiểm tra kết nối mạng và thử tải lại.'),
      loading: _busy,
      actions: [
        if (locked && role == UserRole.tutor)
          TextButton(
            onPressed: () => context.push('/location'),
            child: const Text('Thu hồi chia sẻ vị trí'),
          ),
        if (verify) ...[
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                    repo.reloadIdentity,
                    'Nếu chưa xác thực, hãy kiểm tra thư đến và thư rác.',
                  ),
            child: const Text('Tôi đã xác thực'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(repo.sendVerification, 'Đã gửi email xác thực.'),
            child: const Text('Gửi lại email'),
          ),
        ],
        if (!verify && !locked)
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    final uid = ref.read(identityProvider).asData?.value?.uid;
                    if (uid != null) ref.invalidate(profileProvider(uid));
                    ref.invalidate(identityProvider);
                  },
            child: const Text('Thử lại'),
          ),
        TextButton(
          onPressed: _busy ? null : () => _run(repo.signOut),
          child: const Text('Đăng xuất'),
        ),
      ],
    );
  }
}
