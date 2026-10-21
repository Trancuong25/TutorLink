# GĐ4 — Xếp hạng đa tiêu chí

`packages/tutor_ranking` là package Dart thuần, không import Flutter/Firebase. `rankTutors` nhận candidates, request, RankingWeights và C, trả RankedTutor với tổng điểm, điểm thành phần, trọng số thực dùng, khoảng cách và lý do.

## Công thức

Lọc cứng: môn, isAvailable và d≤R. Ứng dụng đã lọc thêm isHidden và các bộ lọc tùy chọn trước khi gọi. Hai chế độ dùng cùng tập ứng viên đã giới hạn (xem giới hạn 100 trong GĐ3).

| Thành phần | Điểm [0,1] |
|---|---|
| subject | 1 nếu khớp môn/cấp, 0,5 nếu chỉ khớp môn. Không chọn cấp cũng được coi là chỉ khớp môn. |
| schedule | kích thước giao / kích thước hợp hai tập lịch |
| distance | clamp(1−d/R, 0, 1), d tính từ approxLocation |
| price | clamp(2−học phí/ngân sách, 0, 1) |
| rating | (v×ratingAvg + 5×C)/(v+5)/5 |

Score = tổng wᵢ×điểmᵢ. Nếu không chọn lịch, bỏ schedule; nếu không nhập ngân sách, bỏ price. Chia các trọng số còn lại cho tổng của chúng. Thành phần bị bỏ có giá trị null, không phải 0. Nếu tổng trọng số còn lại bằng 0, app dùng mặc định và hiện cảnh báo. Package thuần từ chối trọng số sai bằng ArgumentError; adapter của app chịu trách nhiệm fallback.

Gần nhất chỉ sắp theo khoảng cách rồi UID, không hiện điểm/lý do. Phù hợp nhất sắp điểm giảm dần, khoảng cách tăng dần rồi UID. Chuyển chế độ không gọi lại truy vấn; lựa chọn lưu trong RAM đến khi đổi tài khoản. Vị trí trên marker và giải thích đều là vị trí gần đúng. “Trùng 3/4 buổi” là giao/nhu cầu, khác mẫu số của Jaccard (giao/hợp).

## Trọng số và C

Nguồn chính: `config/ranking_weights` trong Firestore, schema sáu số:

```json
{"subject":0.30,"schedule":0.25,"distance":0.20,"price":0.15,"rating":0.10,"systemRatingMean":4.0}
```

Giá trị C ở JSON trên chỉ minh họa/dự phòng. Seed khi tài liệu chưa có sẽ tính C = sum(ratingAvg×ratingCount)/sum(ratingCount) trên toàn bộ hồ sơ có đánh giá hợp lệ. Production hiện C≈3,9936128781 từ dữ liệu đang có. Nếu không có lượt đánh giá thì dùng C dự phòng trong asset. Đây chưa phải trung bình từ người dùng thật: dữ liệu hiện chủ yếu là mô phỏng.

Asset `config/ranking_defaults.json` dùng chung với seed và làm fallback khi tài liệu thiếu/sai hoặc mạng lỗi, app hiện cảnh báo. Không chôn trọng số mặc định trong code ranking. Tổng năm trọng số cần bằng 1 (sai số 10⁻⁶), mỗi trọng số không âm/hữu hạn; C nằm trong [0,5].

Mọi user đăng nhập được đọc đúng tài liệu; chỉ admin chưa khóa được tạo/sửa và không được xóa qua client. Firebase Console/Admin SDK sử dụng quyền hạ tầng, không bị Rules giới hạn. Sau khảo sát/AHP, chuẩn hóa vector trọng số về tổng 1 rồi cập nhật năm field số trong tài liệu; giữ C đúng nghĩa trung bình hệ thống. Ghi lại dữ liệu khảo sát, phương pháp, version và ngày hiệu lực trong báo cáo thực nghiệm. Trọng số mặc định chưa phải kết quả nghiên cứu.

Seed không ghi đè cấu hình có sẵn để bảo toàn AHP. Khởi tạo riêng config (service account vẫn phải ngoài repo):

```powershell
node scripts/seed/seed.js --project tutorlink-a4ef5 --config-only
```

Cleanup `--clean` chỉ xóa dữ liệu mock, không xóa cấu hình. Khi thay đổi tập đánh giá (hoặc cleanup mock), người quản trị cần cập nhật C; Spark hiện chưa tự cập nhật C khi đánh giá đổi, vì luồng đánh giá thuộc GĐ5.

## Kiểm thử

```powershell
flutter analyze --no-pub
flutter test --no-pub
Push-Location packages/tutor_ranking
dart pub get
dart analyze
dart test
Pop-Location
npm run test:rules
```

Các test bao phủ điểm biên, Bayesian, thiếu tiêu chí, validation trọng số, tie-break, hai chế độ khác thứ tự, widget giải thích và việc không truy vấn lại khi đổi chế độ. Kết quả đo production và phần chưa kiểm tra thiết bị ở [báo cáo GĐ3–GĐ4](verification-phase3-4.md).
