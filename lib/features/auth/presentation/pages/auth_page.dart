import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_providers.dart';

enum AuthPageMode { login, register, forgotPassword, completeProfile }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.mode = AuthPageMode.login});
  final AuthPageMode mode;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  UserRole _role = UserRole.learner;
  bool _busy = false, _obscure = true;
  String? _error, _notice;
  bool get _profile => widget.mode == AuthPageMode.completeProfile;
  bool get _register => widget.mode == AuthPageMode.register;
  bool get _reset => widget.mode == AuthPageMode.forgotPassword;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      switch (widget.mode) {
        case AuthPageMode.login:
          await repo.signIn(_email.text, _password.text);
        case AuthPageMode.register:
          await repo.register(_name.text, _email.text, _password.text, _role);
        case AuthPageMode.completeProfile:
          await repo.completeProfile(_name.text, _role);
          await repo.sendVerification();
        case AuthPageMode.forgotPassword:
          await repo.resetPassword(_email.text);
          if (mounted) {
            setState(
              () => _notice = 'Nếu email đã được đăng ký, bạn sẽ nhận được liên kết đặt lại mật khẩu.',
            );
          }
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _profile
        ? 'Hoàn tất hồ sơ'
        : _register
        ? 'Tạo tài khoản'
        : _reset
        ? 'Quên mật khẩu'
        : 'Đăng nhập';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TutorLink',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kết nối tri thức, gần bạn hơn',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      if (_register || _profile) ...[
                        TextFormField(
                          controller: _name,
                          enabled: !_busy,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Nhập họ và tên.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<UserRole>(
                          initialValue: _role,
                          decoration: const InputDecoration(
                            labelText: 'Bạn là',
                          ),
                          items: [UserRole.learner, UserRole.tutor]
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _role = v!),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_profile) ...[
                        TextFormField(
                          key: const Key('email'),
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch((v ?? '').trim())
                              ? null
                              : 'Nhập email hợp lệ.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_reset && !_profile) ...[
                        TextFormField(
                          key: const Key('password'),
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _obscure,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) => (v ?? '').isEmpty
                              ? 'Nhập mật khẩu.'
                              : _register && v!.length < 8
                              ? 'Dùng ít nhất 8 ký tự.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_notice != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(_notice!),
                        ),
                      FilledButton(
                        key: const Key('submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_reset ? 'Gửi liên kết đặt lại' : title),
                      ),
                      if (widget.mode == AuthPageMode.login) ...[
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => context.go('/forgot-password'),
                          child: const Text('Quên mật khẩu?'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => context.go('/register'),
                          child: const Text('Chưa có tài khoản? Đăng ký'),
                        ),
                      ] else if (!_profile)
                        TextButton(
                          onPressed: _busy ? null : () => context.go('/login'),
                          child: const Text('Về đăng nhập'),
                        ),
                      if (_profile)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    ref.read(authRepositoryProvider).signOut(),
                          child: const Text('Đăng xuất'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
