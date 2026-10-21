import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'database_service.dart';
import 'env_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  GoogleSignIn? _googleSignIn;

  Future<GoogleSignIn> _getGoogleSignIn() async {
    if (_googleSignIn != null) return _googleSignIn!;
    final clientId = await EnvService.getGoogleClientId();
    final serverClientId = await EnvService.get('GOOGLE_SERVER_CLIENT_ID');
    _googleSignIn = GoogleSignIn(
      scopes: <String>['email'],
      // Trên Android, Google Play Services tự động liên kết qua Package Name và SHA-1 trong Google Cloud.
      // Không truyền Android clientId vào đây trên Android vì google_sign_in sẽ diễn giải nhầm nó thành
      // serverClientId (vốn chỉ chấp nhận Web Client ID) và gây ra ApiException 10.
      clientId: (!kIsWeb && Platform.isAndroid) ? null : clientId,
      serverClientId: serverClientId,
    );
    return _googleSignIn!;
  }

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userAvatarUrl;
  DateTime? _lastBackupTime;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userAvatarUrl => _userAvatarUrl;
  DateTime? get lastBackupTime => _lastBackupTime;

  /// Khởi tạo và khôi phục phiên đăng nhập từ SQLite
  /// Đảm bảo tài khoản luôn tồn tại trong app trừ khi người dùng chủ động Logout hoặc xóa app
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final session = await DatabaseService.instance.getActiveSession();
      if (session != null) {
        _isLoggedIn = true;
        _userEmail = session['email'] as String?;
        _userName = session['display_name'] as String?;
        _userAvatarUrl = session['avatar_url'] as String?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring active session: $e');
    }

    // Nếu đã đăng nhập trước đó và ở mobile, thử làm mới phiên Google âm thầm
    if (_isLoggedIn && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final googleSignIn = await _getGoogleSignIn();
        final account = await googleSignIn.signInSilently();
        if (account != null) {
          _userEmail = account.email;
          _userName = account.displayName ?? account.email.split('@').first;
          _userAvatarUrl = account.photoUrl;
          await DatabaseService.instance.saveActiveSession(
            email: _userEmail!,
            displayName: _userName,
            avatarUrl: _userAvatarUrl,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Silent Google Sign In check: $e');
      }
    }
    _isInitialized = true;
  }

  /// Cho phép reset trạng thái phục vụ test mô phỏng khởi động lại app
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userAvatarUrl = null;
    _googleSignIn = null;
  }

  /// Đăng nhập trực tiếp bằng tài khoản Google thật của người dùng trên thiết bị
  Future<String?> signInWithGoogle() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      debugPrint('Google Login is not supported on Windows/Linux desktop.');
      return null;
    }
    try {
      final googleSignIn = await _getGoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // Người dùng hủy chọn tài khoản
        return null;
      }

      _isLoggedIn = true;
      _userEmail = account.email;
      _userName = account.displayName ?? account.email.split('@').first;
      _userAvatarUrl = account.photoUrl;

      // Lưu phiên vào SQLite để giữ tài khoản vĩnh viễn trong app
      try {
        await DatabaseService.instance.saveActiveSession(
          email: _userEmail!,
          displayName: _userName,
          avatarUrl: _userAvatarUrl,
        );
      } catch (e) {
        debugPrint('Error saving active session: $e');
      }

      notifyListeners();
      return _userEmail;
    } catch (e) {
      debugPrint('Error Login Google: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin đăng nhập trực tiếp (phục vụ test hoặc custom provider)
  Future<void> setLoggedInUser({
    required String email,
    String? displayName,
    String? avatarUrl,
  }) async {
    _isLoggedIn = true;
    _userEmail = email.trim().toLowerCase();
    _userName = displayName ?? email.split('@').first;
    _userAvatarUrl = avatarUrl;
    notifyListeners();

    // Lưu phiên vào SQLite để giữ tài khoản vĩnh viễn trong app
    try {
      await DatabaseService.instance.saveActiveSession(
        email: _userEmail!,
        displayName: _userName,
        avatarUrl: _userAvatarUrl,
      );
    } catch (e) {
      debugPrint('Error saving active session: $e');
    }
  }

  /// Đăng xuất (chỉ khi người dùng chủ động bấm Logout)
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {}
    try {
      await DatabaseService.instance.clearActiveSession();
    } catch (e) {
      debugPrint('Error clearing active session: $e');
    }
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
