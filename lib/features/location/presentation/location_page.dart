import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_error.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../tutor_profile/presentation/tutor_providers.dart';
import '../domain/location_point.dart';
import 'location_providers.dart';

class LocationPage extends ConsumerStatefulWidget {
  const LocationPage({super.key, required this.isTutor});
  final bool isTutor;
  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  final _form = GlobalKey<FormState>();
  final _area = TextEditingController(),
      _lat = TextEditingController(),
      _lon = TextEditingController();
  bool _busy = false, _manual = false;
  String? _message;
  @override
  void dispose() {
    _area.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is StateError ? e.message : authErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(LocationSelection selection) async {
    if (widget.isTutor) {
      final uid = ref.read(identityProvider).asData!.value!.uid;
      await ref.read(tutorRepositoryProvider).saveLocation(uid, selection);
    } else {
      ref.read(searchLocationProvider.notifier).select(selection);
    }
    if (mounted) {
      setState(
        () => _message = widget.isTutor
            ? 'Đã lưu vị trí. Hồ sơ chỉ hiển thị vị trí gần đúng.'
            : 'Đã chọn khu vực tìm kiếm cho phiên này.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(identityProvider).asData?.value?.uid;
    final profile = widget.isTutor && uid != null
        ? ref.watch(tutorProfileProvider(uid))
        : null;
    final canSave = !widget.isTutor || profile?.asData?.value != null;
    final locked =
        uid != null &&
        ref.watch(profileProvider(uid)).asData?.value?.isLocked == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền riêng tư vị trí')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.location_on_outlined, size: 56),
          const SizedBox(height: 16),
          Text(
            'Bạn quyết định chia sẻ vị trí',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            widget.isTutor
                ? 'TutorLink sử dụng tọa độ để giúp người học tìm gia sư gần họ. Khi đồng ý lưu, tọa độ gốc được lưu riêng trên Firebase; chỉ tài khoản của bạn được đọc qua ứng dụng. Hồ sơ hiển thị vị trí đã làm mờ, lệch khoảng 200–500 m. Dữ liệu được giữ đến khi bạn xóa vị trí.'
                : 'TutorLink dùng vị trí để tìm gia sư gần bạn. Vị trí tìm kiếm chỉ lưu tạm trong bộ nhớ của phiên đăng nhập, không đưa lên Firestore.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Không thu thập vị trí nền. Bạn có thể từ chối GPS và nhập khu vực thủ công. Làm mờ không bảo đảm ẩn danh tuyệt đối. Không nhập địa chỉ nhà vào phần giới thiệu công khai.',
          ),
          if (widget.isTutor)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Bạn có thể thu hồi đồng ý bên dưới: xóa vị trí riêng và gần đúng. Hồ sơ vẫn tồn tại nhưng không tham gia tìm kiếm theo khoảng cách.',
              ),
            ),
          if (!canSave)
            const Text('Hãy tạo và lưu hồ sơ gia sư trước khi lưu vị trí.'),
          if (profile?.hasError == true)
            TextButton(
              onPressed: () => ref.invalidate(tutorProfileProvider(uid!)),
              child: const Text('Tải lại hồ sơ'),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy || !canSave || locked
                ? null
                : () => _run(() async {
                    final selection = await ref
                        .read(deviceLocationProvider)
                        .requestOnce();
                    await _save(selection);
                  }),
            child: Text(
              widget.isTutor
                  ? 'Đồng ý lấy và lưu vị trí một lần'
                  : 'Đồng ý dùng vị trí một lần',
            ),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => setState(() => _manual = true),
            child: const Text('Từ chối GPS — nhập khu vực'),
          ),
          if (_manual)
            Form(
              key: _form,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn khu vực mẫu hoặc nhập tên khu vực cùng tọa độ tâm. Không cần tọa độ nhà ở.',
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            _area.text = 'Phú Lợi, TP.HCM';
                            _lat.text = '10.9804';
                            _lon.text = '106.6666';
                          },
                    child: const Text('Chọn tâm Phú Lợi, TP.HCM'),
                  ),
                  TextFormField(
                    controller: _area,
                    enabled: !_busy,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Tên phường/quận, khu vực',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Nhập khu vực.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lat,
                    enabled: !_busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Vĩ độ tâm khu vực',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || !n.isFinite || n.abs() > 60
                          ? 'Vĩ độ hợp lệ từ -60 đến 60.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lon,
                    enabled: !_busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Kinh độ tâm khu vực',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || !n.isFinite || n.abs() > 180
                          ? 'Kinh độ hợp lệ từ -180 đến 180.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy || !canSave || locked
                        ? null
                        : () {
                            if (_form.currentState!.validate()) {
                              _run(
                                () => _save(
                                  LocationSelection(
                                    LocationPoint(
                                      double.parse(_lat.text),
                                      double.parse(_lon.text),
                                    ),
                                    'manual',
                                    _area.text.trim(),
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(
                      widget.isTutor
                          ? 'Đồng ý lưu tâm khu vực'
                          : 'Dùng khu vực này',
                    ),
                  ),
                ],
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          if (_message != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_message!)),
          const Divider(),
          OutlinedButton(
            onPressed: _busy || !canSave
                ? null
                : () => _run(() async {
                    if (widget.isTutor) {
                      await ref
                          .read(tutorRepositoryProvider)
                          .revokeLocation(uid!);
                    } else {
                      ref.read(searchLocationProvider.notifier).select(null);
                    }
                    if (mounted) {
                      setState(
                        () => _message =
                            'Đã xóa vị trí đã lưu và thu hồi đồng ý.',
                      );
                    }
                  }),
            child: const Text('Xóa vị trí / Thu hồi đồng ý'),
          ),
        ],
      ),
    );
  }
}
