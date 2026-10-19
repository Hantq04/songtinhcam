import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = await AuthService.instance.signInWithGoogle();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (email == null) {
        // Người dùng đã hủy hoặc đóng giao diện đăng nhập Google
        return;
      }

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Error Google Login: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
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
                          const SizedBox(height: 20),

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
