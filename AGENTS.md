# TutorLink — luật dự án và bàn giao giữa các công cụ AI

Đọc file này, README.md và docs/HANDOFF.md trước khi sửa. Chỉ một công cụ được sửa cùng checkout tại một thời điểm. Hướng dẫn trực tiếp của người dùng là nguồn quyết định phạm vi công việc.

## Quyết định đã chốt

- Firebase Spark, không Cloud Functions, không Blaze, không custom claims. Vai trò/khóa đọc từ users/{uid}; admin cấp bằng scripts/admin/set_admin.js với service account ngoài repo.
- FCM/yêu cầu học/đánh giá thuộc GĐ5, chưa triển khai. Không tự thêm dịch vụ gửi push hoặc đổi gói để triển khai. Chốt phương án thông báo phù hợp Spark khi bắt đầu GĐ5.
- Flutter/Dart, Material 3 tiếng Việt, Riverpod, go_router, kiến trúc theo feature data/domain/presentation. Giữ package ghim và các lockfile (kể cả package Dart con).
- Bản đồ flutter_map + OpenStreetMap; giữ attribution, cache và cấu hình tile/User-Agent. Không tự chuyển Google Maps.
- Giữ kotlin.incremental=false trong android/gradle.properties do lỗi cache Kotlin giữa ổ C/D.
- Xếp hạng ở packages/tutor_ranking: lịch dùng độ phủ giao/nhu cầu, KHÔNG Jaccard. Không chọn cấp thì subject=1. Thiếu lịch/ngân sách thì bỏ tiêu chí và chuẩn hóa trọng số còn lại. Hồ sơ lỗi được bỏ qua và trả skippedUids; request/trọng số lỗi vẫn bị từ chối.
- Trọng số đọc config/ranking_weights; dự phòng config/ranking_defaults.json. Đổi công thức phải cập nhật README, docs/phase4.md và test. Không ghi đè cấu hình khảo sát/AHP khi seed.
- Vị trí chính xác chỉ trong private_locations, hiện chỉ chủ sở hữu đọc. Tìm kiếm chỉ dùng approxLocation công khai; vị trí người học giữ cục bộ/tạm thời.
- Tài khoản khóa không đọc tutors/config. Giữ khả năng chủ sở hữu thu hồi vị trí khi khóa. Rules phải bảo vệ quyền ở server, không chỉ ở UI.

## Quy tắc sửa và kiểm thử

- Chỉ sửa file cần cho nhiệm vụ; không format hàng loạt, nâng dependency, đổi Gradle/Kotlin hoặc kiến trúc ngoài phạm vi.
- Không xóa/làm yếu test để che lỗi. Nếu kỳ vọng test sai, sửa theo bằng chứng và ghi rõ nguyên nhân.
- Đổi firestore.rules phải bổ sung test (cả ca bị từ chối), chạy Emulator đạt trước khi deploy. Chỉ deploy trong phạm vi được người dùng giao, kiểm tra project đích tutorlink-a4ef5; test tự động dùng demo-tutorlink.
- Không commit .env, env.bat, service account, google-services.json, firebase_options.dart, .tools/, build/ hay thông tin xác thực. Không đưa khóa backend vào ứng dụng.
- Cuối phiên chạy scripts\check.bat, báo chính xác kết quả và phần chưa kiểm thử. Không coi test máy tính là xác nhận đã chạy điện thoại hoặc SLA <2 giây.
- Cập nhật docs/HANDOFF.md, commit nhỏ với thông điệp rõ. Push theo yêu cầu người dùng. Không commit thay đổi của người khác hoặc reset/ghi đè công việc dở.
- Dừng đúng giai đoạn đã được giao; GĐ5/GĐ6 cần người dùng cho tiếp tục.

## Tiếp quản từ công cụ khác

1. Đọc luật/bàn giao; xem git status, git log --oneline -10 và diff từ commit bàn giao. Nếu có tag phù hợp có thể so với tag; không giả định đã có tag.
2. Nếu có thay đổi dở, xác định người đang sửa và phạm vi trước khi chạm vào file. Không chạy hai tác nhân sửa cùng checkout.
3. Chạy scripts\check.bat và báo kết quả. Khi chỉ được yêu cầu tiếp quản, chưa tự sửa lỗi hay bắt đầu giai đoạn mới; khi đã có nhiệm vụ cụ thể thì thực hiện trong phạm vi đó.
4. Dùng nhánh codex/<ten-viec> cho nhánh mới nếu không có tên do người dùng chỉ định. Không tự đổi nhánh có công việc dở.

## Môi trường Windows

- scripts\check.bat chạy từ bất kỳ thư mục nào, tự về root, gọi env.bat nếu có, ưu tiên SDK .tools\flutter\bin, dùng JAVA_HOME hoặc JDK Android Studio mặc định.
- env.bat là tùy chỉnh máy cá nhân, không bắt buộc, bị ignore; không lưu bí mật vào file mẫu trong Git.
- Cần dependencies đã cài theo lock: npm ci, flutter pub get, và dart pub get trong packages/tutor_ranking. Script kiểm tra không tự upgrade/cài dependency hoặc deploy.
- Lệnh chung chạy analyze + test Flutter, analyze + test package Dart, npm run test:rules. Dừng ngay khi có lỗi và trả exit code khác 0.
