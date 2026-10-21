# Kiểm nghiệm trên điện thoại — 21/10/2026

Thiết bị: Samsung Galaxy Note9 (SM-N960F), Android 10. ADB đã nhận thiết bị và quyền USB debugging. Mã ứng dụng kiểm tra: efebd6b (sửa review), quy trình bàn giao a665506. Không ghi thông tin đăng nhập trong báo cáo.

## Chuẩn bị

- Người dùng xác nhận chưa có tài khoản để thử; bắt đầu bằng đăng ký vai trò Người học trên thiết bị.
- APK debug mới build thành công (295 giây), đã cài bằng adb install -r, trả Success; không uninstall/clear data.
- Mở MainActivity trả Status: ok, tiến trình ứng dụng đang chạy. Đây chỉ xác nhận khởi động, chưa xác nhận các luồng nghiệp vụ. Log lỗi của tiến trình tại lần kiểm tra đầu không có FATAL EXCEPTION/Unhandled Exception/permission-denied/RenderFlex overflowed.
- Bộ check đầu: analyze sạch, Flutter 38/38, ranking 13/13; Rules 30/31, một test khóa tài khoản timeout 5 giây khi chạy cùng build. Chạy lại toàn bộ sau khi build kết thúc, không sửa test/code để bỏ lỗi.
- Lần chạy lại scripts/check.bat sau build đạt exit code 0 (khoảng 22:00, Asia/Saigon): Flutter/Dart analyze sạch, Flutter 38/38, ranking 13/13, Rules 31/31. Emulator đã dừng. Không thay đổi code hoặc timeout của test.

## Các ca thử trực tiếp

Chỉ đánh dấu đạt khi có bằng chứng thiết bị hoặc người dùng xác nhận. Kết quả unit/widget/Rules không thay thế cột này.

| Giai đoạn | Ca thử | Kết quả trên thiết bị |
|---|---|---|
| GĐ1 | Đăng ký Người học, nhận email xác thực, đăng nhập | Chờ thử |
| GĐ1 | Đăng xuất/đăng nhập lại, quên mật khẩu | Chờ thử |
| GĐ1 | Phân vai trò và phản ứng khi khóa tài khoản thử | Chờ thử; không khóa tài khoản chính |
| GĐ2 | Tạo/sửa hồ sơ gia sư, validate môn/cấp/giá/lịch, bật/tắt nhận học | Chờ thử với tài khoản Gia sư riêng |
| GĐ2 | Quyền GPS, từ chối/nhập thủ công, thu hồi vị trí gia sư | Chờ thử |
| GĐ3 | Người học chọn tâm Phú Lợi thủ công, Toán, bán kính 1–10 km | Chờ thử |
| GĐ3 | Bộ lọc môn/cấp/giá/lịch, trường hợp không có kết quả | Chờ thử |
| GĐ3 | Bản đồ, marker/cluster, mở hồ sơ, chuyển lại danh sách | Chờ thử |
| GĐ3 | Mất mạng/thử lại và quan sát thời gian tìm kiếm | Chờ thử |
| GĐ4 | Chuyển Gần nhất/Phù hợp nhất, thứ tự và giải thích | Chờ thử |
| GĐ4 | Chọn/bỏ lịch, ngân sách và cấp; điểm/giải thích tương ứng | Chờ thử |

Để có dữ liệu mẫu dễ đối chiếu, dùng “Từ chối GPS — nhập khu vực” → “Chọn tâm Phú Lợi, TP.HCM” → “Dùng khu vực này”. Đây là tâm tìm kiếm tạm thời của Người học, không sửa vị trí gia sư.

GĐ5–GĐ6 chưa triển khai, không nằm trong đợt kiểm nghiệm này. Chưa có kết luận toàn bộ GĐ1–GĐ4 đạt trên thiết bị.
