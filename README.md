# Steam Calculator 🎮

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=Dart&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.0.1-brightgreen?style=for-the-badge)
[![Download APK](https://img.shields.io/badge/Download-Android%20APK-00C853?style=for-the-badge&logo=android&logoColor=white)](apk/songtinhcam-release.apk)

---

## 📱 Cài đặt nhanh ứng dụng Android (APK)

Bạn có thể tải trực tiếp file cài đặt APK đã được build sẵn để cài đặt lên thiết bị Android hoặc máy ảo:

* 📦 **Link tải APK trực tiếp**: [**songtinhcam-release.apk**](apk/songtinhcam-release.apk)
* **Cách cài đặt**:
  - Tải file `songtinhcam-release.apk` về điện thoại.
  - Mở file APK vừa tải về trên thiết bị.
  - Nếu xuất hiện cảnh báo bảo mật, chọn **Cài đặt từ nguồn này** (Allow from this source).
  - Nhấn **Cài đặt (Install)** và mở ứng dụng.

---

## 🚀 Hướng dẫn phát triển & Khởi chạy

### 1. Yêu cầu môi trường
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (Khuyên dùng v3.13+ hoặc mới hơn)
* Dart SDK đi kèm Flutter
* Android Studio / VS Code

### 2. Cấu hình biến môi trường (.env)
Dự án sử dụng file `.env` để bảo vệ Steam Web API Key của bạn không bị đẩy lên Git:
1. Sao chép file mẫu `.env.example` thành `.env`:
   ```bash
   cp .env.example .env
   ```
2. Mở file `.env` và điền Steam Web API Key của bạn:
   ```env
   STEAM_API_KEY=your_steam_api_key_here
   ```
   *(Đăng ký lấy key miễn phí tại: [steamcommunity.com/dev/apikey](https://steamcommunity.com/dev/apikey))*

### 3. Cài đặt dependencies
```bash
flutter pub get
```

### 4. Khởi chạy ứng dụng

* **Chạy trên thiết bị di động / Máy ảo Android**:
  ```bash
  flutter run
  ```

* **Chạy trên Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

* **Chạy trên trình duyệt Web (Chrome/Edge)**:
  ```bash
  flutter run -d chrome
  ```

### 5. Build file APK Release mới
Khi muốn đóng gói bản release APK mới:
```bash
flutter build apk --release
```
File APK đầu ra sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Kiểm thử mã nguồn

Dự án tích hợp đầy đủ Unit Tests và Widget Tests để đảm bảo độ tin cậy của thuật toán tính toán và giao diện:

* **Chạy toàn bộ bài test**:
  ```bash
  flutter test
  ```
  *(12/12 bài test tự động: phân giải URL/SteamID, định dạng tiền tệ VND/USD, kiểm tra smoke test và giao diện responsive trên mobile).*

* **Kiểm tra linter và chuẩn mã nguồn**:
  ```bash
  flutter analyze
  ```

---

## 📌 Lưu ý về quyền riêng tư Steam

Để công cụ có thể đọc được danh sách game và thời gian chơi (tương tự như SteamDB), tài khoản Steam cần được thiết lập hiển thị công khai:
1. Vào **Steam Profile** > chọn **Edit Profile**.
2. Chọn mục **Privacy Settings** (Cài đặt riêng tư).
3. Đặt **Game details** sang **Public** (Công khai).
4. Bỏ tích chọn mục *Always keep my total playtime private*.
