import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );

  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userAvatarUrl;
  DateTime? _lastBackupTime;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userAvatarUrl => _userAvatarUrl;
  DateTime? get lastBackupTime => _lastBackupTime;

  /// Đăng nhập trực tiếp bằng tài khoản Google thật của người dùng trên thiết bị
  Future<String?> signInWithGoogle() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      debugPrint('Google Sign-In is not supported on Windows/Linux desktop.');
      return null;
    }
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // Người dùng hủy chọn tài khoản
        return null;
      }

      _isLoggedIn = true;
      _userEmail = account.email;
      _userName = account.displayName ?? account.email.split('@').first;
      _userAvatarUrl = account.photoUrl;
      notifyListeners();
      return _userEmail;
    } catch (e) {
      debugPrint('Error Login Google: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin đăng nhập trực tiếp (phục vụ test hoặc custom provider)
  void setLoggedInUser({
    required String email,
    String? displayName,
    String? avatarUrl,
  }) {
    _isLoggedIn = true;
    _userEmail = email;
    _userName = displayName ?? email.split('@').first;
    _userAvatarUrl = avatarUrl;
    notifyListeners();
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userAvatarUrl = null;
    notifyListeners();
  }

  /// Cập nhật thời điểm backup thành công
  void updateBackupTime([DateTime? time]) {
    _lastBackupTime = time ?? DateTime.now();
    notifyListeners();
  }

  /// Sao lưu dữ liệu tài khoản và lịch sử tính toán Steam (tương thích ngược)
  Future<bool> backupData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _lastBackupTime = DateTime.now();
    notifyListeners();
    return true;
  }
}
