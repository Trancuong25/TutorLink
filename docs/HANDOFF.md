# Bàn giao TutorLink

- Cập nhật: 21/10/2026, Codex.
- Commit ứng dụng gần nhất: efebd6b — Sửa xếp hạng sau review (đã push master). Commit quy trình bàn giao chứa file này: xem git log -1; không ghi hash tự tham chiếu. Chưa có tag giai đoạn.
- Nguồn quy tắc chung: ../AGENTS.md. Claude đọc qua ../CLAUDE.md; với công cụ khác, yêu cầu đọc AGENTS.md/HANDOFF.md trong prompt tiếp quản, không giả định chúng tự đọc.

## Đã xong

- GĐ1: đăng nhập/đăng ký, xác thực email, quên mật khẩu, vai trò và khóa.
- GĐ2: hồ sơ gia sư, bảo vệ/thu hồi vị trí, seed 150 mock.
- GĐ3: tìm theo geohash, lọc, danh sách/bản đồ OSM, chỉ dùng vị trí công khai.
- GĐ4: hai chế độ xếp hạng, giải thích, trọng số Firestore. Review đã sửa: độ phủ lịch thay Jaccard, subject=1 khi không chọn cấp, bỏ hồ sơ lỗi + skippedUids/log UI, chặn user khóa đọc tutors/config, kinh độ riêng ±180°.
- Rules review đã deploy lên Firebase Spark tutorlink-a4ef5. Không Cloud Functions/custom claims. Package và lockfile đã ghim.

## Đang làm / chưa kiểm thử

- Phiên này chỉ thêm luật dự án và quy trình bàn giao, không thay đổi tính năng.
- APK đã build ở trước review; CHƯA chứa sửa review. Chưa build/cài lại và chưa kiểm thử GĐ3–GĐ4 trên điện thoại. Không dùng kết quả thiết bị GĐ2 để suy ra phiên bản mới đã chạy.
- GĐ5–GĐ6 chưa triển khai; FCM/thông báo chưa có. Chưa chọn phương án gửi thông báo cho GĐ5 trong giới hạn Spark.

## Việc tiếp theo

1. Khi tiếp quản: đọc luật, git status/log/diff, chạy scripts\check.bat; không chạy hai công cụ sửa cùng checkout.
2. Khi người dùng yêu cầu: build/cài APK mới, kiểm thử tìm kiếm, bản đồ/GPS và hai chế độ trên điện thoại.
3. Chờ cho phép bắt đầu GĐ5: yêu cầu học, thông báo, đánh giá và báo cáo vi phạm; chốt cách thông báo, cập nhật C và quyền dữ liệu trước khi triển khai.

## Kiểm tra gần nhất

- Bản review efebd6b: Flutter analyze + Dart analyze sạch; Flutter test 38/38, ranking 13/13, Emulator 31/31 đạt.
- scripts\check.bat chạy thành công lúc khoảng 21:20 (Asia/Saigon), 21/10/2026, exit code 0: Flutter/Dart analyze sạch; Flutter 38/38, ranking 13/13, Emulator 31/31 đạt. Emulator đã dừng sau test.
- Không có thay đổi code ứng dụng trong phiên bàn giao này.

## Rủi ro/giới hạn đã biết

- Rules chưa chứng minh geohash khớp approxLocation. Client tạo cặp nhất quán, Haversine lọc theo tọa độ công khai, nhưng không coi đó là bảo đảm toàn vẹn server; chưa sửa vì ngoài phạm vi review được giao.
- systemRatingMean (C) hiện nằm trong config; seed chỉ khởi tạo khi thiếu, không cập nhật tự động theo đánh giá. GĐ5 cần xử lý hoặc có quy trình admin cập nhật.
- Kinh độ ngoài ±180° bị Firestore Emulator từ chối INVALID_ARGUMENT trước Rules; test hai biên hợp lệ đi qua Rules.
- Giới hạn 100 documents/range và 100 kết quả; dữ liệu dày có thể bị cắt. Sai số vị trí làm mờ ảnh hưởng biên bán kính.
- Đo truy vấn trước review trên máy tính 294–1488 ms không phải SLA Android. Thứ tự xếp hạng trong báo cáo cũ dùng Jaccard, không đại diện công thức mới.
- Tile OSM công cộng không có SLA; chưa xác nhận cache/render trên điện thoại.

## Cách bàn giao

Kết thúc ở điểm ổn định, chạy check, cập nhật file này với công việc dở/kết quả thật, commit và push theo yêu cầu. Công cụ sau đọc lịch sử và diff; không chỉ dựa vào lời khẳng định của công cụ trước. Nếu test đỏ khi chỉ tiếp quản, báo lỗi trước khi sửa. Khi đã được giao nhiệm vụ sửa thì tiếp tục trong phạm vi đó.
