# Kiểm thử lại GĐ1–GĐ2 — 21/10/2026

## Tự động

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 29/29 đạt.
- `npm run test:rules`: 24/24 đạt trên Firestore Emulator, gồm seed 150 hồ sơ và cleanup.
- Lần chạy trong sandbox bị chặn truy cập Flutter SDK/Java; chạy lại ngoài sandbox thành công.

## Samsung Galaxy Note9 (SM-N960F), APK debug hiện có

- Khởi động lại ứng dụng: giữ phiên đăng nhập, vào đúng trang Gia sư.
- Lưu lại hồ sơ hiện có: nhận “Đã lưu hồ sơ.”
- Xem hồ sơ công khai: hiển thị đúng môn, cấp, học phí và lịch rảnh.
- Mở quyền riêng tư vị trí, từ chối GPS: hiện biểu mẫu khu vực thủ công.
- Gửi biểu mẫu trống: chặn với lỗi khu vực, vĩ độ và kinh độ.
- Chọn tâm Phú Lợi và lưu: nhận thông báo lưu vị trí thành công.
- Thu hồi vị trí mẫu: nhận “Đã xóa vị trí đã lưu và thu hồi đồng ý.”
- Log được kiểm tra trong lượt thử hồ sơ không có lỗi Flutter/Firestore hoặc crash.

## Giới hạn và việc còn lại

- Đây là kiểm tra giao diện và phản hồi SDK; chưa đọc trực tiếp dữ liệu production để đối chiếu tọa độ công khai/riêng tư.
- Chưa thử GPS thật, quyền bị từ chối vĩnh viễn, GPS tắt, mất mạng, hoặc hai tài khoản trên thiết bị thật.
- Quyền truy cập và độ lệch 200–500 m được kiểm tra bởi bộ test tự động; không suy ra Rules production giống Rules trong repo.
- Vị trí mẫu trên tài khoản người dùng được thu hồi sau thử nghiệm.

## Hoàn thiện tiếp trong ngày 21/10/2026

- Đã bỏ dòng “Chưa có dữ liệu” cố định; cập nhật ba widget test trang chính tương ứng.
- Đã deploy Rules và hai indexes lên `tutorlink-a4ef5`; lệnh đọc indexes xác nhận cả hai cấu hình.
- Seed production thành công: đếm được 150 tutor mock và 150 private location mock.
- Dùng phiên OAuth Firebase CLI đã được chủ dự án cấp quyền, không tạo hoặc lưu khóa service account mới.
- 11 kiểm tra production bằng client Firebase SDK: chặn tự nâng quyền; chặn sửa isLocked; tạo hồ sơ tutor; chặn learner sửa tutor; chặn sửa rating; lưu batch private/public; đối chiếu khoảng cách 200–500 m; owner đọc private; learner bị chặn đọc private; learner đọc public; thu hồi xóa private và đặt public location null.
- Dùng hai Auth user tạm riêng biệt, không sửa dữ liệu tài khoản người dùng cho bộ kiểm tra production; cả hai Auth user và tài liệu thử đã được xóa trong bước cleanup.
- Các lỗi PERMISSION_DENIED ở những ca kiểm tra bị chặn là kết quả mong đợi.
- Sau sửa giao diện: analyze sạch, 29/29 Flutter test đạt, build APK debug thành công.
- Cài đè APK mới lên Note9 thành công; mở lại giữ đúng phiên Gia sư và không còn dòng “Chưa có dữ liệu”.
- Đã push mã nguồn lên repository riêng tư https://github.com/Trancuong25/TutorLink (nhánh master).
- API key, google-services.json, firebase_options.dart, .env và các script vận hành OAuth tạm trong .tools không được đưa lên Git.

## File thay đổi trong đợt hoàn thiện

- `.gitignore`: bỏ qua cache Kotlin.
- `android/gradle.properties`: giữ tùy chọn `kotlin.incremental=false` do người dùng thêm.
- `firebase.json`: giữ metadata FlutterFire do người dùng cấu hình cho project thật.
- `lib/features/home/presentation/pages/home_page.dart`: bỏ thông báo thiếu dữ liệu cố định.
- `test/features/home/home_page_test.dart`: cập nhật kỳ vọng giao diện.
- `README.md`, `docs/phase2.md`, `docs/verification-2026-10-21.md`: cập nhật trạng thái triển khai và bằng chứng kiểm thử.
