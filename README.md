# TutorLink — Giai đoạn 1

Nguyên mẫu Android nghiên cứu tìm gia sư theo vị trí và đa tiêu chí. GĐ1 có Material 3 tiếng Việt, Riverpod generator, go_router, Firebase Auth và hồ sơ phân quyền Firestore. **Không dùng Cloud Functions, custom claims hoặc Blaze.** Chưa triển khai GĐ2–GĐ6.

## Công cụ và cấu trúc

Flutter stable 3.47.7 / Dart 3.13.5. Dependency trực tiếp ghim trong pubspec.yaml và package.json; commit cả pubspec.lock và package-lock.json. Node 24, JDK 21 trở lên cho Firebase Emulator. Flutter cài cục bộ trong .tools/flutter bị loại khỏi Git.

Trên máy hiện tại, thêm SDK cục bộ vào PATH của terminal trước khi dùng các lệnh bên dưới:

```powershell
$env:Path = "$PWD\.tools\flutter\bin;$env:Path"
```

Khi clone ở máy khác, tự cài Flutter 3.47.7 và thêm vào PATH. build_runner ghim 2.16.2 vì 2.17.1 dùng build 5, chưa tương thích riverpod_generator 4.0.9.

- lib/app: app, theme, router và route guard thuần Dart.
- lib/core: cấu hình, thông báo lỗi, màn hình trạng thái.
- lib/features/auth: domain (entity, repository interface), data (Firebase adapter), presentation (providers, forms).
- lib/features/home: khung trang chính cho learner/tutor/admin.
- firebase/tests: kiểm thử Security Rules.
- scripts/admin/set_admin.js: cấp admin ngoài ứng dụng.
- integration_test: smoke test Android với emulator.

Không tạo use case/datasource rỗng khi repository đã đủ cho thao tác Auth đơn giản. Các feature sau sẽ mở rộng theo data/domain/presentation.

## Các bước bạn phải tự làm với Firebase thật

1. Tạo Firebase project gói **Spark** tại Firebase Console.
2. Bật Authentication → Sign-in method → Email/Password. Cấu hình mẫu email xác thực và đặt lại mật khẩu bằng tiếng Việt.
3. Tạo Cloud Firestore ở production mode; chọn region phù hợp. Deploy Rules bên dưới trước khi dùng app.
4. Đăng ký Android app với applicationId **vn.tutorlink.tutorlink**.
5. Cài Firebase CLI và FlutterFire CLI:
   ```powershell
   npm ci
   npx firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<firebase-project-id> --platforms=android
   ```
6. Chạy `cd android`, sau đó `.\gradlew.bat signingReport`; lấy SHA-1 debug thêm vào Firebase Console → Project settings → Android app. Thêm SHA-1 của khóa release khi phát hành. Email/password không phụ thuộc SHA-1 nhưng nên cấu hình đầy đủ cho Android.
7. Kiểm tra tệp `android/app/google-services.json` đã được FlutterFire tạo/tải đúng app; **không commit tệp này, API key hoặc lib/firebase_options.dart**.
8. `flutterfire configure` sinh `lib/firebase_options.dart`. Thêm import vào bootstrap.dart và đổi lời gọi thành:
   ```dart
   await Firebase.initializeApp(
     options: emulator
         ? emulatorFirebaseOptions
         : DefaultFirebaseOptions.currentPlatform,
   );
   ```
   Bootstrap hiện có thể khởi tạo Android qua tài nguyên google-services.json; chưa kèm cấu hình Firebase thật.
9. Sao chép `Copy-Item .env.example .env`; chạy:
   ```powershell
   flutter pub get
   dart run build_runner build
   npx firebase deploy --only firestore:rules,firestore:indexes --project <firebase-project-id>
   flutter run
   ```

.env chỉ chứa cấu hình client như hostname emulator, không chứa private key. Service account phải nằm ngoài repository. API key Firebase phía client không thay thế Security Rules. Nếu FlutterFire tạo thay đổi cấu hình riêng cho project trong firebase.json, kiểm tra trước khi commit.

## Chạy bằng Firebase Emulator, không cần Firebase thật

```powershell
Copy-Item .env.example .env
npm ci
npm run emulators
```

Giữ terminal này mở. Terminal khác:

```powershell
flutter pub get
dart run build_runner build
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Android Emulator dùng EMULATOR_HOST=10.0.2.2. Emulator UI: http://localhost:4000. Email xác thực và reset được emulator ghi liên kết trong terminal/UI, không gửi thư thật. Project demo-tutorlink chỉ dùng local; tránh nhập dữ liệu thật.

Nếu dùng điện thoại thật cần cấu hình host LAN và emulator bind phù hợp; hướng dẫn mặc định dành cho Android Emulator.

## Luồng tài khoản và quyền

- Đăng ký learner/tutor → tạo Firebase Auth → tạo users/{uid} → gửi email xác thực.
- Chưa xác thực email: chỉ màn xác thực, có gửi lại và tải lại trạng thái.
- Auth thành công nhưng ghi Firestore thất bại: giữ phiên; trang hoàn tất hồ sơ cho phép thử lại. Không tự xóa tài khoản.
- users chứa đúng displayName, email, role, isLocked, createdAt.
- Rules buộc role learner/tutor, isLocked=false, email trùng Auth và createdAt bằng server timestamp lúc tạo.
- Người dùng hoạt động chỉ được sửa displayName. Không ai đổi role từ client, kể cả admin.
- Admin chưa bị khóa được đọc/list users và chỉ đổi isLocked. Vai trò admin tra bằng get(users/{uid}), không dùng custom claims.
- Chủ tài khoản bị khóa vẫn đọc được hồ sơ chính mình để app hiển thị trạng thái khóa; không được sửa hồ sơ. Việc khóa Firestore không vô hiệu hóa đăng nhập Firebase Auth.
- Người khác không được đọc hồ sơ riêng; collection chưa làm bị deny mặc định.
- Router theo dõi thay đổi hồ sơ trực tiếp; Rules là lớp bảo vệ dữ liệu. Xác thực email hiện là điều kiện UI; Rules users vẫn cho tạo/đọc hồ sơ trước xác thực để hoàn tất đăng ký.

## Cấp admin một lần

Đăng ký và xác thực email tài khoản dự kiến làm admin trước. Lấy UID trong Firebase Auth. Tải service account từ Firebase Console → Project settings → Service accounts; lưu ví dụ C:\Secrets\tutorlink-admin.json, **ngoài repo**.

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\Secrets\tutorlink-admin.json'
node scripts/admin/set_admin.js <uid> <firebase-project-id>
Remove-Item Env:\GOOGLE_APPLICATION_CREDENTIALS
```

Script kiểm tra đường dẫn thực, kiểm tra Auth user và hồ sơ tồn tại, chỉ cập nhật role=admin và giữ nguyên isLocked. Không đặt credential trong .env, không đưa credential lên Git. Admin SDK chạy cục bộ không cần Cloud Functions/Blaze.

## Kiểm thử

```powershell
dart run build_runner build
flutter analyze
flutter test
npm run test:rules
```

Rules tests dùng project demo-tutorlink trên emulator, xóa dữ liệu emulator giữa các test. Cần Java 21+ trong PATH/JAVA_HOME; nếu máy có Java 8 mặc định, trỏ sang JDK của Android Studio trước khi chạy.

Integration smoke test: bật emulator Auth/Firestore như trên, khởi động Android Emulator mới hoặc xóa dữ liệu app để chưa đăng nhập, rồi:

```powershell
flutter test integration_test/auth_smoke_test.dart -d <android-device-id> --dart-define=USE_FIREBASE_EMULATORS=true
```

Kiểm thử thủ công bổ sung: đăng ký từng vai trò, mở liên kết xác thực từ emulator, đăng xuất/đăng nhập, quên mật khẩu, thử mất mạng khi hoàn tất hồ sơ, đổi isLocked bằng emulator/admin và quan sát điều hướng.

Chưa đo SLA tìm kiếm <2 giây: tính năng tìm kiếm thuộc GĐ3. Không coi widget test hoặc Rules tests là bằng chứng chạy APK trên thiết bị.

## Phạm vi tiếp theo

Kết quả kiểm tra GĐ1 ngày 16/10/2026:

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 19/19 test đạt.
- `npm run test:rules`: 16/16 test đạt trên Firestore Emulator 1.22.0.
- `node --check scripts/admin/set_admin.js`: đạt.
- Chưa chạy integration test/APK trên Android và chưa kết nối Firebase project thật.

GĐ2: hồ sơ gia sư, vị trí riêng/công khai, seed 150 gia sư. GĐ3: tìm kiếm/bản đồ. GĐ4: ranking thuần Dart và giải thích. GĐ5: yêu cầu/đánh giá/báo cáo/FCM. GĐ6: admin/log/CSV và Rules toàn hệ thống. Cách gửi FCM phía máy chủ trên Spark cần chốt ở GĐ5; GĐ1 không cài Cloud Functions.
