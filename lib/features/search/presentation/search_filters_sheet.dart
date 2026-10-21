import 'package:flutter/material.dart';

import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../domain/search_models.dart';

class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({super.key, required this.initial});
  final SearchRequest initial;
  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  final form = GlobalKey<FormState>();
  late String subject;
  String? level, mode;
  late double radius;
  late Set<int> slots;
  late bool requireLevel, requireBudget, requireSchedule;
  late TextEditingController budget;
  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    subject = r.subject;
    level = r.level;
    mode = r.mode;
    radius = r.radiusKm;
    slots = {...r.slots};
    requireLevel = r.requireLevel;
    requireBudget = r.requireBudget;
    requireSchedule = r.requireSchedule;
    budget = TextEditingController(text: r.budget?.toString() ?? '');
  }

  @override
  void dispose() {
    budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bộ lọc và mong muốn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            DropdownButtonFormField<String>(
              initialValue: subject,
              decoration: const InputDecoration(
                labelText: 'Môn học (bắt buộc)',
              ),
              items: catalog.subjects.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => subject = v!),
            ),
            DropdownButtonFormField<String>(
              initialValue: level,
              decoration: const InputDecoration(labelText: 'Cấp học mong muốn'),
              items: [
                const DropdownMenuItem<String>(child: Text('Chưa chọn')),
                ...catalog.levels.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => setState(() => level = v),
            ),
            SwitchListTile(
              title: const Text('Chỉ hiện đúng cấp học'),
              value: requireLevel,
              onChanged: (v) => setState(() => requireLevel = v),
            ),
            TextFormField(
              controller: budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách tối đa (đ/giờ, có thể bỏ trống)',
              ),
              validator: (v) =>
                  (v ?? '').isEmpty ||
                      (int.tryParse(v!) != null &&
                          int.parse(v) > 0 &&
                          int.parse(v) <= 100000000)
                  ? null
                  : 'Nhập ngân sách nguyên dương, tối đa 100 triệu.',
            ),
            SwitchListTile(
              title: const Text('Chỉ hiện trong ngân sách'),
              value: requireBudget,
              onChanged: (v) => setState(() => requireBudget = v),
            ),
            Text('Bán kính ${radius.round()} km'),
            Slider(
              value: radius,
              min: 1,
              max: 10,
              divisions: 9,
              label: '${radius.round()} km',
              onChanged: (v) => setState(() => radius = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: mode,
              decoration: const InputDecoration(labelText: 'Hình thức dạy'),
              items: const [
                DropdownMenuItem<String>(child: Text('Không giới hạn')),
                DropdownMenuItem(value: 'offline', child: Text('Trực tiếp')),
                DropdownMenuItem(value: 'online', child: Text('Trực tuyến')),
                DropdownMenuItem(
                  value: 'both',
                  child: Text('Có cả hai hình thức'),
                ),
              ],
              onChanged: (v) => setState(() => mode = v),
            ),
            const SizedBox(height: 12),
            const Text('Lịch mong muốn · sáng / chiều / tối'),
            for (var day = 0; day < 7; day++)
              Row(
                children: [
                  SizedBox(width: 70, child: Text(catalog.weekDays[day])),
                  for (var period = 0; period < 3; period++)
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          catalog.dayPeriods[period],
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: slots.contains(day * 3 + period),
                        onChanged: (v) => setState(
                          () => v == true
                              ? slots.add(day * 3 + period)
                              : slots.remove(day * 3 + period),
                        ),
                      ),
                    ),
                ],
              ),
            SwitchListTile(
              title: const Text('Chỉ hiện gia sư trùng tất cả buổi đã chọn'),
              value: requireSchedule,
              onChanged: (v) => setState(() => requireSchedule = v),
            ),
            const Text(
              'Khi tắt lọc bắt buộc, cấp học/ngân sách/lịch vẫn là mong muốn để chấm mức phù hợp.',
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    SearchRequest(
                      subject: subject,
                      level: level,
                      budget: int.tryParse(budget.text),
                      slots: slots,
                      radiusKm: radius,
                      mode: mode,
                      requireLevel: requireLevel,
                      requireBudget: requireBudget,
                      requireSchedule: requireSchedule,
                    ),
                  );
                }
              },
              child: const Text('Áp dụng'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, const SearchRequest()),
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ),
    ),
  );
}
