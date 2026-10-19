import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'database_service.dart';

class BackupResult {
  final bool success;
  final bool cancelled;
  final String message;
  final String? filePath;
  final int count;

  const BackupResult({
    required this.success,
    this.cancelled = false,
    required this.message,
    this.filePath,
    this.count = 0,
  });
}

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const MethodChannel _androidChannel =
      MethodChannel('com.example.songtinhcam/file_picker');

  /// Xuất file backup ra thiết bị theo đường dẫn do người dùng chọn
  Future<BackupResult> exportBackup() async {
    try {
      final profiles = await DatabaseService.instance.getAllUserProfiles();

      // Đảm bảo thông tin user đang login được đưa vào backup
      final auth = AuthService.instance;
      if (auth.isLoggedIn && auth.userEmail != null) {
        final email = auth.userEmail!.trim().toLowerCase();
        final hasCurrent = profiles.any(
          (p) => (p['email'] as String? ?? '').toLowerCase() == email,
        );
        if (!hasCurrent) {
          final savedId = await DatabaseService.instance.getSavedSteamId(email);
          if (savedId != null && savedId.isNotEmpty) {
            profiles.add({
              'email': email,
              'display_name': auth.userName,
              'steam_id': savedId,
              'avatar_url': auth.userAvatarUrl,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'songtinhcam_backup_$dateStr.json';

      final backupData = {
        'app': 'songtinhcam',
        'version': '1.2.0',
        'exported_at': now.toIso8601String(),
        'profiles_count': profiles.length,
        'user_profiles': profiles,
        'current_account': auth.isLoggedIn
            ? {
                'email': auth.userEmail,
                'name': auth.userName,
                'avatar': auth.userAvatarUrl,
              }
            : null,
      };

      final jsonContent =
          const JsonEncoder.withIndent('  ').convert(backupData);

      if (!kIsWeb && Platform.isWindows) {
        final chosenPath = await _saveFileWindows(defaultFileName, jsonContent);
        if (chosenPath == null) {
          return const BackupResult(
            success: false,
            cancelled: true,
            message: 'Đã hủy thao tác lưu file.',
          );
        }
        final file = File(chosenPath);
        await file.writeAsString(jsonContent, encoding: utf8);
        AuthService.instance.updateBackupTime(now);

        final displayPath =
            file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : chosenPath;
        return BackupResult(
          success: true,
          message: 'Xuất file thành công: $displayPath',
          filePath: chosenPath,
          count: profiles.length,
        );
      } else if (!kIsWeb && Platform.isAndroid) {
        final result = await _androidChannel.invokeMethod('saveFile', {
          'fileName': defaultFileName,
          'content': jsonContent,
        });

        if (result == null) {
          return const BackupResult(
            success: false,
            cancelled: true,
            message: 'Đã hủy thao tác lưu file.',
          );
        }

        AuthService.instance.updateBackupTime(now);
        return BackupResult(
          success: true,
          message: 'Xuất file thành công: $defaultFileName',
          filePath: defaultFileName,
          count: profiles.length,
        );
      } else {
        return const BackupResult(
          success: false,
          message: 'Nền tảng này chưa hỗ trợ chọn file xuất.',
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      return BackupResult(
        success: false,
        message: 'Lỗi xuất backup: $e',
      );
    }
  }

  /// Nhập file backup từ thiết bị theo file người dùng chọn
  Future<BackupResult> importBackup() async {
    try {
      String? jsonContent;
      String? fileName;

      if (!kIsWeb && Platform.isWindows) {
        final chosenPath = await _pickFileWindows();
        if (chosenPath == null) {
          return const BackupResult(
            success: false,
            cancelled: true,
            message: 'Đã hủy chọn file.',
          );
        }

        final file = File(chosenPath);
        if (!await file.exists()) {
          return const BackupResult(
            success: false,
            message: 'File đã chọn không tồn tại.',
          );
        }

        jsonContent = await file.readAsString(encoding: utf8);
        fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : chosenPath;
      } else if (!kIsWeb && Platform.isAndroid) {
        final result = await _androidChannel.invokeMethod('pickFile');
        if (result == null) {
          return const BackupResult(
            success: false,
            cancelled: true,
            message: 'Đã hủy chọn file.',
          );
        }

        final map = Map<String, dynamic>.from(result as Map);
        jsonContent = map['content'] as String?;
        fileName = map['name'] as String? ?? 'backup.json';
      } else {
        return const BackupResult(
          success: false,
          message: 'Nền tảng này chưa hỗ trợ chọn file nhập.',
        );
      }

      if (jsonContent == null || jsonContent.trim().isEmpty) {
        return const BackupResult(
          success: false,
          message: 'File đã chọn bị trống.',
        );
      }

      final decoded = json.decode(jsonContent);
      List<Map<String, dynamic>> profilesToImport = [];

      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('user_profiles') &&
            decoded['user_profiles'] is List) {
          profilesToImport = (decoded['user_profiles'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else if (decoded.containsKey('email') &&
            decoded.containsKey('steam_id')) {
          profilesToImport.add(decoded);
        }
      } else if (decoded is List) {
        profilesToImport = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      if (profilesToImport.isEmpty) {
        return BackupResult(
          success: false,
          message: 'Không tìm thấy dữ liệu profile hợp lệ trong $fileName.',
        );
      }

      final count =
          await DatabaseService.instance.importUserProfiles(profilesToImport);
      AuthService.instance.updateBackupTime();

      return BackupResult(
        success: true,
        message: 'Đã nhập thành công $count profile từ $fileName!',
        filePath: fileName,
        count: count,
      );
    } catch (e) {
      debugPrint('Import error: $e');
      return BackupResult(
        success: false,
        message: 'Lỗi đọc file: $e',
      );
    }
  }

  /// Hộp thoại chọn file trên Windows (sử dụng PowerShell STA OpenFileDialog)
  Future<String?> _pickFileWindows() async {
    const script = r'''
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$d = New-Object System.Windows.Forms.OpenFileDialog
$d.Title = "Chọn file Backup JSON (SongTinhCam)"
$d.Filter = "JSON Backup (*.json)|*.json|All Files (*.*)|*.*"
$res = $d.ShowDialog($form)
$form.Dispose()
if ($res -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write($d.FileName)
}
''';
    final b64 = _encodeScript(script);
    final res = await Process.run('powershell', [
      '-NoProfile',
      '-STA',
      '-EncodedCommand',
      b64,
    ]);
    if (res.exitCode == 0) {
      final path = res.stdout.toString().trim();
      return path.isNotEmpty ? path : null;
    }
    return null;
  }

  /// Hộp thoại lưu file trên Windows (sử dụng PowerShell STA SaveFileDialog)
  Future<String?> _saveFileWindows(
      String defaultFileName, String content) async {
    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$form = New-Object System.Windows.Forms.Form
\$form.TopMost = \$true
\$d = New-Object System.Windows.Forms.SaveFileDialog
\$d.Title = "Lưu file Backup JSON (SongTinhCam)"
\$d.Filter = "JSON Backup (*.json)|*.json|All Files (*.*)|*.*"
\$d.FileName = "$defaultFileName"
\$res = \$d.ShowDialog(\$form)
\$form.Dispose()
if (\$res -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write(\$d.FileName)
}
''';
    final b64 = _encodeScript(script);
    final res = await Process.run('powershell', [
      '-NoProfile',
      '-STA',
      '-EncodedCommand',
      b64,
    ]);
    if (res.exitCode == 0) {
      final path = res.stdout.toString().trim();
      return path.isNotEmpty ? path : null;
    }
    return null;
  }

  String _encodeScript(String script) {
    final utf16leBytes = <int>[];
    for (final unit in script.codeUnits) {
      utf16leBytes.add(unit & 0xff);
      utf16leBytes.add((unit >> 8) & 0xff);
    }
    return base64.encode(utf16leBytes);
  }
}
