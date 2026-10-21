# GĐ3 — Tìm kiếm

Từ trang người học chọn **Tìm gia sư gần bạn**, chọn khu vực/GPS qua màn GĐ2. Môn bắt buộc; cấp, ngân sách và lịch là mong muốn, chỉ trở thành bộ lọc cứng khi bật công tắc tương ứng. Lọc lịch yêu cầu khớp tất cả buổi đã chọn. Chọn online/offline chấp nhận cả tutor `both`. Xóa bộ lọc đưa về Toán, 5 km, bỏ các tùy chọn còn lại; không xóa vị trí.

## Truy vấn và giới hạn

- Phủ bounding box hình cầu bằng geohash precision 5 với R≤2 km, 4 với R>2 km; xử lý qua kinh tuyến ±180, hỗ trợ tâm ±60° như GĐ2.
- Truy vấn song song `isHidden=false`, `isAvailable=true`, khoảng prefix geohash trên **tutors**; không đọc private_locations.
- Lọc Haversine trên tọa độ đã làm mờ, không diễn giải thành khoảng cách tới nhà thật.
- Tối đa 100 documents **mỗi range Firestore**, rồi gộp/deduplicate/lọc/sắp xếp và lấy 100 kết quả. Số lượt đọc tổng có thể vượt 100 vì một tìm kiếm có nhiều range; UI cảnh báo khi range chạm cap hoặc kết quả vượt 100. Dữ liệu dày có thể bỏ sót ứng viên do cap; không hứa toàn bộ hoặc nearest toàn cục khi bị cắt.
- Chỉ chạy khi áp dụng bộ lọc hoặc đổi tâm; chuyển danh sách/bản đồ không truy vấn lại. Timeout 15s, lỗi có thử lại. Debug log thời gian cả query và xử lý, không ghi tọa độ.
- Thêm composite index subjects (array contains), isHidden, isAvailable, geohash để lọc môn ngay trên server, giảm lượt đọc trước khi lọc khoảng cách.

## Bản đồ

Đổi Google Maps Platform trong đề cương sang flutter_map/OpenStreetMap để tránh bật billing cho nguyên mẫu Spark. Đây là thay đổi cần ghi trong báo cáo khoa học.

Thêm hai dòng trong `.env` theo `.env.example`: MAP_TILE_URL và MAP_USER_AGENT. Widget TutorMap là ranh giới thay nhà cung cấp. Không hard-code URL/agent trong code; thiếu cấu hình vẫn dùng danh sách.

[flutter_map cache](https://docs.fleaflet.dev/layers/tile-layer/caching) dùng cache đĩa built-in theo HTTP headers. Không prefetch/bulk download; cache không bảo đảm dùng offline. Có attribution luôn hiển thị và marker cluster, vòng bán kính, recenter.

[OSM tile policy](https://operations.osmfoundation.org/policies/tiles/) yêu cầu định danh ứng dụng, attribution và cache. Máy chủ công cộng không có SLA hay cam kết tải cho số lượng người dùng cụ thể. Chỉ demo nhẹ; nếu tải tăng/được yêu cầu dừng, đổi MAP_TILE_URL sang nhà cung cấp có điều khoản phù hợp. Vị trí tìm kiếm không gửi Firestore; dịch vụ tile nhận IP và vùng tile đang xem, cần thông báo cho người dùng.

Mục tiêu <2 giây cần đo trên mạng/thiết bị thực tế; không coi test thuật toán là bằng chứng SLA.

## Kiểm tra trước commit GĐ3

Ngày 21/10/2026: analyze source/test/integration_test không có cảnh báo, 35/35 Flutter test đạt. Index mới deploy thành công; tại lần đo đầu index còn BUILDING nên chưa có kết quả latency. Điện thoại không kết nối ADB ở thời điểm này; chưa xác nhận bản đồ trên máy thật. Tiếp tục đo và build trong đợt GĐ4.
