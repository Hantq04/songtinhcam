class SteamFormatters {
  /// Định dạng số tiền VND theo chuẩn Việt Nam (phân cách hàng nghìn bằng dấu chấm và thêm hậu tố ₫)
  /// Ví dụ: 140000 -> "140.000 ₫"
  static String formatVnd(num amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} ₫';
  }

  /// Định dạng số tiền USD với 2 chữ số thập phân
  /// Ví dụ: 19.99 -> "$19.99"
  static String formatUsd(num amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      buffer.write(intPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return '\$${buffer.toString().split('').reversed.join('')}.$decPart';
  }

  /// Định dạng số tiền theo mã tiền tệ ('VND' hoặc 'USD' / 'Vietnamese Dong' / 'U.S. Dollar')
  static String formatAmount(num amount, String currencyCode) {
    final isUsd =
        currencyCode.toUpperCase().contains('USD') ||
        currencyCode.contains('Dollar');
    if (isUsd) {
      return formatUsd(amount);
    } else {
      return formatVnd(amount);
    }
  }

  /// Định dạng chi phí trên mỗi giờ chơi
  /// Ví dụ: "12.500 ₫/h" hoặc "$0.52/h"
  static String formatPricePerHour(num amount, String currencyCode) {
    final isUsd =
        currencyCode.toUpperCase().contains('USD') ||
        currencyCode.contains('Dollar');
    if (isUsd) {
      return '\$${amount.toStringAsFixed(2)}/h';
    } else {
      return '${formatVnd(amount)}/h';
    }
  }

  /// Định dạng tổng số phút thành giờ
  /// Ví dụ: 125 -> "2h"
  static String formatMinutesToHours(int totalMinutes) {
    final hours = (totalMinutes / 60).round();
    final str = hours.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return '${buffer.toString().split('').reversed.join('')}h';
  }

  /// Định dạng số giờ chơi (thập phân)
  /// Ví dụ: 45.2 -> "45.2h"
  static String formatPlaytimeHours(double hours) {
    return '${hours.toStringAsFixed(1)}h';
  }
}
