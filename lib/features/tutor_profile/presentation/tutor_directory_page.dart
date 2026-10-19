import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'tutor_providers.dart';

// Danh mục để mở hồ sơ GĐ2; tìm kiếm/ranking được triển khai ở GĐ3–4.
class TutorDirectoryPage extends ConsumerWidget {
  const TutorDirectoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Hồ sơ gia sư')),
    body: ref
        .watch(tutorDirectoryProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(tutorDirectoryProvider),
              child: const Text('Không tải được danh sách. Thử lại'),
            ),
          ),
          data: (profiles) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tutorDirectoryProvider);
              await ref.read(tutorDirectoryProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (profiles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có hồ sơ gia sư.'),
                  ),
                for (final p in profiles)
                  ListTile(
                    title: Text(p.displayName),
                    subtitle: Text(
                      p.isAvailable ? 'Đang nhận học viên' : 'Tạm ngừng',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/tutors/${p.uid}'),
                  ),
              ],
            ),
          ),
        ),
  );
}
