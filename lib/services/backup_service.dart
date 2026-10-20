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

  /// Xuất file backup ra thiết bị cho riêng tài khoản email đang đăng nhập
  Future<BackupResult> exportBackup() async {
    try {
      final auth = AuthService.instance;
      if (!auth.isLoggedIn || auth.userEmail == null || auth.userEmail!.trim().isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Please login before exporting backup data.',
        );
      }

      final currentEmail = auth.userEmail!.trim().toLowerCase();
      final userProfile = await DatabaseService.instance.getUserProfile(currentEmail);
      final savedSteamId = await DatabaseService.instance.getSavedSteamId(currentEmail);

      final now = DateTime.now();
      final profileData = {
        'email': currentEmail,
        'display_name': userProfile?['display_name'] ?? auth.userName,
        'steam_id': savedSteamId ?? userProfile?['steam_id'] ?? '',
        'avatar_url': userProfile?['avatar_url'] ?? auth.userAvatarUrl,
        'updated_at': userProfile?['updated_at'] ?? now.millisecondsSinceEpoch,
      };

      final emailName =
          currentEmail.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'songtinhcam_${emailName}_$dateStr.json';

      final backupData = {
        'app': 'songtinhcam',
        'version': '1.2.0',
        'exported_at': now.toIso8601String(),
        'account_email': currentEmail,
        'user_profile': profileData,
        'user_profiles': [profileData], // Giữ danh sách chứa riêng profile này để tương thích
      };

      final jsonContent =
          const JsonEncoder.withIndent('  ').convert(backupData);

      if (!kIsWeb && Platform.isWindows) {
        final chosenPath = await _saveFileWindows(defaultFileName, jsonContent);
        if (chosenPath == null) {
          return const BackupResult(
            success: false,
            cancelled: true,
            message: 'File save operation cancelled.',
          );
        }
        final file = File(chosenPath);
        await file.writeAsString(jsonContent, encoding: utf8);
        AuthService.instance.updateBackupTime(now);

        final displayPath =
            file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : chosenPath;
        return BackupResult(
          success: true,
          message: 'Backup exported successfully: $displayPath',
          filePath: chosenPath,
          count: 1,
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
            message: 'File save operation cancelled.',
          );
        }

        AuthService.instance.updateBackupTime(now);
        return BackupResult(
          success: true,
          message: 'Backup exported successfully: $defaultFileName',
          filePath: defaultFileName,
          count: 1,
        );
      } else {
        return const BackupResult(
          success: false,
          message: 'File export is not supported on this platform.',
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      return BackupResult(
        success: false,
        message: 'Export backup error: $e',
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
            message: 'File selection cancelled.',
          );
        }

        final file = File(chosenPath);
        if (!await file.exists()) {
          return const BackupResult(
            success: false,
            message: 'Selected file does not exist.',
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
            message: 'File selection cancelled.',
          );
        }

        final map = Map<String, dynamic>.from(result as Map);
        jsonContent = map['content'] as String?;
        fileName = map['name'] as String? ?? 'backup.json';
      } else {
        return const BackupResult(
          success: false,
          message: 'File import is not supported on this platform.',
        );
      }

      if (jsonContent == null || jsonContent.trim().isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Selected file is empty.',
        );
      }

      final decoded = json.decode(jsonContent);
      List<Map<String, dynamic>> profilesToImport = [];

      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('user_profile') &&
            decoded['user_profile'] is Map) {
          profilesToImport.add(
              Map<String, dynamic>.from(decoded['user_profile'] as Map));
        } else if (decoded.containsKey('account') &&
            decoded['account'] is Map) {
          profilesToImport
              .add(Map<String, dynamic>.from(decoded['account'] as Map));
        } else if (decoded.containsKey('user_profiles') &&
            decoded['user_profiles'] is List) {
          profilesToImport = (decoded['user_profiles'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else if (decoded.containsKey('email') &&
            (decoded.containsKey('steam_id') ||
                decoded.containsKey('steamId'))) {
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
          message: 'No valid profile data found in $fileName.',
        );
      }

      final count =
          await DatabaseService.instance.importUserProfiles(profilesToImport);
      AuthService.instance.updateBackupTime();

      return BackupResult(
        success: true,
        message: 'Successfully imported $count profile(s) from $fileName!',
        filePath: fileName,
        count: count,
      );
    } catch (e) {
      debugPrint('Import error: $e');
      return BackupResult(
        success: false,
        message: 'Error reading file: $e',
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
$d.Title = "Select Backup JSON File (Steam Calculator)"
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
\$d.Title = "Save Backup JSON File (Steam Calculator)"
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
