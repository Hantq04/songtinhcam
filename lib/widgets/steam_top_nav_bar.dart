import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

/// Top Navigation Bar dùng chung cho cả CalculatorScreen và ResultScreen
/// Thiết kế theo phong cách tối ưu của SteamDB
class SteamTopNavBar extends StatelessWidget {
  final bool isMobile;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final String activeTab;

  const SteamTopNavBar({
    super.key,
    required this.isMobile,
    this.showBackButton = false,
    this.onBack,
    this.showMenuButton = false,
    this.onMenuTap,
    this.activeTab = 'Calculator',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F17),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1E2638),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
        vertical: 10,
      ),
      child: Row(
        children: [
          // Back button hoặc Menu button
          if (showBackButton)
            InkWell(
              onTap: onBack ?? () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF182030),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2B3A52), width: 1),
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
            )
          else if (showMenuButton)
            InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF182030),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2B3A52), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu, size: 15, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Menu',
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

          if (showBackButton || showMenuButton) SizedBox(width: isMobile ? 8 : 14),

          // Logo SongTinhCam SteamDB style
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

          const Spacer(),

          // Navigation Links on Desktop/Tablet
          if (!isMobile && MediaQuery.of(context).size.width >= 960) ...[
            _buildNavLink('Sales', isActive: activeTab == 'Sales'),
            _buildNavLink('Charts', isActive: activeTab == 'Charts'),
            _buildNavLink('Calculator', isActive: activeTab == 'Calculator'),
            _buildNavLink('Calendar', isActive: activeTab == 'Calendar'),
            _buildNavLink('Patches', isActive: activeTab == 'Patches'),
            const SizedBox(width: 8),
            _buildSupportLink(),
            const SizedBox(width: 16),
          ],

          // Profile / Avatar pill with PopupMenu (Backup & Login)
          _buildUserPill(context),
        ],
      ),
    );
  }

  Widget _buildUserPill(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final isLoggedIn = auth.isLoggedIn;
        final email = auth.userEmail ?? '';

        return Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: const Color(0xFF141C28),
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF1E2A3C)),
              ),
            ),
          ),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 36),
            tooltip: 'Account & Backup',
            onSelected: (value) => _handleUserAction(context, value),
            itemBuilder: (BuildContext ctx) {
              return [
                if (isLoggedIn) ...[
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 42,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                ],
                const PopupMenuItem<String>(
                  value: 'backup',
                  height: 38,
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 17,
                        color: Color(0xFF60A5FA),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Backup',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoggedIn)
                  const PopupMenuItem<String>(
                    value: 'login',
                    height: 38,
                    child: Row(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 17,
                          color: Color(0xFF38BDF8),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem<String>(
                    value: 'logout',
                    height: 38,
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 17,
                          color: Color(0xFFF87171),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ];
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF131B26),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isLoggedIn
                      ? const Color(0xFF1E40AF)
                      : const Color(0xFF1E2638),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: isLoggedIn
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF28384E),
                    child: Icon(
                      isLoggedIn ? Icons.verified_user : Icons.person,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleUserAction(BuildContext context, String action) {
    if (action == 'login') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (action == 'backup') {
      _showBackupDialog(context);
    } else if (action == 'logout') {
      AuthService.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1B2838),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Logged out successfully',
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return ListenableBuilder(
          listenable: AuthService.instance,
          builder: (ctx, _) {
            final auth = AuthService.instance;
            final isLoggedIn = auth.isLoggedIn;

            return Dialog(
              backgroundColor: const Color(0xFF141C28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF1E2A3C), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: Color(0xFF60A5FA),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Data Backup',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLoggedIn
                            ? 'Linked account: ${auth.userEmail}\nLast backup: ${auth.lastBackupTime != null ? "${auth.lastBackupTime!.hour}:${auth.lastBackupTime!.minute.toString().padLeft(2, '0')} - ${auth.lastBackupTime!.day}/${auth.lastBackupTime!.month}/${auth.lastBackupTime!.year}" : "No backup yet"}'
                            : 'Sign in to sync and backup your Steam Calculator search history to the cloud.',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isLoggedIn)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B62C0),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text('Login'),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await AuthService.instance.backupData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF15803D),
                                      behavior: SnackBarBehavior.floating,
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Data backup successful!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Backup Now'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavLink(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSupportLink() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite, size: 13, color: Color(0xFFD946EF)),
        SizedBox(width: 4),
        Text(
          'Support us',
          style: TextStyle(
            color: Color(0xFFD946EF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
