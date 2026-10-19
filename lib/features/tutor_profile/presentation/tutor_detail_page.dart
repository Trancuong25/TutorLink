import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../domain/tutor_profile.dart';
import 'tutor_providers.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Hồ sơ gia sư')),
    body: ref
        .watch(tutorProfileProvider(uid))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(tutorProfileProvider(uid)),
              child: const Text('Không xem được hồ sơ. Thử lại'),
            ),
          ),
          data: (p) => p == null
              ? const Center(child: Text('Chưa có hồ sơ gia sư.'))
              : _Details(profile: p),
        ),
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.profile});
  final TutorProfile profile;
  @override
  Widget build(BuildContext context) {
    final p = profile;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(p.displayName, style: Theme.of(context).textTheme.headlineMedium),
        if (p.isMock) const Chip(label: Text('Dữ liệu giả phục vụ nghiên cứu')),
        if (p.isHidden) const Text('Hồ sơ đang bị quản trị viên ẩn.'),
        Text(p.isAvailable ? 'Đang nhận học viên' : 'Tạm ngừng nhận học viên'),
        const SizedBox(height: 16),
        Text(p.bio.isEmpty ? 'Chưa có giới thiệu.' : p.bio),
        const SizedBox(height: 16),
        Text(
          'Môn: ${p.subjects.map((s) => catalog.subjects[s] ?? s).join(', ')}',
        ),
        Text(
          'Cấp học: ${p.levels.map((s) => catalog.levels[s] ?? s).join(', ')}',
        ),
        Text('${NumberFormat.decimalPattern('vi').format(p.hourlyRate)} đ/giờ'),
        Text(catalog.teachingModes[p.teachingMode] ?? p.teachingMode),
        Text(
          p.ratingCount == 0
              ? 'Chưa có đánh giá'
              : '★ ${p.ratingAvg.toStringAsFixed(1)} · ${p.ratingCount} đánh giá',
        ),
        const SizedBox(height: 16),
        const Text('Lịch rảnh (giờ Việt Nam)'),
        Wrap(
          spacing: 8,
          children: (p.availability.toList()..sort())
              .map((s) => Chip(label: Text(catalog.slotLabel(s))))
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(
          p.approxLocation == null
              ? 'Chưa chia sẻ khu vực.'
              : 'Vị trí gần đúng: ${p.approxLocation!.latitude.toStringAsFixed(4)}, ${p.approxLocation!.longitude.toStringAsFixed(4)}\nĐã làm mờ 200–500 m, không phải địa chỉ gặp mặt.',
        ),
      ],
    );
  }
}
