# GĐ2 — Hồ sơ gia sư và vị trí

**Cập nhật 21/10/2026:** đã deploy Rules/index và seed 150 gia sư trên Firebase thật; 11 kiểm tra production đạt. Các kết quả ngày 19/10 bên dưới là lịch sử trước triển khai. Xem [báo cáo mới nhất](verification-2026-10-21.md).

GĐ1 được giữ nguyên; thêm route và nút mở feature, quyền Android, Rules/index và geolocator 14.1.1. Không có Cloud Functions, không yêu cầu Blaze. Đây là Flutter thuần; không khởi tạo hoặc đồng bộ một dự án FlutterFlow khác.

## Cách dùng

- Gia sư: trang chính → Tạo / sửa hồ sơ → chọn môn/cấp/lịch → Lưu hồ sơ.
- Công tắc nhận học viên được áp dụng khi nhấn **Lưu hồ sơ**.
- Quản lý vị trí: đồng ý lấy GPS một lần, hoặc từ chối GPS và nhập khu vực.
- Có nút chọn tâm Phú Lợi theo tọa độ đề bài. Khu vực khác nhập tên và tọa độ tâm; chưa có geocoding hay bản đồ ở GĐ2, không âm thầm dùng tâm mặc định cho địa danh không biết.
- Người học: Xem hồ sơ gia sư → trang chỉ đọc, chưa có gửi yêu cầu. Danh mục giới hạn 150 hồ sơ, chưa phải tìm kiếm GĐ3.
- Người học chọn vị trí chỉ lưu RAM, tự xóa khi đổi tài khoản hoặc đóng app.
- Thu hồi đồng ý xóa private location và hai trường tọa độ công khai bằng một batch. Gia sư bị khóa vẫn có nút thu hồi từ màn khóa.

## Schema

`tutors/{uid}`: các trường theo đề bài, thêm `isHidden: bool` (admin quản lý). `approxLocation` và `geohash` là null khi chưa chia sẻ/đã thu hồi. `ratingAvg=0`, `ratingCount=0`, `isMock=false`, `isHidden=false` khi client tạo hồ sơ.

`availability` là list số nguyên duy nhất từ 0 đến 20; trong domain là Set<int>. Slot = ngày × 3 + buổi; thứ hai=0, sáng=0, chiều=1, tối=2. Các khoảng: sáng 06–12h, chiều 12–18h, tối 18–22h, giờ Việt Nam. GĐ4 tính Jaccard bằng giao/hợp hai tập. Chọn ít nhất một buổi.

Danh mục dùng chung của Flutter: `lib/core/constants/tutor_catalog.dart`. Khi mở rộng mã, cập nhật allowlist trong Rules và bộ dữ liệu seed tương ứng.

`private_locations/{uid}`: `location` (GeoPoint), `source` (gps/manual), `consentVersion=location-v1`, `updatedAt` server timestamp. Với manual, location là tâm do người dùng chọn, không phải GPS. Seed dùng `isMock=true` và consentVersion=mock-only qua Admin SDK; không giả vờ có sự đồng ý của người thật.

## Làm mờ và giới hạn

Module Dart thuần sử dụng lưới khoảng 400 m theo phép chiếu tham chiếu vĩ độ 11°, jitter cố định theo UID, chọn tâm ứng viên có khoảng cách Haversine 200–500 m. Tọa độ công khai nằm trên tập tâm rời rạc; geohash **6 ký tự chỉ mã hóa tọa độ công khai**. Hàm hỗ trợ vĩ độ -60 đến 60, gồm toàn Việt Nam.

Cùng UID **và cùng đầu vào** cho cùng kết quả. Thay đổi vị trí phải thay đổi khu vực công khai; không thể yêu cầu cùng UID luôn ra một điểm trên toàn thế giới mà vẫn giữ độ lệch 200–500 m.

Không có phép biến đổi cố định theo UID công khai nào bảo đảm tuyệt đối “không suy ngược”: có thể suy ra khu vực, kết hợp thông tin phụ hoặc nhiều lần cập nhật. Đây là giảm độ chính xác, không phải mã hóa/differential privacy. Không ghi địa chỉ nhà vào bio; không dùng điểm công khai làm địa chỉ gặp mặt.

Rules bảo vệ quyền đọc/ghi và tính nguyên tử, chặn công khai điểm trùng GPS. Rules không chứng minh GPS thật, không kiểm tra đúng thuật toán hash/lưới hoặc tính geohash từ tọa độ. Client bị sửa có thể khai báo vị trí giả; gói Spark không có backend tin cậy để xác minh thiết bị.

Chỉ owner đọc private qua SDK client, kể cả admin ứng dụng cũng bị chặn; Admin SDK/service account vẫn có quyền hạ tầng. Rules tutors đọc hồ sơ không ẩn cho người đăng nhập; owner/admin vẫn đọc hồ sơ ẩn. Tutor không tự gỡ ẩn hoặc sửa rating/isMock. Admin khóa qua users.isLocked như GĐ1 và ẩn qua tutors.isHidden + updatedAt.

Luồng đồng ý nêu mục đích, dữ liệu, lưu trữ, từ chối và thu hồi theo yêu cầu đề bài tham chiếu [NĐ13/2023](https://chinhphu.vn/default.aspx?docid=207759&pageid=27160). Tại thời điểm triển khai còn có [NĐ356/2025 hiệu lực 01/01/2026](https://vanban.chinhphu.vn/?docid=216387&pageid=27160). Nguyên mẫu không phải chứng nhận tuân thủ pháp lý đầy đủ; trước thu thập dữ liệu thật cần bổ sung đơn vị chịu trách nhiệm, liên hệ và chính sách lưu trữ/chuyển dữ liệu thực tế của đơn vị nghiên cứu.

## Seed và dọn dữ liệu

Giữ emulator chạy với `npm run emulators`, terminal khác:

```powershell
node scripts/seed/seed.js --emulator
node scripts/seed/seed.js --emulator --clean
```

Chạy Firebase thật (chưa thực hiện trong GĐ2):

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\Secrets\tutorlink-admin.json'
node scripts/seed/seed.js --project <project-id>
# Lệnh sau xóa các tài liệu isMock trong tutors và private_locations của project đã chọn.
node scripts/seed/seed.js --project <project-id> --clean
Remove-Item Env:\GOOGLE_APPLICATION_CREDENTIALS
```

Service account bắt buộc ngoài repo. --emulator chỉ dùng localhost:8080 và demo-tutorlink, không dùng credential thật. Chế độ thật từ chối chạy nếu FIRESTORE_EMULATOR_HOST còn được đặt.

Seed xorshift32=20261019; 150 UID mock_001…mock_150; 300 tài liệu trong một batch, không tạo Auth users. Chạy lại tái lập thuộc tính/vị trí, updatedAt thay đổi theo lần chạy. Từ chối ghi đè ID có isMock khác true. Cleanup có phân trang, chỉ xóa tài liệu isMock=true ở hai collection và giữ dữ liệu thật.

Kết quả CLI Emulator:
- 150 gia sư; khoảng cách 0–2km: 68, 2–5km: 46, 5–10km: 36 (tính từ vị trí giả gốc).
- Học phí 80–<150k: 43; 150–<220k: 50; 220–300k: 57.
- Môn: Toán 57, Hóa 62, Tin 57, Văn 55, Lý 48, Anh 56, Sinh 51. Một gia sư có nhiều môn.

## Chạy và kiểm tra

Kết quả ngày 19/10/2026:

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 29/29 đạt, gồm 10.000 mẫu độ lệch vị trí, biên tọa độ, route guard, widget hồ sơ và từ chối GPS/chọn manual/thu hồi vị trí trong RAM.
- `npm run test:rules`: 24/24 đạt (16 test users GĐ1, 7 test tutor/private Rules, 1 test seed/cleanup).
- CLI `node scripts/seed/seed.js --emulator`: thành công; thống kê ở trên. Test cleanup xác nhận xóa 300 tài liệu mock và giữ tài liệu thật mẫu.
- Chưa chạy lại GĐ2 trên thiết bị thật, chưa deploy Rules/index hoặc seed lên Firebase thật.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
npm run test:rules
npx firebase deploy --only firestore:rules,firestore:indexes --project <project-id>
```

Deploy Rules/index là bước bạn thực hiện cho project thật. Chờ index sẵn sàng trước truy vấn GĐ3; Emulator không kiểm chứng trạng thái tạo index production.

Checklist thiết bị thật GĐ2 chưa chạy trong phiên này: tạo/sửa sau khởi động lại; bật/tắt sẵn sàng; chấp nhận/từ chối/quyền bị từ chối vĩnh viễn/GPS tắt; nhập manual; kiểm tra quyền riêng tư với hai tài khoản; thu hồi khi bị khóa; mất mạng khi lưu batch; giao diện trên màn hình hẹp và cỡ chữ lớn. Không suy từ kiểm thử widget ra kết quả GPS trên thiết bị thật.
