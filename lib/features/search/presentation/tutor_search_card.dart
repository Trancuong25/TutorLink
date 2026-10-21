import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../domain/search_models.dart';

class TutorSearchCard extends StatelessWidget {
  const TutorSearchCard({super.key, required this.hit, this.explanation});
  final SearchHit hit;
  final Widget? explanation;
  @override
  Widget build(BuildContext context) {
    final t = hit.tutor;
    return Card(
      child: InkWell(
        onTap: () => context.push('/tutors/${t.uid}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (t.isMock) const Text('Dữ liệu mô phỏng'),
              Text(t.subjects.map((s) => catalog.subjects[s] ?? s).join(', ')),
              Text(t.levels.map((s) => catalog.levels[s] ?? s).join(', ')),
              Text(
                '${NumberFormat.decimalPattern('vi').format(t.hourlyRate)} đ/giờ'
                ' · ${hit.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km (gần đúng)',
              ),
              Text(
                t.ratingCount == 0
                    ? 'Chưa có đánh giá'
                    : '★ ${t.ratingAvg.toStringAsFixed(1)} (${t.ratingCount} lượt)',
              ),
              const Text('Đang nhận học viên'),
              ?explanation,
            ],
          ),
        ),
      ),
    );
  }
}
