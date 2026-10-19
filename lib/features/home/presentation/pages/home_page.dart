import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(identityProvider).asData?.value?.uid;
    final profile = uid == null
        ? null
        : ref.watch(profileProvider(uid)).asData?.value;
    final (icon, title, description) = switch (role) {
      UserRole.learner => (
        Icons.search,
        'Tìm người đồng hành học tập',
        'Danh sách gia sư và tìm kiếm theo vị trí sẽ có ở giai đoạn 3.',
      ),
      UserRole.tutor => (
        Icons.school_outlined,
        'Chia sẻ kiến thức của bạn',
        'Cập nhật môn dạy, học phí, lịch rảnh và khu vực của bạn.',
      ),
      UserRole.admin => (
        Icons.admin_panel_settings_outlined,
        'Quản trị TutorLink',
        'Duyệt tài khoản, báo cáo và log thực nghiệm sẽ có ở giai đoạn 6.',
      ),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('TutorLink'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Xin chào, ${profile?.displayName ?? 'bạn'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(role.label)),
          ),
          const SizedBox(height: 28),
          if (role == UserRole.tutor)
            FilledButton(
              onPressed: () => context.push('/tutor/profile'),
              child: const Text('Tạo / sửa hồ sơ gia sư'),
            ),
          if (role == UserRole.learner) ...[
            FilledButton(
              onPressed: () => context.push('/tutors'),
              child: const Text('Xem hồ sơ gia sư'),
            ),
            TextButton(
              onPressed: () => context.push('/location'),
              child: const Text('Chọn khu vực tìm kiếm'),
            ),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
