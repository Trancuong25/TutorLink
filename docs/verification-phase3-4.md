# Bàn giao GĐ3–GĐ4 — 21/10/2026

## Checkpoint

- GĐ3: commit `fadd7d0`, analyze sạch và 35/35 Flutter test đạt trước khi làm GĐ4.
- GĐ4: package Dart thuần, đọc cấu hình Firestore, giao diện hai chế độ và giải thích.
- Index mới đã deploy và truy vấn thực thành công sau khi hết BUILDING.
- Rules config đã deploy; tạo config mặc định chỉ khi chưa tồn tại, không ghi đè khảo sát/AHP.

## Kết quả kiểm thử tự động

- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: 38/38 đạt (cả GĐ1–GĐ4).
- Package `dart analyze`: không có vấn đề; `dart test`: 10/10 đạt.
- Firebase Emulator: 27/27 đạt, gồm quyền config và seed giữ nguyên trọng số AHP có sẵn.
- Widget kiểm chứng đổi chế độ đổi thứ tự và hiện/ẩn giải thích, không tăng số lần tải ứng viên.
- Haversine giữa bộ lọc và ranking được kiểm tra giống hệt để tránh sai lệch tập tại biên R.
- APK debug build thành công với mã cuối cùng. File: `build/app/outputs/flutter-apk/app-debug.apk` (không commit binary lên Git).
- Kiểm tra một tile OSM tại vùng mẫu trả HTTP 200, image/png và Cache-Control. Đây không thay thế kiểm thử render/cache trên Android.
- SDK Platform 35 và CMake 3.22.1 được Gradle cài từ Android SDK trong lần build. Còn cảnh báo tương thích Kotlin/SDK tooling từ dependency, không làm build thất bại.

## Firebase thật

Project `tutorlink-a4ef5`, Spark, không Cloud Functions, không Google Maps/billing. Đo từ máy tính tới Firestore production (Node Firestore SDK, truy vấn cùng index, prefix sinh bằng hàm Dart của app), trên bộ 150 mock, môn Toán, tâm Phú Lợi:

| R | Số kết quả | Range | Documents đọc | Ba lần đo (ms) |
|---|---:|---:|---:|---|
| 1 km | 3 | 2 | 22 | 1488, 466, 397 |
| 2 km | 24 | 4 | 34 | 325, 424, 314 |
| 5 km | 34 | 1 | 47 | 432, 353, 294 |
| 10 km | 47 | 2 | 47 | 379, 395, 360 |

Các lần đo đều <2 giây trên máy/mạng này. Không coi đây là SLA trên Android hoặc mạng di động. Thời gian gồm query + lọc/sort; chưa gồm tải tile bản đồ.

Kiểm chứng client Firebase SDK bằng learner thử trên production: đọc ranking config, bị chặn sửa config, truy vấn môn/geohash thành công. Cùng kiểm tra hồi quy quyền/vị trí: 14/14 đạt. Hai Auth user tạm và documents thử đã cleanup; không đổi tài khoản của người dùng.

So sánh package Dart với 47 ứng viên thực tế từ tập mock công khai: Toán/THPT, ngân sách 150.000, lịch {2,5,8,11}, R=10 km, C≈3,9936. Tính cả hai chế độ khoảng 18 ms trên máy tính.

- Gần nhất: mock_010, mock_101, mock_055, mock_092, mock_135, mock_124, mock_004, mock_119, mock_056, mock_137.
- Phù hợp nhất: mock_004, mock_066, mock_042, mock_110, mock_082, mock_009, mock_103, mock_007, mock_091, mock_124.
- Lý do đứng đầu: khớp môn/cấp, trùng 3/4 buổi, cách 1,3 km gần đúng, học phí vượt ngân sách, rating 4,9 với 98 lượt. Ngân sách ở ca này là mong muốn, không bật lọc bắt buộc.

## Chưa kiểm thử trên thiết bị

ADB không có điện thoại kết nối trong đợt GĐ3–GĐ4. Chưa xác nhận GPS, tile/cache, cluster, nhấn marker, thay đổi bộ lọc và hai chế độ trên Note9. Không dùng thành công GĐ2 để suy ra GĐ3–GĐ4 đã chạy trên thiết bị. Chưa chạy integration_test Android trong đợt này.

Khi kết nối lại: cài APK mới, đăng nhập **Người học** (tài khoản Gia sư không có route tìm kiếm), chọn Phú Lợi, chọn Toán và tăng R 1→10 km; chuyển danh sách/bản đồ, bấm marker, mở hồ sơ; chọn cấp/ngân sách/lịch rồi so hai chế độ. Kiểm tra cache bằng mở lại vùng đã xem, thử mất mạng và khôi phục mạng. Không bật bộ lọc cứng ngân sách/lịch nếu muốn nghiên cứu ảnh hưởng của các điểm mềm này.

## Giới hạn nghiên cứu

- Chỉ dùng vị trí đã làm mờ; sai số vị trí ảnh hưởng việc lọc biên và thứ tự gần nhất.
- Tối đa 100 documents mỗi range, 100 kết quả trả về; ở tập dày có thể bị cắt. UI cảnh báo và hai chế độ dùng cùng tập bị cắt.
- Tile công cộng OSM không có SLA; cấu hình được URL/User-Agent, cache đĩa theo HTTP, không bulk download.
- Trọng số hiện là khởi đầu. C cần cập nhật quản trị khi dữ liệu đánh giá thay đổi.
