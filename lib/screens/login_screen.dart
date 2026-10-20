import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/steam_service.dart';
import 'steam_result_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  /// Hộp thoại hướng dẫn chi tiết khi gặp lỗi cấu hình Google Sign-In Error 10 (DEVELOPER_ERROR)
  Future<String?> _showGoogleError10Dialog() async {
    const sha1Fingerprint = '26:4B:D0:A4:05:55:6E:EA:53:E2:41:69:1D:F2:31:FF:1F:A3:D2:3C';
    const packageName = 'com.example.songtinhcam';

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141C28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF223044), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.security, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Google Login Setup (Error 10)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Play Services returned Error 10 (DEVELOPER_ERROR). '
              'To enable native Google sign-in on Android, add this build\'s SHA-1 fingerprint to your Google Cloud Console OAuth 2.0 Client ID for Android:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F17),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF1E2838)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Package: $packageName', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontFamily: 'monospace')),
                  SizedBox(height: 4),
                  Text('SHA-1: $sha1Fingerprint', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can also log in directly with your email below. Your session will remain saved in the app permanently.',
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: sha1Fingerprint));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF15803D),
                  behavior: SnackBarBehavior.floating,
                  content: Text('SHA-1 fingerprint copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF38BDF8)),
            label: const Text('Copy SHA-1', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B62C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Login with Email'),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại đăng nhập bằng email (dùng cho Desktop hoặc khi Google Sign-In gặp lỗi cấu hình)
  Future<String?> _showEmailInputDialog({
    String? title,
    String? description,
    String? defaultEmail,
  }) async {
    final emailController = TextEditingController(text: defaultEmail ?? '');
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141C28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF223044), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2838),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.email_outlined, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title ?? 'Login with Email',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description ??
                    'Enter your email address to sync history and backup Steam Calculator data:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF38BDF8), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF0F141D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF223044)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Invalid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, emailController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeLogin(String email) async {
    AuthService.instance.setLoggedInUser(
      email: email,
      displayName: email.split('@').first,
    );

    // Check if there is a saved Steam ID in local SQLite for this email
    final savedSteamId = await DatabaseService.instance.getSavedSteamId(email);

    if (savedSteamId != null && savedSteamId.trim().isNotEmpty) {
      try {
        final result = await SteamService.calculateAccount(
          input: savedSteamId.trim(),
          currencyName: 'Vietnamese Dong',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Welcome $email! Auto-loaded calculation for $savedSteamId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SteamResultScreen(
              result: result,
              currencyName: 'Vietnamese Dong',
            ),
          ),
        );
        return;
      } catch (calcError) {
        debugPrint('Auto calculation failed: $calcError');
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Login successfully with $email',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _handleEmailLogin() async {
    final isDesktopPlatform = !kIsWeb && (Platform.isWindows || Platform.isLinux);

    if (isDesktopPlatform) {
      final email = await _showEmailInputDialog(
        title: 'Desktop Login',
        description: 'Google Play Services is not supported on Desktop. Please enter your email to continue:',
      );
      if (email == null) return;
      await _completeLogin(email);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? email;
    try {
      email = await AuthService.instance.signInWithGoogle();
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      email = await _showEmailInputDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Lỗi Google Play Services (như error 10 / DEVELOPER_ERROR khi chưa liên kết SHA-1 trên Google Cloud)
      final errorStr = e.toString();
      final isDevError10 = errorStr.contains('10') || errorStr.contains('sign_in_failed');

      if (isDevError10) {
        final choice = await _showGoogleError10Dialog();
        if (choice == 'email') {
          email = await _showEmailInputDialog(
            title: 'Account Email Login',
            description:
                'Enter your real email address. Your account will stay saved in the app permanently until you logout:',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E2838),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Google Login: ${errorStr.replaceAll("Exception: ", "")}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );

        email = await _showEmailInputDialog(
          title: 'Account Email Login',
          description:
              'Enter your real email address. Your account will stay saved in the app permanently until you logout:',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (email != null && email.isNotEmpty) {
      await _completeLogin(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F141D);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0B0F17),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF1E2638),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF182030),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF2B3A52),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A9FFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sports_esports,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SongTinhCam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Login Body
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141C28),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1E2A3C),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // App / Email Icon with vibrant glow
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A9FFF), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A9FFF).withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.mail_outline_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Login to your account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),

                          const Text(
                            'Login with email to sync history and backup Steam Calculator data.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Button DUY NHẤT: Đăng nhập bằng email (Người dùng không tự nhập)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleEmailLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B62C0),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.email_outlined, size: 20),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Login with email',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final email = await _showEmailInputDialog(
                                        title: 'Direct Email Login',
                                        description:
                                            'Enter your email address to sync history and backup data:',
                                      );
                                      if (email != null && mounted) {
                                        await _completeLogin(email);
                                      }
                                    },
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                              label: const Text(
                                'Or enter email directly',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Thông tin bảo mật
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: Color(0xFF4ADE80),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Direct authentication via user Google account on device.',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
