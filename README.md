# Steam Calculator (SteamDB Style) 🎮

Ứng dụng Flutter mô phỏng công cụ **Steam Calculator** lấy cảm hứng từ giao diện trực quan, hiện đại và chuẩn mực của [SteamDB Calculator](https://steamdb.info/calculator/).

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=Dart&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.0.1-brightgreen?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-12%2F12%20Passed-success?style=for-the-badge)

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### 1. Yêu cầu môi trường
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Khuyên dùng v3.13+ hoặc mới hơn)
- Dart SDK đi kèm Flutter

### 2. Cài đặt dependencies
Chạy lệnh sau tại thư mục gốc của dự án:
```bash
flutter pub get
```

### 3. Khởi chạy ứng dụng

- **Chạy trên thiết bị di động / Máy ảo Android**:
  ```bash
  flutter run
  ```

- **Chạy trên Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

- **Chạy trên trình duyệt Web (Chrome/Edge)**:
  ```bash
  flutter run -d chrome
  ```

### 4. Mẹo Debug trên VS Code (`.vscode/launch.json`)
Nếu bạn gặp lỗi socket loopback kết nối thất bại (`OS Error: 1225 - WSAECONNREFUSED`) khi chạy **Run and Debug (F5)** trên Windows, cấu hình trong `.vscode/launch.json` đã được bổ sung cờ `--disable-dds`:
```json
{
  "name": "songtinhcam",
  "request": "launch",
  "type": "dart",
  "toolArgs": ["--disable-dds"]
}
```

---

## 🧪 Kiểm thử mã nguồn

Dự án tích hợp đầy đủ Unit Tests và Widget Tests để đảm bảo độ tin cậy của thuật toán tính toán và giao diện:

- **Chạy toàn bộ bài test**:
  ```bash
  flutter test
  ```
  *(Bao gồm: phân giải URL/SteamID, định dạng tiền tệ VND/USD, kiểm tra smoke test và giao diện responsive trên mobile).*

- **Kiểm tra linter và chuẩn mã nguồn**:
  ```bash
  flutter analyze
  ```

---

## 📌 Lưu ý về quyền riêng tư Steam

Để công cụ có thể đọc được danh sách game và thời gian chơi, tài khoản Steam cần được thiết lập hiển thị công khai:
1. Vào **Steam Profile** > chọn **Edit Profile**.
2. Chọn mục **Privacy Settings**.
3. Đặt **Game details** sang **Public**.
4. Bỏ tích chọn mục *Always keep my total playtime private*.
5. (Tùy chọn) Nhận Steam Web API Key cá nhân tại [Steam Community Developer](https://steamcommunity.com/dev/apikey) nếu muốn tăng hạn mức request.

---

## 📄 Giấy phép

Dự án được xây dựng phục vụ mục đích học tập và tham khảo kỹ thuật.
Dữ liệu trò chơi và bản quyền thuộc về © [Valve Corporation](https://www.valvesoftware.com/). Cảm hứng giao diện thuộc về [SteamDB](https://steamdb.info/).
