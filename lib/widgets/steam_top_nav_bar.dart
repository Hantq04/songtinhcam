import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/steam_service.dart';
import '../screens/login_screen.dart';
import '../screens/steam_result_screen.dart';

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
        border: Border(bottom: BorderSide(color: Color(0xFF1E2638), width: 1)),
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

          if (showBackButton || showMenuButton)
            SizedBox(width: isMobile ? 8 : 14),

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
                  value: 'profile',
                  height: 38,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 17,
                        color: Color(0xFF38BDF8),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
    if (action == 'profile') {
      _showProfileDialog(context);
    } else if (action == 'login') {
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
      builder: (BuildContext ctx) => _BackupDialog(parentContext: context),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const _ProfileDialog(),
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

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog();

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final TextEditingController _steamIdController = TextEditingController();
  bool _isSaving = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSteamId();
  }

  Future<void> _loadSavedSteamId() async {
    final email = AuthService.instance.userEmail;
    if (email != null && email.isNotEmpty) {
      final savedId = await DatabaseService.instance.getSavedSteamId(email);
      if (mounted && savedId != null) {
        setState(() {
          _steamIdController.text = savedId;
        });
      }
    }
  }

  @override
  void dispose() {
    _steamIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSteamId() async {
    final email = AuthService.instance.userEmail;
    if (email == null) return;

    final steamId = _steamIdController.text.trim();
    if (steamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Text('Please enter a Steam ID or profile URL to save.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await DatabaseService.instance.saveUserProfile(
        email: email,
        displayName: AuthService.instance.userName,
        steamId: steamId,
        avatarUrl: AuthService.instance.userAvatarUrl,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF15803D),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Steam ID saved to SQLite for $email',
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Error saving to SQLite: $e'),
        ),
      );
    }
  }

  Future<void> _calculateAndNavigate() async {
    final steamId = _steamIdController.text.trim();
    if (steamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Please enter a Steam ID first.'),
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final email = AuthService.instance.userEmail;
      if (email != null) {
        await DatabaseService.instance.saveUserProfile(
          email: email,
          displayName: AuthService.instance.userName,
          steamId: steamId,
          avatarUrl: AuthService.instance.userAvatarUrl,
        );
      }

      final result = await SteamService.calculateAccount(
        input: steamId,
        currencyName: 'Vietnamese Dong',
      );

      if (!mounted) return;
      setState(() {
        _isCalculating = false;
      });

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SteamResultScreen(
            result: result,
            currencyName: 'Vietnamese Dong',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final isLoggedIn = auth.isLoggedIn;
    final email = auth.userEmail ?? '';
    final name = auth.userName ?? 'User';

    if (!isLoggedIn) {
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
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'User Profile',
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
                const Text(
                  'Please login to view your profile and link your Steam ID for automatic account calculation.',
                  style: TextStyle(
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B62C0),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: const Color(0xFF141C28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1E2A3C), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF38BDF8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'User Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Basic user info box (Name & Email)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2838)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1D4ED8),
                      backgroundImage: auth.userAvatarUrl != null
                          ? NetworkImage(auth.userAvatarUrl!)
                          : null,
                      child: auth.userAvatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Steam ID input section
              const Text(
                'Linked Steam ID',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F17),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF26374D)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _steamIdController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  cursorColor: const Color(0xFF38BDF8),
                  decoration: const InputDecoration(
                    hintText: 'SteamID64 or vanity profile URL',
                    hintStyle: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stored securely in local SQLite. When you log in, this Steam account will be calculated automatically.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_steamIdController.text.trim().isNotEmpty)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                      ),
                      onPressed: (_isSaving || _isCalculating)
                          ? null
                          : _calculateAndNavigate,
                      child: _isCalculating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Color(0xFF38BDF8),
                              ),
                            )
                          : const Text('Calculate'),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B62C0),
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        (_isSaving ||
                            _isCalculating ||
                            _steamIdController.text.trim().isEmpty)
                        ? null
                        : _saveSteamId,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupDialog extends StatefulWidget {
  final BuildContext parentContext;
  const _BackupDialog({required this.parentContext});

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  bool _isLoading = false;
  String? _loadingAction;

  Future<void> _handleImport() async {
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() {
      _isLoading = true;
      _loadingAction = 'Selecting file to import...';
    });

    final result = await BackupService.instance.importBackup();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingAction = null;
    });

    if (result.cancelled) {
      return;
    }

    if (result.success) {
      Navigator.pop(context);
      messenger.showSnackBar(
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
                  result.message,
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
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleExport() async {
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() {
      _isLoading = true;
      _loadingAction = 'Choosing save location...';
    });

    final result = await BackupService.instance.exportBackup();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingAction = null;
    });

    if (result.cancelled) {
      return;
    }

    if (result.success) {
      Navigator.pop(context);
      messenger.showSnackBar(
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
                  result.message,
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
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A)
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.backup_table_rounded,
                          color: Color(0xFF60A5FA),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Backup & Restore',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Profile & Steam ID Backup',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle,
                                size: 16,
                                color: Color(0xFF38BDF8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  auth.userEmail ?? 'No email',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Last backup: ${auth.lastBackupTime != null ? "${auth.lastBackupTime!.hour.toString().padLeft(2, '0')}:${auth.lastBackupTime!.minute.toString().padLeft(2, '0')} - ${auth.lastBackupTime!.day}/${auth.lastBackupTime!.month}/${auth.lastBackupTime!.year}" : "Never backed up"}',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You can export your saved profile and Steam ID to a file on your device, or select a backup file to restore anytime.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Login to backup and restore your profile and linked Steam ID.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _loadingAction ?? 'Processing...',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(ctx),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                        if (!isLoggedIn)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B62C0),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                widget.parentContext,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text('Login'),
                          )
                        else ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              foregroundColor: const Color(0xFF38BDF8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleImport,
                            icon: const Icon(
                              Icons.file_upload_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Import',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15803D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleExport,
                            icon: const Icon(
                              Icons.file_download_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Export',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
