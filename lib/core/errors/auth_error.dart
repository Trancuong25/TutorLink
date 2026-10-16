import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email hoặc mật khẩu chưa đúng.',
      'email-already-in-use' =>
        'Email này đã được đăng ký. Hãy đăng nhập hoặc đặt lại mật khẩu.',
      'invalid-email' => 'Địa chỉ email không hợp lệ.',
      'weak-password' => 'Mật khẩu chưa đủ mạnh.',
      'too-many-requests' =>
        'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau.',
      'network-request-failed' ||
      'unavailable' => 'Không thể kết nối. Kiểm tra mạng và thử lại.',
      'permission-denied' => 'Không có quyền thực hiện thao tác này.',
      'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
      _ => 'Không thể hoàn tất thao tác. Vui lòng thử lại.',
    };
  }
  return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
}
