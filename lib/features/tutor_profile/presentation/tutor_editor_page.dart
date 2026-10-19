import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../../../core/errors/auth_error.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../domain/tutor_profile.dart';
import 'tutor_providers.dart';

class TutorEditorPage extends ConsumerWidget {
  const TutorEditorPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(identityProvider).asData?.value?.uid;
    if (uid == null) return const SizedBox.shrink();
    return ref
        .watch(tutorProfileProvider(uid))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(
            appBar: AppBar(title: const Text('Hồ sơ gia sư')),
            body: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(tutorProfileProvider(uid)),
                child: const Text('Không tải được hồ sơ. Thử lại'),
              ),
            ),
          ),
          data: (profile) =>
              _TutorForm(key: ValueKey(uid), uid: uid, initial: profile),
        );
  }
}

class _TutorForm extends ConsumerStatefulWidget {
  const _TutorForm({super.key, required this.uid, this.initial});
  final String uid;
  final TutorProfile? initial;
  @override
  ConsumerState<_TutorForm> createState() => _TutorFormState();
}

class _TutorFormState extends ConsumerState<_TutorForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _bio, _price;
  late final Set<String> _subjects, _levels;
  late final Set<int> _slots;
  late String _mode;
  late bool _available;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.displayName ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
    _price = TextEditingController(text: p?.hourlyRate.toString() ?? '150000');
    _subjects = {...?p?.subjects};
    _levels = {...?p?.levels};
    _slots = {...?p?.availability};
    _mode = p?.teachingMode ?? 'both';
    _available = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final p = TutorProfile(
      uid: widget.uid,
      displayName: _name.text,
      bio: _bio.text,
      subjects: _subjects.toList(),
      levels: _levels.toList(),
      hourlyRate: int.parse(_price.text),
      availability: _slots,
      teachingMode: _mode,
      isAvailable: _available,
    );
    final error = p.validate();
    if (error != null) {
      setState(() => _message = error);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(tutorRepositoryProvider).save(p);
      if (mounted) setState(() => _message = 'Đã lưu hồ sơ.');
    } catch (e) {
      if (mounted) setState(() => _message = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _choices(
    String title,
    Map<String, String> options,
    Set<String> selected,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      Wrap(
        spacing: 8,
        children: options.entries
            .map(
              (e) => FilterChip(
                label: Text(e.value),
                selected: selected.contains(e.key),
                onSelected: _busy
                    ? null
                    : (value) => setState(() {
                        if (value) {
                          selected.add(e.key);
                        } else {
                          selected.remove(e.key);
                        }
                      }),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hồ sơ gia sư')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _name,
            enabled: !_busy,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nhập tên hiển thị.' : null,
          ),
          TextFormField(
            controller: _bio,
            enabled: !_busy,
            maxLength: 2000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Giới thiệu',
              helperText: 'Không ghi địa chỉ nhà hoặc tọa độ chính xác.',
            ),
          ),
          const SizedBox(height: 16),
          _choices('Môn dạy', catalog.subjects, _subjects),
          _choices('Cấp học', catalog.levels, _levels),
          TextFormField(
            controller: _price,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Học phí (đồng/giờ)'),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 50000 || n > 1000000
                  ? 'Nhập học phí 50.000–1.000.000.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _mode,
            decoration: const InputDecoration(labelText: 'Hình thức dạy'),
            items: catalog.teachingModes.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _mode = v!),
          ),
          const SizedBox(height: 20),
          Text(
            'Lịch rảnh hằng tuần',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('Sáng 06–12h · Chiều 12–18h · Tối 18–22h (giờ Việt Nam)'),
          for (var day = 0; day < 7; day++)
            Row(
              children: [
                SizedBox(width: 85, child: Text(catalog.weekDays[day])),
                for (var period = 0; period < 3; period++)
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        catalog.dayPeriods[period],
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _slots.contains(day * 3 + period),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                              if (v == true) {
                                _slots.add(day * 3 + period);
                              } else {
                                _slots.remove(day * 3 + period);
                              }
                            }),
                    ),
                  ),
              ],
            ),
          SwitchListTile(
            title: const Text('Sẵn sàng nhận học viên'),
            value: _available,
            onChanged: _busy ? null : (v) => setState(() => _available = v),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!),
            ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Đang lưu…' : 'Lưu hồ sơ'),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.push('/location'),
            child: const Text('Quản lý vị trí và quyền riêng tư'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => context.push('/tutors/${widget.uid}'),
            child: const Text('Xem hồ sơ công khai'),
          ),
        ],
      ),
    ),
  );
}
